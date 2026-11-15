import bcrypt from "bcryptjs";
import crypto from "crypto";
import jwt, { SignOptions } from "jsonwebtoken";
import { OAuth2Client } from "google-auth-library";
import { dbPool, query } from "../config/database.config";
import { parseLocation } from "../utils/geoParser";
import {
  RegisterDTO,
  AdminCreateUserDTO,
  LoginDTO,
  GoogleLoginDTO,
  RefreshTokenDTO,
  ChangePasswordDTO,
  RequestAuthCodeDTO,
  VerifyEmailCodeDTO,
  ResetPasswordWithCodeDTO,
} from "../validation/auth.validation";
import { UserRole, UserStatus } from "../constants/enums.constants";
import { EmailService } from "./email.service";
import { AppError } from "../utils/AppError";
import { PoolClient } from "pg";

type AuthCodePurpose = "email_verification" | "password_recovery" | "email_change";

type UserRow = {
  id: string;
  email: string;
  username: string;
  password_hash: string | null;
  google_sub: string | null;
  email_verified: boolean;
  role: UserRole;
  status: string;
  [key: string]: unknown;
};

const accessSecret = process.env.JWT_ACCESS_SECRET!;
const refreshSecret = process.env.JWT_REFRESH_SECRET!;
const accessTtl = process.env.JWT_ACCESS_TTL ?? "15m";
const refreshTtl = process.env.JWT_REFRESH_TTL ?? "30d";
const googleClientId = process.env.GOOGLE_CLIENT_ID;

function positiveInteger(name: string, fallback: number): number {
  const value = Number(process.env[name] ?? fallback);
  return Number.isInteger(value) && value > 0 ? value : fallback;
}

const authCodeTtlMinutes = positiveInteger("AUTH_CODE_TTL_MINUTES", 15);
const authCodeResendSeconds = positiveInteger("AUTH_CODE_RESEND_SECONDS", 60);
const authCodeMaxAttempts = positiveInteger("AUTH_CODE_MAX_ATTEMPTS", 5);
const authCodeMaxRequestsPerHour = positiveInteger(
  "AUTH_CODE_MAX_REQUESTS_PER_HOUR",
  5
);
const authCodeMaxRequestsPerIpHour = positiveInteger(
  "AUTH_CODE_MAX_REQUESTS_PER_IP_HOUR",
  20
);
const authCodePepper =
  process.env.AUTH_CODE_PEPPER ?? process.env.JWT_ACCESS_SECRET!;

if (!process.env.JWT_ACCESS_SECRET || !process.env.JWT_REFRESH_SECRET) {
  throw new Error("Missing JWT_ACCESS_SECRET or JWT_REFRESH_SECRET in .env");
}

const googleClient = googleClientId ? new OAuth2Client(googleClientId) : null;

export class AuthService {
  private static hashCode(code: string): string {
    return crypto
      .createHmac("sha256", authCodePepper)
      .update(code)
      .digest("hex");
  }

  private static hashToken(token: string): string {
    return crypto.createHash("sha256").update(token).digest("hex");
  }

  private static generateCode(): string {
    return crypto.randomInt(100000, 1000000).toString();
  }

  private static async findProfileByEmail(email: string) {
    const result = await query<UserRow>(
      "SELECT id, email FROM users WHERE email = $1 LIMIT 1",
      [email]
    );

    return result.rows[0] ?? null;
  }

  private static async createAuthCode(
    email: string,
    purpose: AuthCodePurpose,
    userId?: string | null,
    requestedIp?: string | null
  ) {
    const code = this.generateCode();
    const expiresAt = new Date(
      Date.now() + authCodeTtlMinutes * 60 * 1000
    );
    const normalizedIp =
      requestedIp?.replace(/^::ffff:/, "").slice(0, 64) || null;
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");
      await client.query("SELECT pg_advisory_xact_lock(hashtext($1))", [
        `${email}:${purpose}`,
      ]);

      const latest = await client.query<{ age_seconds: number }>(
        `SELECT EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at))::int AS age_seconds
         FROM auth_verification_codes
         WHERE email = $1
           AND purpose = $2
           AND consumed_at IS NULL
         ORDER BY created_at DESC
         LIMIT 1`,
        [email, purpose]
      );

      if (
        latest.rows[0] &&
        latest.rows[0].age_seconds < authCodeResendSeconds
      ) {
        throw new AppError("Please wait before requesting another code", 429);
      }

      const emailRate = await client.query<{ total: number }>(
        `SELECT COUNT(*)::int AS total
         FROM auth_verification_codes
         WHERE email = $1
           AND purpose = $2
           AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour'`,
        [email, purpose]
      );
      if ((emailRate.rows[0]?.total ?? 0) >= authCodeMaxRequestsPerHour) {
        throw new AppError("Too many code requests", 429);
      }

      if (normalizedIp) {
        const ipRate = await client.query<{ total: number }>(
          `SELECT COUNT(*)::int AS total
           FROM auth_verification_codes
           WHERE requested_ip = $1
             AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour'`,
          [normalizedIp]
        );
        if ((ipRate.rows[0]?.total ?? 0) >= authCodeMaxRequestsPerIpHour) {
          throw new AppError("Too many code requests", 429);
        }
      }

      await client.query(
        `UPDATE auth_verification_codes
         SET consumed_at = CURRENT_TIMESTAMP
         WHERE email = $1
           AND purpose = $2
           AND consumed_at IS NULL`,
        [email, purpose]
      );

      await client.query(
        `INSERT INTO auth_verification_codes
          (email, user_id, purpose, code_hash, expires_at, max_attempts, requested_ip)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          email,
          userId ?? null,
          purpose,
          this.hashCode(code),
          expiresAt,
          authCodeMaxAttempts,
          normalizedIp,
        ]
      );
      await client.query("COMMIT");
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }

    return {
      code,
      expires_at: expiresAt.toISOString(),
    };
  }

  private static async consumeAuthCode(
    email: string,
    code: string,
    purpose: AuthCodePurpose,
    expectedUserId?: string,
    onConsume?: (client: PoolClient, userId: string | null) => Promise<void>
  ) {
    const client = await dbPool.connect();
    let transactionOpen = false;

    try {
      await client.query("BEGIN");
      transactionOpen = true;
      await client.query("SELECT pg_advisory_xact_lock(hashtext($1))", [
        `${email}:${purpose}`,
      ]);

      const result = await client.query<{
        id: number;
        user_id: string | null;
        expires_at: Date;
        code_hash: string;
        attempt_count: number;
        max_attempts: number;
      }>(
        `SELECT id, user_id, expires_at, code_hash, attempt_count, max_attempts
         FROM auth_verification_codes
         WHERE email = $1
         AND purpose = $2
         AND consumed_at IS NULL
         ORDER BY created_at DESC
         LIMIT 1
         FOR UPDATE`,
        [email, purpose]
      );

      const stored = result.rows[0];
      if (!stored) {
        await client.query("COMMIT");
        transactionOpen = false;
        throw new AppError("Invalid verification code", 400);
      }
      if (expectedUserId && stored.user_id !== expectedUserId) {
        throw new AppError("Invalid verification code", 400);
      }

      if (new Date(stored.expires_at).getTime() < Date.now()) {
        await client.query(
          "UPDATE auth_verification_codes SET consumed_at = CURRENT_TIMESTAMP WHERE id = $1",
          [stored.id]
        );
        await client.query("COMMIT");
        transactionOpen = false;
        throw new AppError("Verification code expired", 409);
      }

      if (stored.attempt_count >= stored.max_attempts) {
        await client.query(
          "UPDATE auth_verification_codes SET consumed_at = CURRENT_TIMESTAMP WHERE id = $1",
          [stored.id]
        );
        await client.query("COMMIT");
        transactionOpen = false;
        throw new AppError("Too many verification attempts", 429);
      }

      const providedHash = this.hashCode(code);
      const storedHash = Buffer.from(stored.code_hash, "hex");
      const providedHashBuffer = Buffer.from(providedHash, "hex");
      const matches =
        storedHash.length === providedHashBuffer.length &&
        crypto.timingSafeEqual(storedHash, providedHashBuffer);

      if (!matches) {
        const nextAttempts = stored.attempt_count + 1;
        await client.query(
          `UPDATE auth_verification_codes
           SET attempt_count = $2,
               consumed_at = CASE WHEN $2 >= max_attempts THEN CURRENT_TIMESTAMP ELSE consumed_at END
           WHERE id = $1`,
          [stored.id, nextAttempts]
        );
        await client.query("COMMIT");
        transactionOpen = false;
        throw new AppError(
          nextAttempts >= stored.max_attempts
            ? "Too many verification attempts"
            : "Invalid verification code",
          nextAttempts >= stored.max_attempts ? 429 : 400
        );
      }

      await client.query(
        `UPDATE auth_verification_codes
         SET consumed_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [stored.id]
      );
      if (onConsume) await onConsume(client, stored.user_id);
      await client.query("COMMIT");
      transactionOpen = false;
      return stored;
    } catch (error) {
      if (transactionOpen) {
        await client.query("ROLLBACK").catch(() => undefined);
      }
      throw error;
    } finally {
      client.release();
    }
  }

  private static async buildAuthResponse(profile: UserRow) {
    const session = await this.createSession(profile);

    return {
      session,
      user: {
        id: profile.id,
        email: profile.email,
        role: profile.role,
      },
      profile: this.sanitizeProfile(profile),
    };
  }

  private static sanitizeProfile(profile: UserRow) {
    const parsed = parseLocation(profile) as UserRow;
    const {
      password_hash: _passwordHash,
      google_sub: _googleSub,
      ...safeProfile
    } = parsed;

    return safeProfile;
  }

  private static async createLocalProfile(
    data: RegisterDTO,
    options: {
      role: UserRole;
      status?: UserStatus;
      emailVerified?: boolean;
    }
  ): Promise<UserRow> {
    const {
      email,
      password,
      first_name,
      last_name,
      username,
      location,
    } = data;

    const usernameSafe = username ?? email.split("@")[0];
    const passwordHash = await bcrypt.hash(password, 12);
    const point = location?.coordinates
      ? `SRID=4326;POINT(${location.coordinates[0]} ${location.coordinates[1]})`
      : null;

    const duplicate = await query(
      "SELECT id FROM users WHERE email = $1 OR username = $2 LIMIT 1",
      [email, usernameSafe]
    );

    if (duplicate.rows.length > 0) {
      throw new Error("Email or username already in use");
    }

    const result = await query<UserRow>(
      `INSERT INTO users
        (first_name, last_name, username, email, password_hash, role, status, location, email_verified)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *, encode(ST_AsEWKB(location::geometry), 'hex') AS location`,
      [
        first_name ?? null,
        last_name ?? null,
        usernameSafe,
        email,
        passwordHash,
        options.role,
        options.status ?? "active",
        point,
        options.emailVerified ?? false,
      ]
    );

    const profile = result.rows[0];
    if (!profile) throw new Error("Profile creation failed");

    await query("SELECT create_wallet(p_user_id => $1)", [profile.id], {
      userId: profile.id,
      role: profile.role,
    });

    return profile;
  }

  private static async createSession(profile: UserRow, client?: PoolClient) {
    const accessToken = jwt.sign(
      {
        sub: profile.id,
        email: profile.email,
        role: profile.role,
      },
      accessSecret,
      { expiresIn: accessTtl } as SignOptions
    );

    const refreshToken = jwt.sign(
      {
        sub: profile.id,
        token_id: crypto.randomUUID(),
      },
      refreshSecret,
      { expiresIn: refreshTtl } as SignOptions
    );

    const decoded = jwt.decode(refreshToken) as { exp?: number } | null;
    const expiresAt = new Date((decoded?.exp ?? 0) * 1000);

    const execute = client ? client.query.bind(client) : query;
    await execute(
      `INSERT INTO user_refresh_tokens (user_id, token_hash, expires_at)
       VALUES ($1, $2, $3)`,
      [profile.id, this.hashToken(refreshToken), expiresAt]
    );

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      token_type: "bearer",
      expires_in: getJwtSeconds(accessToken),
    };
  }

  static async register(data: RegisterDTO, requestedIp?: string) {
    await this.assertRegistrationRateLimit(requestedIp);
    const profile = await this.createLocalProfile(data, { role: "user" });
    let deliverySent = true;

    try {
      await this.sendAuthCode(
        profile.email,
        "email_verification",
        profile.id,
        requestedIp
      );
    } catch (error) {
      deliverySent = false;
      console.error("Verification email delivery failed:", error);
    }

    return {
      requires_email_verification: true,
      email: profile.email,
      delivery_sent: deliverySent,
    };
  }

  static async createUserByAdmin(data: AdminCreateUserDTO) {
    const { role, status, email_verified, ...registration } = data;
    const profile = await this.createLocalProfile(registration, {
      role,
      ...(status !== undefined ? { status } : {}),
      emailVerified: email_verified ?? true,
    });

    return this.sanitizeProfile(profile);
  }

  static async login(data: LoginDTO) {
    const { email, username, password } = data;

    const result = await query<UserRow>(
      `SELECT *, encode(ST_AsEWKB(location::geometry), 'hex') AS location
       FROM users
       WHERE email = $1 OR username = $2
       LIMIT 1`,
      [email ?? null, username ?? null]
    );

    const profile = result.rows[0];
    if (!profile?.password_hash) {
      throw new Error("Invalid credentials");
    }

    const ok = await bcrypt.compare(password, profile.password_hash);
    if (!ok) throw new Error("Invalid credentials");

    if (profile.status !== "active") {
      throw new Error("User not active");
    }

    if (!profile.email_verified) {
      throw new AppError("Email not verified", 403);
    }

    return this.buildAuthResponse(profile);
  }

  static async loginWithGoogle(data: GoogleLoginDTO) {
    if (!googleClient || !googleClientId) {
      throw new Error("Google login is not configured");
    }

    const ticket = await googleClient.verifyIdToken({
      idToken: data.id_token,
      audience: googleClientId,
    });

    const payload = ticket.getPayload();
    const googleSub = payload?.sub;
    const email = payload?.email;

    if (!googleSub || !email || payload?.email_verified !== true) {
      throw new Error("Invalid Google token");
    }

    const existing = await query<UserRow>(
      `SELECT *, encode(ST_AsEWKB(location::geometry), 'hex') AS location
       FROM users
       WHERE google_sub = $1 OR email = $2
       LIMIT 1`,
      [googleSub, email]
    );

    let profile = existing.rows[0];

    if (profile) {
      if (!profile.google_sub) {
        const updated = await query<UserRow>(
          `UPDATE users
           SET google_sub = $1,
               email_verified = true,
               updated_at = now()
           WHERE id = $2
           RETURNING *, encode(ST_AsEWKB(location::geometry), 'hex') AS location`,
          [googleSub, profile.id]
        );
        profile = updated.rows[0];
      }
    } else {
      const inserted = await query<UserRow>(
        `INSERT INTO users (email, username, google_sub, role, email_verified)
         VALUES ($1, $2, $3, 'user', true)
         RETURNING *, encode(ST_AsEWKB(location::geometry), 'hex') AS location`,
        [email, email.split("@")[0], googleSub]
      );
      profile = inserted.rows[0];

      if (!profile) throw new Error("Profile creation failed");

      await query("SELECT create_wallet(p_user_id => $1)", [profile.id], {
        userId: profile.id,
        role: profile.role,
      });
    }

    if (!profile) throw new Error("Profile creation failed");

    if (profile.status !== "active") throw new AppError("User not active", 403);
    return this.buildAuthResponse(profile);
  }

  static async refreshToken(data: RefreshTokenDTO) {
    let decoded: { sub?: string | undefined } | string;

    try {
      decoded = jwt.verify(data.refresh_token, refreshSecret);
    } catch {
      throw new Error("Invalid refresh token");
    }

    if (typeof decoded === "string" || !decoded.sub) {
      throw new Error("Invalid refresh token");
    }

    const tokenHash = this.hashToken(data.refresh_token);
    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");
      const tokenResult = await client.query(
        `UPDATE user_refresh_tokens SET revoked_at = now()
         WHERE user_id = $1 AND token_hash = $2
           AND revoked_at IS NULL AND expires_at > now()
         RETURNING id`, [decoded.sub, tokenHash]
      );
      if (!tokenResult.rowCount) throw new AppError("Invalid refresh token", 401);
      const profileResult = await client.query<UserRow>(
      `SELECT *, encode(ST_AsEWKB(location::geometry), 'hex') AS location
       FROM users
       WHERE id = $1
       LIMIT 1`,
      [decoded.sub]
    );

    const profile = profileResult.rows[0];
    if (!profile) throw new Error("User not found");
    if (profile.status !== "active") throw new AppError("User not active", 403);
    if (!profile.email_verified) {
      throw new AppError("Email not verified", 403);
    }

      const session = await this.createSession(profile, client);
      await client.query("COMMIT");
      return {
      session,
      user: {
        id: profile.id,
        email: profile.email,
        role: profile.role,
      },
      profile: this.sanitizeProfile(profile),
    };
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  static async requestEmailChange(userId: string, data: RequestAuthCodeDTO, ip?: string) {
    const email = data.email.toLowerCase();
    const existing = await this.findProfileByEmail(email);
    if (existing) throw new AppError("Email or username already in use", 409);
    return this.sendAuthCode(email, "email_change", userId, ip);
  }

  static async confirmEmailChange(userId: string, data: VerifyEmailCodeDTO) {
    const email = data.email.toLowerCase();
    await this.consumeAuthCode(email, data.code, "email_change", userId, async client => {
      await client.query("UPDATE users SET email = $2, email_verified = true WHERE id = $1", [userId, email]);
    });
    return { success: true };
  }

  static async logout(refreshToken?: string) {
    if (refreshToken) {
      await query(
        "UPDATE user_refresh_tokens SET revoked_at = now() WHERE token_hash = $1",
        [this.hashToken(refreshToken)]
      );
    }

    return { success: true };
  }

  static async changePassword(userId: string, data: ChangePasswordDTO) {
    const result = await query<UserRow>(
      "SELECT id, password_hash FROM users WHERE id = $1 LIMIT 1",
      [userId]
    );

    const profile = result.rows[0];
    if (!profile?.password_hash) throw new Error("User not found");

    const ok = await bcrypt.compare(data.current_password, profile.password_hash);
    if (!ok) throw new Error("Invalid current password");

    const passwordHash = await bcrypt.hash(data.new_password, 12);

    await query(
      `UPDATE users
       SET password_hash = $1,
           updated_at = now()
       WHERE id = $2`,
      [passwordHash, userId]
    );

    await query(
      "UPDATE user_refresh_tokens SET revoked_at = now() WHERE user_id = $1",
      [userId]
    );

    return { success: true };
  }

  static async requestEmailVerificationCode(
    data: RequestAuthCodeDTO,
    requestedIp?: string
  ) {
    const profile = await this.findProfileByEmail(data.email);

    if (!profile) throw new Error("User not found");

    const verified = await query<{ email_verified: boolean }>(
      "SELECT email_verified FROM users WHERE id = $1 LIMIT 1",
      [profile.id]
    );
    if (verified.rows[0]?.email_verified) {
      throw new AppError("Email already verified", 409);
    }

    return this.sendAuthCode(
      data.email,
      "email_verification",
      profile.id,
      requestedIp
    );
  }

  static async verifyEmailCode(data: VerifyEmailCodeDTO) {
    const stored = await this.consumeAuthCode(
      data.email,
      data.code,
      "email_verification"
    );

    if (!stored.user_id) throw new Error("User not found");

    await query(
      `UPDATE users
       SET email_verified = true,
           updated_at = now()
       WHERE id = $1`,
      [stored.user_id]
    );

    return { success: true };
  }

  static async requestPasswordRecoveryCode(
    data: RequestAuthCodeDTO,
    requestedIp?: string
  ) {
    const profile = await this.findProfileByEmail(data.email);

    if (!profile) {
      return {
        success: true,
        expires_at: new Date(
          Date.now() + authCodeTtlMinutes * 60 * 1000
        ).toISOString(),
      };
    }

    return this.sendAuthCode(
      data.email,
      "password_recovery",
      profile.id,
      requestedIp
    );
  }

  static async resetPasswordWithCode(data: ResetPasswordWithCodeDTO) {
    const stored = await this.consumeAuthCode(
      data.email,
      data.code,
      "password_recovery"
    );

    if (!stored.user_id) throw new Error("User not found");

    const passwordHash = await bcrypt.hash(data.new_password, 12);

    await query(
      `UPDATE users
       SET password_hash = $1,
           email_verified = true,
           updated_at = now()
       WHERE id = $2`,
      [passwordHash, stored.user_id]
    );

    await query(
      "UPDATE user_refresh_tokens SET revoked_at = now() WHERE user_id = $1",
      [stored.user_id]
    );

    return { success: true };
  }

  private static async sendAuthCode(
    email: string,
    purpose: AuthCodePurpose,
    userId: string,
    requestedIp?: string
  ) {
    const created = await this.createAuthCode(
      email,
      purpose,
      userId,
      requestedIp
    );

    try {
      await EmailService.sendAuthCode({
        email,
        code: created.code,
        purpose,
        expiresInMinutes: authCodeTtlMinutes,
      });
    } catch (error) {
      await query(
        `UPDATE auth_verification_codes
         SET consumed_at = CURRENT_TIMESTAMP
         WHERE email = $1
           AND purpose = $2
           AND code_hash = $3
           AND consumed_at IS NULL`,
        [email, purpose, this.hashCode(created.code)]
      ).catch(() => undefined);
      throw error;
    }

    const exposeCode =
      process.env.NODE_ENV !== "production" &&
      process.env.AUTH_EXPOSE_CODES === "true";

    return {
      success: true,
      expires_at: created.expires_at,
      ...(exposeCode ? { code: created.code } : {}),
    };
  }

  private static async assertRegistrationRateLimit(requestedIp?: string) {
    const normalizedIp = requestedIp?.replace(/^::ffff:/, "").slice(0, 64);
    if (!normalizedIp) return;

    const result = await query<{ total: number }>(
      `SELECT COUNT(*)::int AS total
       FROM auth_verification_codes
       WHERE requested_ip = $1
         AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour'`,
      [normalizedIp]
    );

    if ((result.rows[0]?.total ?? 0) >= authCodeMaxRequestsPerIpHour) {
      throw new AppError("Too many code requests", 429);
    }
  }

  static async getCurrentUser(userId: string) {
    const result = await query<UserRow>(
      `SELECT *, encode(ST_AsEWKB(location::geometry), 'hex') AS location
       FROM users
       WHERE id = $1
       LIMIT 1`,
      [userId]
    );

    const profile = result.rows[0];
    if (!profile) throw new Error("User not found");

    return this.sanitizeProfile(profile);
  }
}

function getJwtSeconds(token: string) {
  const decoded = jwt.decode(token) as { exp?: number; iat?: number } | null;
  if (!decoded?.exp || !decoded.iat) return undefined;
  return decoded.exp - decoded.iat;
}

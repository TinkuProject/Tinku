import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { query } from "../config/database.config";
import { UserRole } from "../constants/enums.constants";

const accessSecret = process.env.JWT_ACCESS_SECRET;

if (!accessSecret) {
  throw new Error("Missing JWT_ACCESS_SECRET in .env");
}

type AccessPayload = {
  sub: string;
  email?: string;
  role?: UserRole;
};

async function resolveAuthenticatedUser(req: Request) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith("Bearer ")) {
    return null;
  }

  const token = authHeader.slice("Bearer ".length).trim();
  const decoded = jwt.verify(token, accessSecret!) as AccessPayload | string;

  if (typeof decoded === "string" || !decoded.sub) {
    throw new Error("Invalid token");
  }

  const userResult = await query<{
    id: string;
    email: string;
    role: UserRole;
    email_verified: boolean;
    permissions: string[] | null;
  }>(
    `SELECT
       u.id,
       u.email,
       u.role,
       u.email_verified,
       COALESCE(
         array_agg(granted.code ORDER BY granted.code)
           FILTER (WHERE granted.code IS NOT NULL),
         ARRAY[]::varchar[]
       ) AS permissions
     FROM users u
     LEFT JOIN LATERAL (
       SELECT p.code
       FROM role_permissions rp
       JOIN permissions p ON p.id = rp.permission_id
       WHERE rp.role = u.role
       UNION
       SELECT p.code
       FROM user_labels ul
       JOIN label_permissions lp ON lp.label_id = ul.label_id
       JOIN permissions p ON p.id = lp.permission_id
       WHERE ul.user_id = u.id
     ) granted ON true
     WHERE u.id = $1
       AND u.status = 'active'
       AND u.email_verified = true
     GROUP BY u.id, u.email, u.role, u.email_verified
     LIMIT 1`,
    [decoded.sub]
  );

  const user = userResult.rows[0];
  if (!user) {
    throw new Error("User not found in DB");
  }

  return {
    id: user.id,
    email: user.email,
    role: user.role,
    permissions: user.permissions ?? [],
  };
}

export const authMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const user = await resolveAuthenticatedUser(req);
    if (!user) {
      return res.status(401).json({ error: "No token provided" });
    }

    req.user = user;

    next();
  } catch {
    return res.status(401).json({ error: "Unauthorized" });
  }
};

export const optionalAuthMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (!req.headers.authorization) {
    next();
    return;
  }

  try {
    const user = await resolveAuthenticatedUser(req);
    if (user) req.user = user;
    next();
  } catch {
    return res.status(401).json({ error: "Unauthorized" });
  }
};

import bcrypt from "bcryptjs";
import dotenv from "dotenv";
import { query, dbPool } from "../src/config/database.config";
import { registerSchema } from "../src/validation/auth.validation";

dotenv.config();

async function seedUsers() {
  const system = await query<{ id: string }>(
    `INSERT INTO users (email, username, password_hash, role, email_verified)
     VALUES ('stripe-system@tinku.local', 'stripe-system', NULL, 'admin', true)
     ON CONFLICT (email) DO UPDATE SET password_hash = NULL RETURNING id`
  );
  console.log(`STRIPE_SYSTEM_REVIEWER_ID=${system.rows[0]?.id}`);
  if (!process.argv.includes("--test-users")) return;
  if (!["development", "test"].includes(process.env.NODE_ENV ?? "")) {
    throw new Error("Test users may only be seeded in development or test");
  }
  const password = registerSchema.shape.password.min(12).parse(process.env.SEED_TEST_PASSWORD);
  const USERS = (["user", "partner", "admin", "master"] as const)
    .map(role => ({ email: `${role}@test.com`, password, role }));
  for (const user of USERS) {
    console.log(`\nProcesando ${user.email}...`);

    const passwordHash = await bcrypt.hash(user.password, 12);
    const username = user.email.split("@")[0];

    const result = await query<{ id: string }>(
      `INSERT INTO users (email, username, password_hash, role, email_verified)
       VALUES ($1, $2, $3, $4, true)
       ON CONFLICT (email) DO NOTHING
       RETURNING id`,
      [user.email, username, passwordHash, user.role]
    );

    const userId = result.rows[0]?.id;
    if (!userId) continue;

    await query("SELECT create_wallet(p_user_id => $1)", [userId], {
      userId,
      role: user.role,
    });

    console.log(`Usuario listo (${user.role}) -> ${userId}`);

  }
}

seedUsers()
  .catch((err) => {
    console.error("Error en seed:", err);
    process.exitCode = 1;
  }).finally(() => dbPool.end());

import bcrypt from "bcryptjs";
import { dbPool, query } from "../src/config/database.config";

async function run() {
  const apply = process.argv.includes("--apply");
  const rows = await query<{ id: string; password_hash: string | null }>(
    "SELECT id, password_hash FROM users WHERE email = ANY($1::text[])",
    [["user@test.com", "partner@test.com", "admin@test.com", "master@test.com", "stripe-system@tinku.local"]]
  );
  for (const user of rows.rows) {
    if (!user.password_hash || !await bcrypt.compare("Pass1234", user.password_hash)) continue;
    if (apply) {
      const client = await dbPool.connect();
      try {
        await client.query("BEGIN");
        await client.query("UPDATE users SET password_hash = NULL, status = 'inactive' WHERE id = $1", [user.id]);
        await client.query("UPDATE user_refresh_tokens SET revoked_at = now() WHERE user_id = $1", [user.id]);
        await client.query("COMMIT");
      } catch (error) {
        await client.query("ROLLBACK"); throw error;
      } finally { client.release(); }
    }
    console.log(`Legacy seed account ${user.id}: ${apply ? "disabled" : "would be disabled"}`);
  }
}
run().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => dbPool.end());

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { Client } = require("pg");

const MIGRATION_LOCK_NAME = "tinku_schema_migrations";
const connectionString = process.env.MIGRATION_DATABASE_URL || process.env.DATABASE_URL;
if (!connectionString) throw new Error("Falta MIGRATION_DATABASE_URL o DATABASE_URL.");

const migrationsSql = `
CREATE TABLE IF NOT EXISTS schema_migrations (
  id bigserial PRIMARY KEY,
  name varchar(255) NOT NULL UNIQUE,
  checksum varchar(64) NOT NULL,
  executed_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
`;

function cleanTransactionStatements(sql) {
  return sql.replace(/^\s*(?:BEGIN|START\s+TRANSACTION|COMMIT|ROLLBACK)\s*;\s*$/gim, "");
}

async function main() {
  const client = new Client({ connectionString });
  const migrationsPath = path.join(__dirname, "database/migrations");
  let locked = false;
  try {
    await client.connect();
    await client.query("SELECT pg_advisory_lock(hashtext($1))", [MIGRATION_LOCK_NAME]);
    locked = true;
    await client.query(migrationsSql);
    const files = fs.readdirSync(migrationsPath)
      .filter((name) => /^\d{4}_[a-z0-9_]+\.sql$/i.test(name))
      .sort((a, b) => a.localeCompare(b));
    for (const name of files) {
      const sql = fs.readFileSync(path.join(migrationsPath, name), "utf8");
      const checksum = crypto.createHash("sha256").update(sql).digest("hex");
      const previous = await client.query("SELECT checksum FROM schema_migrations WHERE name = $1", [name]);
      if (previous.rowCount) {
        if (previous.rows[0].checksum !== checksum) throw new Error(`${name} fue aplicado con otro checksum; crea una migracion nueva.`);
        console.log(`${name}: ya aplicada.`);
        continue;
      }
      await client.query("BEGIN");
      try {
        await client.query(cleanTransactionStatements(sql));
        await client.query("INSERT INTO schema_migrations(name, checksum) VALUES ($1, $2)", [name, checksum]);
        await client.query("COMMIT");
      } catch (error) {
        await client.query("ROLLBACK").catch(() => undefined);
        throw error;
      }
      console.log(`${name}: aplicada.`);
    }
  } finally {
    if (locked) await client.query("SELECT pg_advisory_unlock(hashtext($1))", [MIGRATION_LOCK_NAME]).catch(() => undefined);
    await client.end().catch(() => undefined);
  }
}

main().catch((error) => {
  console.error("Fallaron las migraciones de Tinku.", error);
  process.exitCode = 1;
});

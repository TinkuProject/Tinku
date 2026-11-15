import crypto from "crypto";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";
import { Client } from "pg";

dotenv.config();

const connectionString = process.env.MIGRATION_DATABASE_URL ?? process.env.DATABASE_URL;
const MIGRATION_LOCK_NAME = "tinku_schema_migrations";

if (!connectionString) {
  console.error("Error: Missing MIGRATION_DATABASE_URL or DATABASE_URL in .env");
  process.exit(1);
}

const MIGRATIONS_TABLE_SQL = `
CREATE TABLE IF NOT EXISTS schema_migrations (
  id bigserial PRIMARY KEY,
  name varchar(255) NOT NULL UNIQUE,
  checksum varchar(64) NOT NULL,
  executed_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
`;

function getMigrationFiles(migrationsFolder: string) {
  if (!fs.existsSync(migrationsFolder)) {
    return [];
  }

  return fs
    .readdirSync(migrationsFolder)
    .filter((file) => /^\d{4}_[a-z0-9_]+\.sql$/i.test(file))
    .sort((a, b) => a.localeCompare(b));
}

function checksum(content: string) {
  return crypto.createHash("sha256").update(content).digest("hex");
}

function removeTransactionStatements(content: string) {
  return content.replace(
    /^\s*(?:BEGIN|START\s+TRANSACTION|COMMIT|ROLLBACK)\s*;\s*$/gim,
    ""
  );
}

async function runMigrations() {
  const client = new Client({ connectionString });
  const migrationsFolder = path.join(__dirname, "../database/migrations");
  let lockAcquired = false;

  try {
    await client.connect();
    await client.query("SELECT pg_advisory_lock(hashtext($1))", [
      MIGRATION_LOCK_NAME,
    ]);
    lockAcquired = true;
    await client.query(MIGRATIONS_TABLE_SQL);

    const files = getMigrationFiles(migrationsFolder);

    if (files.length === 0) {
      console.log("No migrations found.");
      return;
    }

    for (const file of files) {
      const filePath = path.join(migrationsFolder, file);
      const sqlContent = fs.readFileSync(filePath, "utf-8");
      const fileChecksum = checksum(sqlContent);
      const executableSql = removeTransactionStatements(sqlContent);

      const applied = await client.query(
        "SELECT checksum FROM schema_migrations WHERE name = $1",
        [file]
      );

      if (applied.rowCount && applied.rows[0].checksum !== fileChecksum) {
        throw new Error(
          `Migration "${file}" was already applied with a different checksum. Create a new migration instead of editing it.`
        );
      }

      if (applied.rowCount) {
        console.log(`${file} already applied. Skipping.`);
        continue;
      }

      console.log(`Executing ${file}...`);
      await client.query("BEGIN");

      try {
        await client.query(executableSql);
        await client.query(
          "INSERT INTO schema_migrations (name, checksum) VALUES ($1, $2)",
          [file, fileChecksum]
        );
        await client.query("COMMIT");
      } catch (error) {
        try {
          await client.query("ROLLBACK");
        } catch (rollbackError) {
          console.error(`Could not roll back migration ${file}:`, rollbackError);
        }
        throw error;
      }

      console.log(`${file} executed successfully.`);
    }

    console.log("\nMigrations finished successfully!");
  } catch (error) {
    console.error("Error executing migrations:", error);
    process.exitCode = 1;
  } finally {
    try {
      if (lockAcquired) {
        await client.query("SELECT pg_advisory_unlock(hashtext($1))", [
          MIGRATION_LOCK_NAME,
        ]);
      }
    } catch (error) {
      console.error("Error releasing migration lock:", error);
      process.exitCode = 1;
    } finally {
      await client.end();
    }
  }
}

runMigrations();

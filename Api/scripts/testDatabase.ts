import fs from "fs";
import path from "path";
import crypto from "crypto";
import { execFileSync } from "child_process";
import dotenv from "dotenv";
import { Client } from "pg";

dotenv.config();

async function run() {
  const source = new URL(process.env.DATABASE_URL ?? "");
  if (!["localhost", "127.0.0.1", "[::1]"].includes(source.hostname)) {
    throw new Error("Isolated database tests require a local PostgreSQL server");
  }
  const name = `tinku_security_test_${crypto.randomBytes(6).toString("hex")}`;
  const target = new URL(source);
  target.pathname = `/${name}`;
  const admin = new Client({ connectionString: source.toString() });
  await admin.connect();
  let created = false;
  try {
    await admin.query(`CREATE DATABASE "${name}"`);
    created = true;
    const db = new Client({ connectionString: target.toString() });
    await db.connect();
    try {
      for (const file of ["01-db.sql", "02-functions.sql", "03-triggers.sql", "04-init.sql"]) {
        await db.query(fs.readFileSync(path.join(__dirname, "../database", file), "utf8"));
      }
      await db.query("BEGIN");
      await db.query(fs.readFileSync(path.join(__dirname, "../database/migrations/0030_security_and_order_lifecycle.sql"), "utf8"));
      await db.query("COMMIT");
      console.log("Fresh schema and migration 0030 validated in an isolated database.");
    } finally { await db.end(); }
    const files = fs.readdirSync(path.join(__dirname, "../tests-integration"))
      .filter(file => file.endsWith(".test.js")).map(file => path.join(__dirname, "../tests-integration", file));
    execFileSync(process.execPath, ["--test", ...files], {
      stdio: "inherit", env: { ...process.env, DATABASE_URL: target.toString(), TEST_DATABASE_URL: target.toString() },
    });
  } finally {
    if (created) {
      if (!/^tinku_security_test_[a-f0-9]{12}$/.test(name) || name === source.pathname.slice(1)) {
        throw new Error("Invalid test database cleanup target");
      }
      await admin.query(`DROP DATABASE "${name}" WITH (FORCE)`);
    }
    await admin.end();
  }
}

run().catch(error => { console.error(error); process.exitCode = 1; });

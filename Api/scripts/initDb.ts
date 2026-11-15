import fs from "fs";
import path from "path";
import dotenv from "dotenv";
import { Client } from "pg";

dotenv.config();

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error("❌ Error: Missing DATABASE_URL in .env");
  process.exit(1);
}

const SQL_FILES = [
  "01-db.sql",
  "02-functions.sql",
  "03-triggers.sql",
  "04-init.sql",
  "05-jobs.sql",
];

async function initDatabase() {
  const dbUrl = new URL(connectionString!);
  const dbName = dbUrl.pathname.slice(1);

  if (!dbName) {
    console.error("❌ Error: DATABASE_URL does not contain a database name.");
    process.exit(1);
  }

  console.log(`Connecting to server to check database: "${dbName}"...`);

  // Conectar primero a la base de datos 'postgres' por defecto para poder crear la nuestra
  dbUrl.pathname = "/postgres";
  const defaultClient = new Client({ connectionString: dbUrl.toString() });

  try {
    await defaultClient.connect();

    const checkDbResult = await defaultClient.query(
      "SELECT 1 FROM pg_database WHERE datname = $1",
      [dbName]
    );

    if (checkDbResult.rowCount === 0) {
      console.log(`🔨 Database "${dbName}" does not exist. Creating it...`);
      // CREATE DATABASE no permite variables de parámetros ($1), por lo que concatenamos de forma segura tras validar dbName
      if (!/^[a-zA-Z0-9_-]+$/.test(dbName)) {
        throw new Error(`Invalid database name: "${dbName}"`);
      }
      await defaultClient.query(`CREATE DATABASE "${dbName}"`);
      console.log(`🚀 Database "${dbName}" created successfully!`);
    } else {
      console.log(`✅ Database "${dbName}" already exists.`);
    }
  } catch (error) {
    console.error("❌ Error ensuring database existence:", error);
    process.exit(1);
  } finally {
    await defaultClient.end();
  }

  // Ahora conectar a la base de datos destino para ejecutar los esquemas
  console.log(`\nConnecting to database "${dbName}" to execute SQL scripts...`);
  const client = new Client({ connectionString });

  try {
    await client.connect();

    const dbFolder = path.join(__dirname, "../database");

    for (const file of SQL_FILES) {
      const filePath = path.join(dbFolder, file);
      if (!fs.existsSync(filePath)) {
        console.warn(`⚠️ Warning: SQL file "${file}" not found in database folder. Skipping...`);
        continue;
      }

      console.log(`📖 Executing ${file}...`);
      const sqlContent = fs.readFileSync(filePath, "utf-8");

      // Ejecutar el script SQL completo
      await client.query(sqlContent);
      console.log(`✅ ${file} executed successfully.`);
    }

    console.log("\n🎉 Database initialization finished successfully!");
  } catch (error) {
    console.error("❌ Error executing SQL scripts:", error);
    process.exit(1);
  } finally {
    await client.end();
  }
}

initDatabase();

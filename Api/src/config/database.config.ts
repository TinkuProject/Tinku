import dotenv from "dotenv";
import { Pool, PoolClient, QueryResult, types, defaults } from "pg";
import { UserRole } from "../constants/enums.constants";

export type QueryResultRow = { [column: string]: any; };

dotenv.config();

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error("Missing DATABASE_URL in .env");
}

types.setTypeParser(20, (value) => Number(value)); // int8 / bigserial
types.setTypeParser(1700, (value) => Number(value)); // numeric / decimal
defaults.parseInputDatesAsUTC = true;
types.setTypeParser(1114, value => new Date(`${value.replace(" ", "T")}Z`));

export const dbPool = new Pool({
  connectionString,
  options: "-c timezone=UTC",
  max: Number(process.env.DB_POOL_MAX ?? 20),
  idleTimeoutMillis: Number(process.env.DB_IDLE_TIMEOUT_MS ?? 30_000),
  connectionTimeoutMillis: Number(
    process.env.DB_CONNECTION_TIMEOUT_MS ?? 10_000
  ),
  statement_timeout: Number(process.env.DB_STATEMENT_TIMEOUT_MS ?? 30_000),
});

export type DbContext = {
  userId?: string;
  role?: UserRole;
};

export async function query<T extends QueryResultRow = any>(
  text: string,
  values: unknown[] = [],
  context?: DbContext
): Promise<QueryResult<T>> {
  const client = await dbPool.connect();

  try {
    if (!context?.userId && !context?.role) {
      return await client.query<T>(text, values);
    }

    await client.query("BEGIN");
    await setDbContext(client, context);
    const result = await client.query<T>(text, values);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    if (context?.userId || context?.role) {
      await client.query("ROLLBACK").catch(() => undefined);
    }
    throw error;
  } finally {
    client.release();
  }
}

async function setDbContext(client: PoolClient, context: DbContext) {
  if (context.userId) {
    await client.query("SELECT set_config('app.user_id', $1, true)", [
      context.userId,
    ]);
  }

  if (context.role) {
    await client.query("SELECT set_config('app.user_role', $1, true)", [
      context.role,
    ]);
  }
}

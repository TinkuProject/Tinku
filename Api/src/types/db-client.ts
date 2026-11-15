type DbError = Error & {
  code?: string;
};

type DbListResult = {
  data: any[];
  error: DbError | null;
  count?: number | null;
};

type DbSingleResult = {
  data: any;
  error: DbError | null;
  count?: number | null;
};

type DbRpcResult = {
  data: any;
  error: DbError | null;
};

type DbQueryBuilder = PromiseLike<DbListResult> & {
  select(columns?: string, options?: { count?: string; head?: boolean }): DbQueryBuilder;
  insert(payload: any): DbQueryBuilder;
  upsert(
    payload: any,
    options?: { onConflict?: string; ignoreDuplicates?: boolean }
  ): DbQueryBuilder;
  update(payload: any): DbQueryBuilder;
  delete(): DbQueryBuilder;
  eq(column: string, value: unknown): DbQueryBuilder;
  neq(column: string, value: unknown): DbQueryBuilder;
  gt(column: string, value: unknown): DbQueryBuilder;
  gte(column: string, value: unknown): DbQueryBuilder;
  lt(column: string, value: unknown): DbQueryBuilder;
  lte(column: string, value: unknown): DbQueryBuilder;
  ilike(column: string, value: string): DbQueryBuilder;
  is(column: string, value: unknown): DbQueryBuilder;
  in(column: string, value: unknown[]): DbQueryBuilder;
  match(values: Record<string, unknown>): DbQueryBuilder;
  or(expression: string): DbQueryBuilder;
  order(column: string, options?: { ascending?: boolean }): DbQueryBuilder;
  range(from: number, to: number): DbQueryBuilder;
  limit(count: number): DbQueryBuilder;
  single(): Promise<DbSingleResult>;
  maybeSingle(): Promise<DbSingleResult>;
};

export type DbClient = {
  from(table: string): DbQueryBuilder;
  rpc(
    functionName: string,
    params?: Record<string, unknown>
  ): Promise<DbRpcResult>;
};

import { query, DbContext } from "./database.config";

type DbLikeResult<T = any> = {
  data: T | null;
  error: Error | null;
  count?: number | null;
};

type Filter = {
  column: string;
  operator: "=" | "!=" | ">" | ">=" | "<" | "<=" | "ILIKE" | "IS" | "IN" | "OR";
  value: unknown;
};

type Order = {
  column: string;
  ascending: boolean;
};

const arrayRpcFunctions = new Set([
  "get_nearby_entities",
  "refresh_entity_transport_relations",
  "refresh_all_entity_transport_relations",
]);

const locationTables = new Set([
  "users",
  "businesses",
  "events",
  "transport_routes",
  "tourist_places",
  "charging_points",
]);

export class PgDbClient {
  constructor(private readonly context: DbContext = {}) {}

  from(table: string) {
    // Native table access is authorized in the API layer. Database context is
    // reserved for RPC functions that explicitly use current_app_user_*().
    return new PgQueryBuilder(table, {});
  }

  async rpc(functionName: string, params: Record<string, unknown> = {}) {
    try {
      const entries = Object.entries(params);
      const values = entries.map(([, value]) => value);
      const args = entries
        .map(([key], index) => `${quoteIdentifier(key)} => $${index + 1}`)
        .join(", ");

      const sql = `SELECT * FROM ${quoteIdentifier(functionName)}(${args})`;
      const result = await query(sql, values, this.context);

      return {
        data: arrayRpcFunctions.has(functionName)
          ? result.rows
          : result.rows.length === 1
            ? result.rows[0]
            : result.rows,
        error: null,
      };
    } catch (error) {
      return {
        data: null,
        error: normalizeError(error),
      };
    }
  }
}

class PgQueryBuilder {
  private action: "select" | "insert" | "update" | "delete" | "upsert" =
    "select";
  private selectColumns = "*";
  private countMode: string | undefined;
  private head = false;
  private insertPayload: Record<string, unknown> | Record<string, unknown>[] | null =
    null;
  private upsertOptions:
    | { onConflict?: string; ignoreDuplicates?: boolean }
    | undefined;
  private updatePayload: Record<string, unknown> | null = null;
  private filters: Filter[] = [];
  private orders: Order[] = [];
  private rangeStart: number | null = null;
  private rangeEnd: number | null = null;
  private limitCount: number | null = null;
  private wantSingle = false;
  private wantMaybeSingle = false;

  constructor(
    private readonly table: string,
    private readonly context: DbContext
  ) {}

  select(columns = "*", options?: { count?: string; head?: boolean }) {
    if (!this.insertPayload && !this.updatePayload && this.action !== "delete") {
      this.action = "select";
    }
    this.selectColumns = columns.trim() || "*";
    this.countMode = options?.count;
    this.head = options?.head ?? false;
    return this;
  }

  insert(payload: Record<string, unknown> | Record<string, unknown>[]) {
    this.action = "insert";
    this.insertPayload = payload;
    return this;
  }

  upsert(
    payload: Record<string, unknown> | Record<string, unknown>[],
    options?: { onConflict?: string; ignoreDuplicates?: boolean }
  ) {
    this.action = "upsert";
    this.insertPayload = payload;
    this.upsertOptions = options;
    return this;
  }

  update(payload: Record<string, unknown>) {
    this.action = "update";
    this.updatePayload = payload;
    return this;
  }

  delete() {
    this.action = "delete";
    return this;
  }

  eq(column: string, value: unknown) {
    this.filters.push({ column, operator: "=", value });
    return this;
  }

  neq(column: string, value: unknown) {
    this.filters.push({ column, operator: "!=", value });
    return this;
  }

  gt(column: string, value: unknown) {
    this.filters.push({ column, operator: ">", value });
    return this;
  }

  gte(column: string, value: unknown) {
    this.filters.push({ column, operator: ">=", value });
    return this;
  }

  lt(column: string, value: unknown) {
    this.filters.push({ column, operator: "<", value });
    return this;
  }

  lte(column: string, value: unknown) {
    this.filters.push({ column, operator: "<=", value });
    return this;
  }

  ilike(column: string, value: string) {
    this.filters.push({ column, operator: "ILIKE", value });
    return this;
  }

  is(column: string, value: unknown) {
    this.filters.push({ column, operator: "IS", value });
    return this;
  }

  in(column: string, value: unknown[]) {
    this.filters.push({ column, operator: "IN", value });
    return this;
  }

  match(values: Record<string, unknown>) {
    Object.entries(values).forEach(([column, value]) => {
      this.eq(column, value);
    });
    return this;
  }

  or(expression: string) {
    this.filters.push({ column: "", operator: "OR", value: expression });
    return this;
  }

  order(column: string, options?: { ascending?: boolean }) {
    this.orders.push({
      column,
      ascending: options?.ascending ?? true,
    });
    return this;
  }

  range(from: number, to: number) {
    this.rangeStart = from;
    this.rangeEnd = to;
    return this;
  }

  limit(count: number) {
    this.limitCount = count;
    return this;
  }

  single() {
    this.wantSingle = true;
    return this.execute();
  }

  maybeSingle() {
    this.wantMaybeSingle = true;
    return this.execute();
  }

  then<TResult1 = DbLikeResult, TResult2 = never>(
    onfulfilled?:
      | ((value: DbLikeResult) => TResult1 | PromiseLike<TResult1>)
      | undefined
      | null,
    onrejected?:
      | ((reason: any) => TResult2 | PromiseLike<TResult2>)
      | undefined
      | null
  ): Promise<TResult1 | TResult2> {
    return this.execute().then(onfulfilled, onrejected);
  }

  catch<TResult = never>(
    onrejected?:
      | ((reason: any) => TResult | PromiseLike<TResult>)
      | undefined
      | null
  ): Promise<DbLikeResult | TResult> {
    return this.execute().catch(onrejected);
  }

  finally(onfinally?: (() => void) | undefined | null) {
    return this.execute().finally(onfinally);
  }

  private async execute(): Promise<DbLikeResult> {
    try {
      const built = this.buildSql();
      const result = await query(built.sql, built.values, this.context);

      if (this.head) {
        return {
          data: null,
          error: null,
          count: Number(result.rows[0]?.count ?? 0),
        };
      }

      const rows = await this.enrichRows(result.rows);

      if (this.wantSingle) {
        if (rows.length !== 1) {
          throw new Error("Expected exactly one row");
        }
        return { data: rows[0], error: null };
      }

      if (this.wantMaybeSingle) {
        if (rows.length > 1) {
          throw new Error("Expected at most one row");
        }
        return { data: rows[0] ?? null, error: null };
      }

      return {
        data: rows,
        error: null,
        count: this.countMode ? rows.length : null,
      };
    } catch (error) {
      return {
        data: null,
        error: normalizeError(error),
      };
    }
  }

  private buildSql() {
    switch (this.action) {
      case "insert":
        return this.buildInsert(false);
      case "upsert":
        return this.buildInsert(true);
      case "update":
        return this.buildUpdate();
      case "delete":
        return this.buildDelete();
      case "select":
      default:
        return this.buildSelect();
    }
  }

  private buildSelect() {
    const values: unknown[] = [];
    const where = this.buildWhere(values);
    const select = this.head
      ? "COUNT(*)::int AS count"
      : this.buildSelectColumns();

    let sql = `SELECT ${select} FROM ${quoteIdentifier(this.table)}${where}`;
    sql += this.buildOrder();
    sql += this.buildLimitOffset(values);

    return { sql, values };
  }

  private buildInsert(upsert: boolean) {
    const rows = Array.isArray(this.insertPayload)
      ? this.insertPayload
      : this.insertPayload
        ? [this.insertPayload]
        : [];

    if (rows.length === 0) throw new Error("Insert payload is empty");

    const columns = Object.keys(rows[0] ?? {});
    const values: unknown[] = [];
    const tuples = rows.map((row) => {
      const placeholders = columns.map((column) => {
        values.push(row[column]);
        return `$${values.length}`;
      });
      return `(${placeholders.join(", ")})`;
    });

    const columnSql = columns.map(quoteIdentifier).join(", ");
    let sql = `INSERT INTO ${quoteIdentifier(this.table)} (${columnSql}) VALUES ${tuples.join(", ")}`;

    if (upsert) {
      const conflict = this.upsertOptions?.onConflict
        ? this.upsertOptions.onConflict
        : columns.includes("id")
          ? "id"
          : columns[0];
      if (!conflict) throw new Error("Upsert conflict column is required");

      if (this.upsertOptions?.ignoreDuplicates) {
        sql += ` ON CONFLICT (${quoteIdentifier(conflict)}) DO NOTHING`;
        sql += ` RETURNING ${this.buildSelectColumns()}`;
        return { sql, values };
      }

      const updates = columns
        .filter((column) => column !== conflict)
        .map(
          (column) =>
            `${quoteIdentifier(column)} = EXCLUDED.${quoteIdentifier(column)}`
        );

      sql += ` ON CONFLICT (${quoteIdentifier(conflict)}) DO UPDATE SET ${updates.join(", ")}`;
    }

    sql += ` RETURNING ${this.buildSelectColumns()}`;

    return { sql, values };
  }

  private buildUpdate() {
    if (!this.updatePayload) throw new Error("Update payload is empty");

    const values: unknown[] = [];
    const sets = Object.entries(this.updatePayload).map(([column, value]) => {
      values.push(value);
      return `${quoteIdentifier(column)} = $${values.length}`;
    });

    const where = this.buildWhere(values);
    const sql = `UPDATE ${quoteIdentifier(this.table)} SET ${sets.join(", ")}${where} RETURNING ${this.buildSelectColumns()}`;

    return { sql, values };
  }

  private buildDelete() {
    const values: unknown[] = [];
    const where = this.buildWhere(values);
    const sql = `DELETE FROM ${quoteIdentifier(this.table)}${where} RETURNING ${this.buildSelectColumns()}`;

    return { sql, values };
  }

  private buildWhere(values: unknown[]) {
    if (this.filters.length === 0) return "";

    const clauses = this.filters.map((filter) => {
      if (filter.operator === "OR") {
        return `(${buildOrExpression(String(filter.value), values)})`;
      }

      if (filter.operator === "IS") {
        return `${quotePath(filter.column)} IS ${filter.value === null ? "NULL" : "NOT NULL"}`;
      }

      if (filter.operator === "IN") {
        values.push(filter.value);
        return `${quotePath(filter.column)} = ANY($${values.length})`;
      }

      if (
        this.table === "payment_requests" &&
        filter.column === "payments.method" &&
        filter.operator === "="
      ) {
        values.push(filter.value);
        return `EXISTS (
          SELECT 1
          FROM payments
          WHERE payments.id = payment_requests.payment_id
            AND payments.method = $${values.length}
        )`;
      }

      values.push(filter.value);
      return `${quotePath(filter.column)} ${filter.operator} $${values.length}`;
    });

    return ` WHERE ${clauses.join(" AND ")}`;
  }

  private buildOrder() {
    if (this.orders.length === 0) return "";

    const orderSql = this.orders
      .map(
        (order) =>
          `${quotePath(order.column)} ${order.ascending ? "ASC" : "DESC"}`
      )
      .join(", ");

    return ` ORDER BY ${orderSql}`;
  }

  private buildLimitOffset(values: unknown[]) {
    if (this.rangeStart !== null && this.rangeEnd !== null) {
      values.push(this.rangeEnd - this.rangeStart + 1);
      const limitParam = values.length;
      values.push(this.rangeStart);
      return ` LIMIT $${limitParam} OFFSET $${values.length}`;
    }

    if (this.limitCount !== null) {
      values.push(this.limitCount);
      return ` LIMIT $${values.length}`;
    }

    return "";
  }

  private buildSelectColumns() {
    if (this.selectColumns === "*" || this.selectColumns.includes("(")) {
      if (locationTables.has(this.table)) {
        return `*, encode(ST_AsEWKB(location::geometry), 'hex') AS location`;
      }
      return "*";
    }

    return this.selectColumns
      .split(",")
      .map((column) => quotePath(column.trim()))
      .join(", ");
  }

  private async enrichRows(rows: any[]) {
    if (rows.length === 0 || !this.selectColumns.includes("(")) {
      return rows;
    }

    if (
      this.table === "business_claim_requests" &&
      this.selectColumns.includes("business:businesses")
    ) {
      return this.withBusinesses(rows);
    }

    if (
      this.selectColumns.includes("business:business_id") &&
      rows.some((row) => row.business_id !== undefined)
    ) {
      return this.withBusinesses(rows);
    }

    if (this.table === "event_tickets") {
      let enriched = rows;

      if (this.selectColumns.includes("event_ticket_days")) {
        enriched = await this.withTicketDays(enriched);
      }

      if (this.selectColumns.includes("users:user_id")) {
        enriched = await this.withTicketUsers(enriched);
      }

      return enriched;
    }

    if (this.table === "event_ticket_days") {
      let enriched = rows;

      if (this.selectColumns.includes("event_tickets:ticket_id")) {
        enriched = await this.withDayTickets(enriched);
      }

      if (this.selectColumns.includes("events:event_id")) {
        enriched = await this.withDayEvents(enriched);
      }

      return enriched;
    }

    if (
      this.table === "transport_lines" &&
      this.selectColumns.includes("transport_routes")
    ) {
      return this.withTransportRouteIds(rows);
    }

    if (
      this.table === "tourist_place_tags" &&
      this.selectColumns.includes("tag:tags")
    ) {
      return this.withTags(rows);
    }

    return rows;
  }

  private async withBusinesses(rows: any[]) {
    const ids = uniqueValues(rows.map((row) => row.business_id));
    if (ids.length === 0) return rows;

    const result = await query(
      `SELECT *, encode(ST_AsEWKB(location::geometry), 'hex') AS location
       FROM businesses
       WHERE id = ANY($1)`,
      [ids],
      this.context
    );
    const byId = new Map(result.rows.map((row) => [row.id, row]));

    return rows.map((row) => ({
      ...row,
      business: byId.get(row.business_id) ?? null,
    }));
  }

  private async withTicketDays(rows: any[]) {
    const ids = uniqueValues(rows.map((row) => row.id));
    if (ids.length === 0) return rows;

    const result = await query(
      `SELECT *
       FROM event_ticket_days
       WHERE ticket_id = ANY($1)
       ORDER BY valid_from ASC`,
      [ids],
      this.context
    );
    const byTicketId = groupBy(result.rows, "ticket_id");

    return rows.map((row) => ({
      ...row,
      event_ticket_days: byTicketId.get(row.id) ?? [],
    }));
  }

  private async withTicketUsers(rows: any[]) {
    const ids = uniqueValues(rows.map((row) => row.user_id));
    if (ids.length === 0) return rows;

    const result = await query(
      `SELECT id, username, first_name, last_name, ci
       FROM users
       WHERE id = ANY($1)`,
      [ids],
      this.context
    );
    const byId = new Map(result.rows.map((row) => [row.id, row]));

    return rows.map((row) => ({
      ...row,
      users: byId.get(row.user_id) ?? null,
    }));
  }

  private async withDayTickets(rows: any[]) {
    const ids = uniqueValues(rows.map((row) => row.ticket_id));
    if (ids.length === 0) return rows;

    const result = await query(
      `SELECT *
       FROM event_tickets
       WHERE id = ANY($1)`,
      [ids],
      this.context
    );
    const byId = new Map(result.rows.map((row) => [row.id, row]));

    return rows.map((row) => ({
      ...row,
      event_tickets: byId.get(row.ticket_id) ?? null,
    }));
  }

  private async withDayEvents(rows: any[]) {
    const ids = uniqueValues(rows.map((row) => row.event_id));
    if (ids.length === 0) return rows;

    const result = await query(
      `SELECT *, encode(ST_AsEWKB(location::geometry), 'hex') AS location
       FROM events
       WHERE id = ANY($1)`,
      [ids],
      this.context
    );
    const byId = new Map(result.rows.map((row) => [row.id, row]));

    return rows.map((row) => ({
      ...row,
      events: byId.get(row.event_id) ?? null,
    }));
  }

  private async withTransportRouteIds(rows: any[]) {
    const ids = uniqueValues(rows.map((row) => row.id));
    if (ids.length === 0) return rows;

    const result = await query(
      `SELECT id, transport_line_id
       FROM transport_routes
       WHERE transport_line_id = ANY($1)
       ORDER BY stop_order ASC`,
      [ids],
      this.context
    );
    const byLineId = groupBy(result.rows, "transport_line_id");

    return rows.map((row) => ({
      ...row,
      transport_routes: byLineId.get(row.id) ?? [],
    }));
  }

  private async withTags(rows: any[]) {
    const ids = uniqueValues(rows.map((row) => row.tag_id));
    if (ids.length === 0) return rows;

    const result = await query(
      `SELECT id, name, description, status, created_at, updated_at
       FROM tags
       WHERE id = ANY($1)`,
      [ids],
      this.context
    );
    const byId = new Map(result.rows.map((row) => [row.id, row]));

    return rows.map((row) => ({
      ...row,
      tag: byId.get(row.tag_id) ?? null,
    }));
  }
}

function uniqueValues(values: unknown[]) {
  return [...new Set(values.filter((value) => value !== null && value !== undefined))];
}

function groupBy(rows: any[], key: string) {
  const groups = new Map<unknown, any[]>();

  rows.forEach((row) => {
    const value = row[key];
    const existing = groups.get(value) ?? [];
    existing.push(row);
    groups.set(value, existing);
  });

  return groups;
}

function buildOrExpression(expression: string, values: unknown[]) {
  return expression
    .split(",")
    .map((part) => {
      const [column, operator, ...rawValueParts] = part.split(".");
      const rawValue = rawValueParts.join(".");

      if (!column || !operator) {
        throw new Error(`Unsupported OR expression: ${part}`);
      }

      if (operator === "is") {
        return `${quotePath(column)} IS ${rawValue === "null" ? "NULL" : "NOT NULL"}`;
      }

      values.push(rawValue);

      if (operator === "eq") return `${quotePath(column)} = $${values.length}`;
      if (operator === "gt") return `${quotePath(column)} > $${values.length}`;
      if (operator === "lt") return `${quotePath(column)} < $${values.length}`;

      throw new Error(`Unsupported OR operator: ${operator}`);
    })
    .join(" OR ");
}

function quotePath(path: string) {
  const clean = path.split("!")[0] ?? path;
  return clean.split(".").map(quoteIdentifier).join(".");
}

function quoteIdentifier(identifier: string) {
  if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(identifier)) {
    throw new Error(`Invalid SQL identifier: ${identifier}`);
  }

  return `"${identifier}"`;
}

function normalizeError(error: unknown): Error {
  if (error instanceof Error) return error;
  return new Error(String(error));
}

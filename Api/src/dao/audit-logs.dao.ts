import { DbClient } from "../types/db-client";
import { AuditLog } from "../dto/audit-log.dto";
import { AuditLogCreateInput } from "../validation/audit-logs.validation";

export class AuditLogsDAO {
  private table = "audit_logs";
  constructor(private db: DbClient) { }

  private mapToDomain(row: any): AuditLog {
    return {
      ...row,
      created_at: new Date(row.created_at),
    };
  }

  async create(data: AuditLogCreateInput): Promise<AuditLog> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert(data)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToDomain(result);
  }

  async findAll(limit = 50, offset = 0): Promise<AuditLog[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    return data.map((row) => this.mapToDomain(row));
  }

  async findById(id: number): Promise<AuditLog | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToDomain(data) : null;
  }

  async findByUser(
    user_id: string,
    limit = 50,
    offset = 0
  ): Promise<AuditLog[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", user_id)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    return data.map((row) => this.mapToDomain(row));
  }

  async findByEntity(
    entity_type: string,
    entity_id: number
  ): Promise<AuditLog[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("entity_type", entity_type)
      .eq("entity_id", entity_id)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return data.map((row) => this.mapToDomain(row));
  }

  async findByFilters(params: {
    user_id?: string;
    entity_type?: string;
    entity_id?: number;
    action?: string;
    limit?: number;
    offset?: number;
  }): Promise<AuditLog[]> {
    let query = this.db.from(this.table).select("*");

    if (params.user_id) {
      query = query.eq("user_id", params.user_id);
    }

    if (params.entity_type) {
      query = query.eq("entity_type", params.entity_type);
    }

    if (params.entity_id) {
      query = query.eq("entity_id", params.entity_id);
    }

    if (params.action) {
      query = query.eq("action", params.action);
    }

    query = query.order("created_at", { ascending: false });

    if (params.limit !== undefined && params.offset !== undefined) {
      query = query.range(
        params.offset,
        params.offset + params.limit - 1
      );
    }

    const { data, error } = await query;

    if (error) throw error;

    return data.map((row) => this.mapToDomain(row));
  }
}
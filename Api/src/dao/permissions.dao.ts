import { DbClient } from "../types/db-client";
import { Permission } from "../dto/permission.dto";
import { PermissionCreateInput, PermissionUpdateInput,
} from "../validation/permissions.validation";

export class PermissionsDAO {
  private table = "permissions";
  constructor(private db: DbClient) { }

  private mapToDomain(row: any): Permission {
    if (!row) return row;

    return {
      ...row,
      created_at: new Date(row.created_at),
    };
  }

  async create(data: PermissionCreateInput): Promise<Permission> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(result);
  }

  async getAll(): Promise<Permission[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("id");

    if (error) throw error;
    return (data || []).map((row) => this.mapToDomain(row));
  }

  async getById(id: number): Promise<Permission | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async getByCode(code: string): Promise<Permission | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("code", code)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async getByCodes(codes: string[]): Promise<Permission[]> {
    if (codes.length === 0) return [];

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("code", codes)
      .order("id");

    if (error) throw error;
    return (data || []).map((row) => this.mapToDomain(row));
  }

  async update(
    id: number,
    updates: PermissionUpdateInput
  ): Promise<Permission> {
    const { data, error } = await this.db
      .from(this.table)
      .update(updates)
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(data);
  }

  async delete(id: number): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", id);

    if (error) throw error;
  }
}

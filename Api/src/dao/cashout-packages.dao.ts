import { DbClient } from "../types/db-client";
import { CashoutPackage } from "../dto/cashout-package.dto";
import { CashoutPackageCreateInput, CashoutPackageUpdateInput,
} from "../validation/cashout-packages.validation";

export class CashoutPackagesDAO {
  private table = "cashout_packages";
  constructor(private db: DbClient) { }

  private mapToDomain(row: any): CashoutPackage {
    return {
      ...row,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(data: CashoutPackageCreateInput): Promise<CashoutPackage> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert({
        ...data,
        status: "active",
        created_at: new Date().toISOString(),
      })
      .select("*")
      .single();

    if (error) throw error;
    return this.mapToDomain(result);
  }

  // 🔹 Solo paquetes activos (para uso normal)
  async findAll(): Promise<CashoutPackage[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", "active")
      .order("cash_amount", { ascending: true });

    if (error) throw error;
    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  // 🔹 Para panel admin (ve todo)
  async findAllAdmin(): Promise<CashoutPackage[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findById(id: number): Promise<CashoutPackage | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async update(
    id: number,
    updates: CashoutPackageUpdateInput
  ): Promise<CashoutPackage> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        ...updates,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;
    return this.mapToDomain(data);
  }

  async softDelete(id: number): Promise<CashoutPackage> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "archived",
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToDomain(data);
  }

  // 🟡 Desactivar (sin archivar)
  async deactivate(id: number): Promise<CashoutPackage> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "inactive",
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;
    return this.mapToDomain(data);
  }

  // 🟢 Reactivar
  async activate(id: number): Promise<CashoutPackage> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "active",
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;
    return this.mapToDomain(data);
  }
}
import { DbClient } from "../types/db-client";
import { CoinPackage } from "../dto/coin-package.dto";
import { CoinPackageCreateInput, CoinPackageUpdateInput } from "../validation/coin-packages.validation";
import { BasicStatus } from "../constants/enums.constants";

export class CoinPackagesDAO {
  private table = "coin_packages";
  constructor(private db: DbClient) {}

  private mapToDomain(row: any): CoinPackage {
    return {
      ...row,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(data: CoinPackageCreateInput): Promise<CoinPackage> {
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

  async findAll(): Promise<CoinPackage[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", "active")
      .order("tinkus_amount", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findAllAdmin(): Promise<CoinPackage[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findById(id: number): Promise<CoinPackage | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToDomain(data) : null;
  }

  async findActiveById(id: number): Promise<CoinPackage | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .eq("status", "active")
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToDomain(data) : null;
  }

  async findPartnerUpgradePackage(): Promise<CoinPackage | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("name", "partner_upgrade")
      .eq("status", "active")
      .single();

    if (error) return null;

    return data;
  }

  async update(
    id: number,
    updates: CoinPackageUpdateInput
  ): Promise<CoinPackage> {
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

  async softDelete(id: number): Promise<CoinPackage> {
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

  async deactivate(id: number): Promise<CoinPackage> {
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

  async activate(id: number): Promise<CoinPackage> {
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

  async findByFilters(params: {
    status?: BasicStatus;
  }): Promise<CoinPackage[]> {
    let query = this.db.from(this.table).select("*");

    if (params.status) {
      query = query.eq("status", params.status);
    }

    const { data, error } = await query.order("tinkus_amount", {
      ascending: true,
    });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }
}
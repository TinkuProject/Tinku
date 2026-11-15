import { DbClient } from "../types/db-client";
import { Discount } from "../dto/discount.dto";
import { DiscountCreateInput, DiscountUpdateInput } from "../validation/discounts.validation";
import { query } from "../config/database.config";

export class DiscountsDAO {
  private table = "discounts";
  constructor(private db: DbClient) {}

  private mapToDomain(row: any): Discount {
    if (!row) return row;

    return {
      ...row,
      start_date: new Date(row.start_date),
      end_date: new Date(row.end_date),
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(data: DiscountCreateInput): Promise<Discount> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(result);
  }

  async createWithCharge(data: DiscountCreateInput, userId: string) {
    const { data: result, error } = await this.db.rpc(
      "create_discount_with_charge",
      {
        p_user_id: userId,
        p_business_id: data.business_id,
        p_description: data.description ?? null,
        p_discount_percent: data.discount_percent,
        p_start_date: data.start_date,
        p_end_date: data.end_date,
        p_status: data.status ?? "active",
      }
    );

    if (error) throw error;

    return this.mapToDomain(result);
  }

  async getAll(): Promise<Discount[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data || []).map((row) => this.mapToDomain(row));
  }

  async getById(id: number): Promise<Discount | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async getMine(userId: string): Promise<Discount[]> {
    const result = await query(
      `SELECT d.*
       FROM discounts d
       JOIN businesses b ON b.id = d.business_id
       WHERE b.owner_id = $1
       ORDER BY d.created_at DESC`,
      [userId]
    );

    return result.rows.map((row) => this.mapToDomain(row));
  }

  async getByBusinessId(businessId: number): Promise<Discount[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("business_id", businessId)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data || []).map((row) => this.mapToDomain(row));
  }

  async getActive(): Promise<Discount[]> {
    const now = new Date().toISOString();
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", "active")
      .lte("start_date", now)
      .gte("end_date", todayStart.toISOString())
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data || []).map((row) => this.mapToDomain(row));
  }

  async getActiveByBusinessId(businessId: number): Promise<Discount[]> {
    const now = new Date().toISOString();
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("business_id", businessId)
      .eq("status", "active")
      .lte("start_date", now)
      .gte("end_date", todayStart.toISOString())
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data || []).map((row) => this.mapToDomain(row));
  }

  async getByBusinessIds(
    businessIds: number[],
    activeOnly = false
  ): Promise<Record<string, Discount[]>> {
    const uniqueIds = [...new Set(businessIds)];
    const now = new Date().toISOString();
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    let query = this.db
      .from(this.table)
      .select("*")
      .in("business_id", uniqueIds)
      .order("created_at", { ascending: false });

    if (activeOnly) {
      query = query
        .eq("status", "active")
        .lte("start_date", now)
        .gte("end_date", todayStart.toISOString());
    }

    const { data, error } = await query;

    if (error) throw error;

    const result: Record<string, Discount[]> = {};

    for (const row of data || []) {
      const mapped = this.mapToDomain(row);
      const key = String(mapped.business_id);

      if (!result[key]) {
        result[key] = [];
      }

      result[key].push(mapped);
    }

    return result;
  }

  async update(id: number, updates: DiscountUpdateInput): Promise<Discount> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        ...updates,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(data);
  }

  async softDelete(id: number): Promise<Discount> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "cancelled",
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToDomain(data);
  }
}

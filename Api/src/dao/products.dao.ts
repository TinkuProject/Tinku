import { DbClient } from "../types/db-client";
import { Product } from "../dto/product.dto";
import { ProductInsert, ProductUpdateInput } from "../validation/products.validation";
import { query } from "../config/database.config";

export class ProductsDAO {
  private table = "products";
  constructor(private db: DbClient) { }

  private mapToDomain(row: any): Product {
    if (!row) return row;

    return {
      ...row,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(data: ProductInsert): Promise<Product> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert({
        ...data,
        status: (data as any).status ?? "active",
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(result);
  }

  async getAll(): Promise<Product[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data || []).map((r) => this.mapToDomain(r));
  }

  async getActive(): Promise<Product[]> {
    const result = await query(
      `SELECT p.*
       FROM products p
       JOIN businesses b ON b.id = p.business_id
       WHERE p.status = 'active'
         AND b.status = 'active'
         AND b.validated = true
       ORDER BY p.created_at DESC`
    );

    return result.rows.map((row) => this.mapToDomain(row));
  }

  async getById(id: number): Promise<Product | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async getPublicById(id: number): Promise<Product | null> {
    const result = await query(
      `SELECT p.*
       FROM products p
       JOIN businesses b ON b.id = p.business_id
       WHERE p.id = $1
         AND p.status = 'active'
         AND b.status = 'active'
         AND b.validated = true
       LIMIT 1`,
      [id]
    );

    const row = result.rows[0];
    return row ? this.mapToDomain(row) : null;
  }

  async getByBusiness(businessId: number): Promise<Product[]> {
    const result = await query(
      `SELECT p.*
       FROM products p
       JOIN businesses b ON b.id = p.business_id
       WHERE p.business_id = $1
         AND p.status = 'active'
         AND b.status = 'active'
         AND b.validated = true
       ORDER BY p.created_at DESC`,
      [businessId]
    );

    return result.rows.map((row) => this.mapToDomain(row));
  }

  async getMine(userId: string): Promise<Product[]> {
    const result = await query(
      `SELECT p.*
       FROM products p
       JOIN businesses b ON b.id = p.business_id
       WHERE b.owner_id = $1
       ORDER BY p.created_at DESC`,
      [userId]
    );

    return result.rows.map((row) => this.mapToDomain(row));
  }

  async getByBusinesses(businessIds: number[]
  ): Promise<Record<number, Product[]>> {
    if (businessIds.length === 0) return {};

    const queryResult = await query(
      `SELECT p.*
       FROM products p
       JOIN businesses b ON b.id = p.business_id
       WHERE p.business_id = ANY($1::bigint[])
         AND p.status = 'active'
         AND b.status = 'active'
         AND b.validated = true
       ORDER BY p.created_at DESC`,
      [businessIds]
    );

    const result: Record<number, Product[]> = {};

    for (const row of queryResult.rows) {
      const mapped = this.mapToDomain(row);
      const key = mapped.business_id;

      if (!result[key]) {
        result[key] = [];
      }

      result[key].push(mapped);
    }

    return result;
  }

  async getByBusinessesAdmin(
    businessIds: number[]
  ): Promise<Record<number, Product[]>> {
    if (businessIds.length === 0) return {};

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("business_id", businessIds)
      .order("created_at", { ascending: false });

    if (error) throw error;

    const result: Record<number, Product[]> = {};
    for (const row of data ?? []) {
      const mapped = this.mapToDomain(row);
      (result[mapped.business_id] ??= []).push(mapped);
    }
    return result;
  }

  async getByBusinessAdmin(
    businessId: number
  ): Promise<Product[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("business_id", businessId)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data || []).map((r) => this.mapToDomain(r));
  }

  async update(
    id: number,
    updates: ProductUpdateInput
  ): Promise<Product> {
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

  async softDelete(id: number): Promise<Product> {
    return this.update(id, {
      status: "inactive",
    });
  }
}

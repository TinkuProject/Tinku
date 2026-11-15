import { DbClient } from "../types/db-client";
import { Category } from "../dto/category.dto";
import { CategoryCreateInput, CategoryUpdateInput } from "../validation/categories.validation";
import { CategoryEntityType, BasicStatus, BusinessType } from "../constants/enums.constants";

export class CategoriesDAO {
  private table = "categories";
  constructor(private db: DbClient) { }

  private mapToDomain(row: any): Category {
    return {
      ...row,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(data: CategoryCreateInput): Promise<Category> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert({
        ...data,
        status: "active",
        created_at: new Date().toISOString(),
      })
      .select("*")
      .maybeSingle();

    if (error) throw error;
    if (!result) throw new Error("Insert succeeded but no data returned");

    return this.mapToDomain(result);
  }

  async findAll(): Promise<Category[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", "active")
      .order("name", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findAllAdmin(): Promise<Category[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findById(id: number): Promise<Category | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToDomain(data) : null;
  }

  async findByIds(ids: number[]): Promise<Category[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("id", ids)
      .eq("status", "active");

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async update(
    id: number,
    updates: CategoryUpdateInput
  ): Promise<Category> {
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

  async softDelete(id: number): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .update({
        status: "archived",
        updated_at: new Date().toISOString(),
      })
      .eq("id", id);

    if (error) throw error;
  }

  async deactivate(id: number): Promise<Category> {
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

  async activate(id: number): Promise<Category> {
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
    entity_type?: CategoryEntityType;
    status?: BasicStatus;
    business_type?: BusinessType | null;
  }): Promise<Category[]> {
    let query = this.db.from(this.table).select("*");

    if (params.entity_type) {
      query = query.eq("entity_type", params.entity_type);
    }

    if (params.status) {
      query = query.eq("status", params.status);
    } else {
      query = query.eq("status", "active");
    }

    if (params.entity_type === "business") {
      if (params.business_type !== undefined) {
        query = query.eq("business_type", params.business_type);
      }
    }

    const { data, error } = await query.order("name", {
      ascending: true,
    });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }
}
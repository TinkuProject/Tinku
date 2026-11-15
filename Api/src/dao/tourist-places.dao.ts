import { DbClient } from "../types/db-client";
import { TouristPlace } from "../dto/tourist-place.dto";
import { TouristPlaceCreateInput, TouristPlaceUpdateInput,
  TouristPlaceIdInput, TouristPlaceCategoryInput,
} from "../validation/tourist-places.validation";
import { buildPoint, parseLocation } from "../utils/location";

export class TouristPlacesDAO {
  private table = "tourist_places";
  constructor(private readonly db: DbClient) {}

  private mapToEntity(data: any): TouristPlace {
    const parsed = parseLocation(data.location);

    if (!parsed) {
      throw new Error("Location is required but was null from DB");
    }

    return {
      id: data.id,
      category_id: data.category_id,
      name: data.name,
      description: data.description ?? null,
      address: data.address ?? null,
      created_by: data.created_by ?? null,
      location: parsed,
      status: data.status,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at ? new Date(data.updated_at) : null,
    };
  }

  async create(
    input: TouristPlaceCreateInput,
    createdBy?: string
  ): Promise<TouristPlace> {
    const { location, ...rest } = input;

    const payload = {
      ...rest,
      created_by: createdBy ?? null,
      location: buildPoint({
        coordinates: [location.longitude, location.latitude],
      }),
    };

    const { data, error } = await this.db
      .from(this.table)
      .insert(payload)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findAll(limit?: number, offset = 0): Promise<TouristPlace[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .in("status", ["active", "inactive"])
      .order("created_at", { ascending: false });

    if (limit !== undefined) {
      query = query.range(offset, offset + limit - 1);
    }

    const { data, error } = await query;

    if (error) throw error;

    return (data ?? []).map((item) => this.mapToEntity(item));
  }

  async findPublic(
    limit?: number,
    offset = 0,
    filters: { query?: string; categoryId?: number } = {}
  ): Promise<TouristPlace[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .eq("status", "active")
      .order("created_at", { ascending: false });

    if (filters.query) query = query.ilike("name", `%${filters.query}%`);
    if (filters.categoryId) query = query.eq("category_id", filters.categoryId);
    if (limit !== undefined) query = query.range(offset, offset + limit - 1);

    const { data, error } = await query;
    if (error) throw error;
    return (data ?? []).map((item) => this.mapToEntity(item));
  }

  async countPublic(
    filters: { query?: string; categoryId?: number } = {}
  ): Promise<number> {
    let query = this.db
      .from(this.table)
      .select("*", { count: "exact", head: true })
      .eq("status", "active");

    if (filters.query) query = query.ilike("name", `%${filters.query}%`);
    if (filters.categoryId) query = query.eq("category_id", filters.categoryId);

    const { count, error } = await query;
    if (error) throw error;
    return count ?? 0;
  }

  async findMine(userId: string, limit?: number, offset = 0): Promise<TouristPlace[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .eq("created_by", userId)
      .in("status", ["active", "inactive"])
      .order("created_at", { ascending: false });

    if (limit !== undefined) {
      query = query.range(offset, offset + limit - 1);
    }

    const { data, error } = await query;

    if (error) throw error;

    return (data ?? []).map((item) => this.mapToEntity(item));
  }

  async findById(input: TouristPlaceIdInput): Promise<TouristPlace | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findByIds(ids: number[]): Promise<TouristPlace[]> {
    if (ids.length === 0) return [];

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("id", ids);

    if (error) throw error;

    return (data ?? []).map((item) => this.mapToEntity(item));
  }

  async findByCategory(
    input: TouristPlaceCategoryInput
  ): Promise<TouristPlace[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("category_id", input.category_id)
      .in("status", ["active", "inactive"]);

    if (error) throw error;

    return (data ?? []).map((item) => this.mapToEntity(item));
  }

  async update(input: TouristPlaceUpdateInput): Promise<TouristPlace> {
    const { id, location, ...rest } = input;

    const payload: any = {
      ...rest,
      updated_at: new Date().toISOString(),
    };

    if (location) {
      payload.location = buildPoint({
        coordinates: [location.longitude, location.latitude],
      });
    }

    const { data, error } = await this.db
      .from(this.table)
      .update(payload)
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async softDelete(input: TouristPlaceIdInput): Promise<TouristPlace> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "archived",
        updated_at: new Date().toISOString(),
      })
      .eq("id", input.id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async exists(input: TouristPlaceIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}

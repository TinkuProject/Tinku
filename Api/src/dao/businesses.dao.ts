import { DbClient } from "../types/db-client";
import { Business } from "../dto/business.dto";
import { BusinessCreateInput, BusinessUpdateInput, BusinessIdInput,
  AdminBusinessUpdateInput } from "../validation/businesses.validation";
import { parseLocation, buildPoint } from "../utils/location";
import { BusinessStatus } from "../constants/enums.constants";

export class BusinessesDAO {
  private table = "businesses";
  constructor(private readonly db: DbClient) { }

  private mapToEntity(data: any): Business {
    const parsedLocation = parseLocation(data.location);

    if (!parsedLocation) {
      throw new Error("Location is required but was null from DB");
    }

    return {
      id: data.id,
      category_id: data.category_id,
      owner_id: data.owner_id,
      name: data.name,
      nit: data.nit,
      description: data.description,
      phone: data.phone,
      email: data.email,
      business_type: data.business_type,
      address: data.address,
      location: parsedLocation,
      website: data.website,
      validated: data.validated,
      status: data.status,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at ? new Date(data.updated_at) : null,
    };
  }

  async create(
    input: BusinessCreateInput & {
      owner_id?: string | null;
      status?: BusinessStatus;
      validated?: boolean;
    }
  ): Promise<Business> {
    const { location, ...rest } = input;

    const { data, error } = await this.db
      .from(this.table)
      .insert({
        ...rest,
        owner_id: input.owner_id ?? null,
        validated: input.validated ?? false,
        location: buildPoint({
          coordinates: [location.longitude, location.latitude],
        }),
        status: input.status ?? "pending",
      })
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findAll(limit?: number, offset = 0): Promise<Business[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (limit !== undefined) {
      query = query.range(offset, offset + limit - 1);
    }

    const { data, error } = await query;

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findActiveValidated(
    limit?: number,
    offset = 0,
    filters: {
      query?: string;
      categoryId?: number;
      businessType?: string;
      excludeBusinessType?: string;
    } = {}
  ): Promise<Business[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .eq("status", "active")
      .eq("validated", true)
      .order("created_at", { ascending: false });

    if (filters.query) query = query.ilike("name", `%${filters.query}%`);
    if (filters.categoryId) query = query.eq("category_id", filters.categoryId);
    if (filters.businessType) {
      query = query.eq("business_type", filters.businessType);
    }
    if (filters.excludeBusinessType) {
      query = query.neq("business_type", filters.excludeBusinessType);
    }

    if (limit !== undefined) {
      query = query.range(offset, offset + limit - 1);
    }

    const { data, error } = await query;

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async countActiveValidated(
    filters: {
      query?: string;
      categoryId?: number;
      businessType?: string;
      excludeBusinessType?: string;
    } = {}
  ): Promise<number> {
    let query = this.db
      .from(this.table)
      .select("*", { count: "exact", head: true })
      .eq("status", "active")
      .eq("validated", true);

    if (filters.query) query = query.ilike("name", `%${filters.query}%`);
    if (filters.categoryId) query = query.eq("category_id", filters.categoryId);
    if (filters.businessType) query = query.eq("business_type", filters.businessType);
    if (filters.excludeBusinessType) {
      query = query.neq("business_type", filters.excludeBusinessType);
    }

    const { count, error } = await query;
    if (error) throw error;
    return count ?? 0;
  }

  async findById(
    input: BusinessIdInput
  ): Promise<Business | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findPublicById(input: BusinessIdInput): Promise<Business | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .eq("status", "active")
      .eq("validated", true)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToEntity(data) : null;
  }

  async findByIds(ids: number[]): Promise<Business[]> {
    if (ids.length === 0) return [];

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("id", ids);

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findPublicByIds(ids: number[]): Promise<Business[]> {
    if (ids.length === 0) return [];

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("id", ids)
      .eq("status", "active")
      .eq("validated", true);

    if (error) throw error;
    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByOwner(owner_id: string): Promise<Business[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("owner_id", owner_id)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findIdsByOwner(owner_id: string): Promise<number[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("owner_id", owner_id);

    if (error) throw error;

    return (data ?? []).map((i) => Number(i.id)).filter((id) => id > 0);
  }

  async findPromotableByOwner(owner_id: string): Promise<Business[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("owner_id", owner_id)
      .eq("validated", true)
      .eq("status", "active")
      .order("name", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findClaimable(): Promise<Business[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .is("owner_id", null)
      .eq("status", "active")
      .order("name");

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByCategory(
    category_id: number,
    publicOnly = true
  ): Promise<Business[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .eq("category_id", category_id)
      .order("created_at", { ascending: false });

    if (publicOnly) {
      query = query.eq("status", "active").eq("validated", true);
    }

    const { data, error } = await query;

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async update(
    input: BusinessUpdateInput & BusinessIdInput
  ): Promise<Business> {
    const { id, location, ...rest } = input;

    const updateData: any = {
      ...rest,
      updated_at: new Date().toISOString(),
    };

    if (location) {
      updateData.location = buildPoint({
        coordinates: [location.longitude, location.latitude],
      });
    }

    const { data, error } = await this.db
      .from(this.table)
      .update(updateData)
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async adminUpdate(
    input: AdminBusinessUpdateInput & BusinessIdInput
  ): Promise<Business> {
    const { id, ...rest } = input;

    const { data, error } = await this.db
      .from(this.table)
      .update(rest)
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async validate(input: BusinessIdInput): Promise<Business> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "active",
        validated: true,
        updated_at: new Date().toISOString(),
      })
      .eq("id", input.id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async reject(input: BusinessIdInput): Promise<Business> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "suspended",
        validated: false,
        updated_at: new Date().toISOString(),
      })
      .eq("id", input.id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async softDelete(input: BusinessIdInput): Promise<Business> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "inactive",
        updated_at: new Date().toISOString(),
      })
      .eq("id", input.id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async exists(input: BusinessIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }

  async findByStatus(status: BusinessStatus): Promise<Business[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", status)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }
}

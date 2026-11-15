import { DbClient } from "../types/db-client";
import { Event } from "../dto/event.dto";
import { EventCreateInput, EventUpdateInput, EventIdInput,
} from "../validation/events.validation";
import { parseLocation, buildPoint } from "../utils/location";
import { EventStatus } from "../constants/enums.constants";

export class EventsDAO {
  private table = "events";
  constructor(private readonly db: DbClient) { }

  private mapToEntity(data: any): Event {
    const parsedLocation = parseLocation(data.location);

    if (!parsedLocation) {
      throw new Error("Location is required but was null from DB");
    }

    return {
      id: data.id,
      business_id: data.business_id,
      creator_id: data.creator_id,
      category_id: data.category_id,
      name: data.name,
      description: data.description,
      start_date: new Date(data.start_date),
      end_date: new Date(data.end_date),
      capacity: data.capacity,
      attendees_count: data.attendees_count,
      tinku_price: data.tinku_price,
      address: data.address,
      location: parsedLocation,
      status: data.status,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at
        ? new Date(data.updated_at)
        : null,
    };
  }

  async create(
    input: EventCreateInput & { creator_id: string, status?: EventStatus; }
  ): Promise<Event> {
    const { location, ...rest } = input;

    const { data, error } = await this.db
      .from(this.table)
      .insert({
        ...rest,
        creator_id: input.creator_id,
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

  async findAll(
    limit?: number,
    offset = 0,
    publicOnly = true,
    filters: { query?: string; categoryId?: number } = {}
  ): Promise<Event[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .order("start_date", { ascending: true })
      .order("id", { ascending: true });

    if (publicOnly) {
      query = query
        .eq("status", "active")
        .gte("end_date", new Date().toISOString());
    }

    if (filters.query) query = query.ilike("name", `%${filters.query}%`);
    if (filters.categoryId) query = query.eq("category_id", filters.categoryId);

    if (limit !== undefined) {
      query = query.range(offset, offset + limit - 1);
    }

    const { data, error } = await query;

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async countAll(
    publicOnly = true,
    filters: { query?: string; categoryId?: number } = {}
  ): Promise<number> {
    let query = this.db
      .from(this.table)
      .select("*", { count: "exact", head: true });

    if (publicOnly) {
      query = query
        .eq("status", "active")
        .gte("end_date", new Date().toISOString());
    }
    if (filters.query) query = query.ilike("name", `%${filters.query}%`);
    if (filters.categoryId) query = query.eq("category_id", filters.categoryId);

    const { count, error } = await query;
    if (error) throw error;
    return count ?? 0;
  }

  async findById(input: EventIdInput): Promise<Event | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findPublicById(input: EventIdInput): Promise<Event | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .eq("status", "active")
      .gte("end_date", new Date().toISOString())
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToEntity(data) : null;
  }

  async getByStatus(status: EventStatus): Promise<Event[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", status)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data || []).map(this.mapToEntity);
  }

  async update(
    input: EventUpdateInput & EventIdInput & {
      status?: EventStatus;
    }
  ): Promise<Event> {
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

  // Eliminación física, no se recomienda usar, mejor usar softDelete
  async delete(input: EventIdInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", input.id);

    if (error) throw error;
  }

  async softDelete(input: EventIdInput): Promise<Event> {
    const { data, error } = await this.db.rpc("cancel_event_with_refunds", { p_event_id: input.id });

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findByCategory(
    category_id: number,
    publicOnly = true
  ): Promise<Event[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .eq("category_id", category_id)
      .order("start_date", { ascending: true });

    if (publicOnly) {
      query = query
        .eq("status", "active")
        .gte("end_date", new Date().toISOString());
    }
    const { data, error } = await query;

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByCreator(user_id: string): Promise<Event[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("creator_id", user_id)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByBusiness(
    business_id: number,
    publicOnly = true
  ): Promise<Event[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .eq("business_id", business_id)
      .order("start_date", { ascending: true });

    if (publicOnly) {
      query = query
        .eq("status", "active")
        .gte("end_date", new Date().toISOString());
    }
    const { data, error } = await query;

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findUpcoming(): Promise<Event[]> {
    const now = new Date().toISOString();

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", "active")
      .gte("start_date", now)
      .order("start_date", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByIds(ids: number[], publicOnly = true): Promise<Event[]> {
    if (ids.length === 0) return [];

    let query = this.db
      .from(this.table)
      .select("*")
      .in("id", ids);

    if (publicOnly) {
      query = query
        .eq("status", "active")
        .gte("end_date", new Date().toISOString());
    }
    const { data, error } = await query;

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async exists(input: EventIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}

import { DbClient } from "../types/db-client";
import { TransportRoute } from "../dto/transport-route.dto";
import { TransportRouteCreateInput, TransportRouteUpdateInput,
  TransportRouteIdInput, TransportRouteByLineInput,
} from "../validation/transport-routes.validation";
import { buildPoint, parseLocation } from "../utils/location";

export class TransportRoutesDAO {
  private table = "transport_routes";
  constructor(private readonly db: DbClient) { }

  private mapToEntity(data: any): TransportRoute {
    const parsed = parseLocation(data.location);

    if (!parsed) {
      throw new Error("Location is required but was null from DB");
    }

    return {
      id: data.id,
      transport_line_id: data.transport_line_id,
      direction: data.direction,
      stop_order: data.stop_order,
      location: parsed,
    };
  }

  async create(input: TransportRouteCreateInput): Promise<TransportRoute> {
    const { location, ...rest } = input;

    const payload = {
      ...rest,
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

  async createBulk(inputs: TransportRouteCreateInput[]): Promise<TransportRoute[]> {
    const payload = inputs.map((input) => {
      const { location, ...rest } = input;

      return {
        ...rest,
        location: buildPoint({
          coordinates: [location.longitude, location.latitude],
        }),
      };
    });

    const { data, error } = await this.db
      .from(this.table)
      .insert(payload)
      .select("*");

    if (error) {
      console.error("DB ERROR:", error);
      throw error;
    }

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByLine(
    input: TransportRouteByLineInput
  ): Promise<TransportRoute[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("transport_line_id", input.transport_line_id)
      .order("stop_order");

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByLineAndDirection(
    transport_line_id: number,
    direction: string
  ): Promise<TransportRoute[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("transport_line_id", transport_line_id)
      .eq("direction", direction)
      .order("stop_order");

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findById(input: TransportRouteIdInput): Promise<TransportRoute | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findByLines(
    lineIds: number[],
    direction?: string
  ): Promise<Record<string, TransportRoute[]>> {
    const uniqueIds = [...new Set(lineIds)];

    let query = this.db
      .from(this.table)
      .select("*")
      .in("transport_line_id", uniqueIds)
      .order("transport_line_id")
      .order("direction")
      .order("stop_order");

    if (direction) {
      query = query.eq("direction", direction);
    }

    const { data, error } = await query;

    if (error) throw error;

    const result: Record<string, TransportRoute[]> = {};

    for (const row of data ?? []) {
      const mapped = this.mapToEntity(row);
      const key = String(mapped.transport_line_id);

      if (!result[key]) {
        result[key] = [];
      }

      result[key].push(mapped);
    }

    return result;
  }

  async update(input: TransportRouteUpdateInput): Promise<TransportRoute> {
    const { id, location, ...rest } = input;

    const payload: any = {
      ...rest,
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

  async delete(input: TransportRouteIdInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", input.id);

    if (error) throw error;
  }

  async syncLineStatusByRouteCount(transportLineId: number): Promise<void> {
    const { count, error: countError } = await this.db
      .from(this.table)
      .select("id", { count: "exact", head: true })
      .eq("transport_line_id", transportLineId);

    if (countError) throw countError;

    const nextStatus = (count ?? 0) >= 2 ? "active" : "inactive";

    const { error } = await this.db
      .from("transport_lines")
      .update({
        status: nextStatus,
        updated_at: new Date().toISOString(),
      })
      .eq("id", transportLineId)
      .neq("status", "archived");

    if (error) throw error;
  }

  async exists(input: TransportRouteIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}

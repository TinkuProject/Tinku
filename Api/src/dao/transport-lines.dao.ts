import { DbClient } from "../types/db-client";
import { TransportLine } from "../dto/transport-line.dto";
import {
  TransportLineCreateInput, TransportLineUpdateInput,
  TransportLineIdInput
} from "../validation/transport-lines.validation";

export class TransportLinesDAO {
  private table = "transport_lines";
  constructor(private readonly db: DbClient) { }

  private mapToEntity(data: any): TransportLine {
    return {
      id: data.id,
      vehicle_type_id: data.vehicle_type_id,
      name: data.name,
      status: data.status,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at ? new Date(data.updated_at) : null,
    };
  }

  async create(input: TransportLineCreateInput): Promise<TransportLine> {
    const { data, error } = await this.db
      .from(this.table)
      .insert(input)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findAll(): Promise<TransportLine[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("status", ["active", "inactive"])
      .order("name");

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findActiveWithRoutes(): Promise<TransportLine[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*, transport_routes!inner(id)")
      .eq("status", "active")
      .order("name");

    if (error) throw error;

    return (data ?? [])
      .filter((i: any) => (i.transport_routes ?? []).length >= 2)
      .map((i) => this.mapToEntity(i));
  }

  async findById(input: TransportLineIdInput): Promise<TransportLine | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findByIds(ids: number[]): Promise<TransportLine[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("id", ids)
      .in("status", ["active", "inactive"])
      .order("name");

    if (error) {
      throw new Error(error.message);
    }

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async countRoutePoints(lineId: number): Promise<number> {
    const { count, error } = await this.db
      .from("transport_routes")
      .select("id", { count: "exact", head: true })
      .eq("transport_line_id", lineId);

    if (error) throw error;

    return count ?? 0;
  }

  async findByVehicleType(vehicle_type_id: number): Promise<TransportLine[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("vehicle_type_id", vehicle_type_id)
      .in("status", ["active", "inactive"]);

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async update(input: TransportLineUpdateInput): Promise<TransportLine> {
    const { id, ...updates } = input;

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

    return this.mapToEntity(data);
  }

  async softDelete(input: TransportLineIdInput): Promise<TransportLine> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "archived",
        updated_at: new Date(),
      })
      .eq("id", input.id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async exists(input: TransportLineIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}

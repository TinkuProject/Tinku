import { DbClient } from "../types/db-client";
import { ChargingPoint } from "../dto/charging-point.dto";
import { ChargingPointStatus } from "../constants/enums.constants";
import { parseLocation, buildPoint } from "../utils/location";

export class ChargingPointsDAO {
  private table = "charging_points";
  constructor(private db: DbClient) {}

  private mapToDomain(row: any): ChargingPoint {
    return {
      ...row,
      location: parseLocation(row.location),
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(data: {
    name: string;
    address: string;
    location: {
      latitude: number;
      longitude: number;
    };
    status?: ChargingPointStatus;
  }): Promise<ChargingPoint> {
    const { location, ...rest } = data;

    const { data: result, error } = await this.db
      .from(this.table)
      .insert({
        ...rest,
        status: data.status ?? "active",
        location: buildPoint({
          coordinates: [location.longitude, location.latitude],
        }),
        created_at: new Date().toISOString(),
      })
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToDomain(result);
  }

  async findAll(): Promise<ChargingPoint[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findById(id: number): Promise<ChargingPoint | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToDomain(data) : null;
  }

  async findActive(): Promise<ChargingPoint[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", "active")
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async update(
    id: number,
    data: {
      name?: string;
      address?: string;
      location?: {
        latitude: number;
        longitude: number;
      };
      status?: ChargingPointStatus;
    }
  ): Promise<ChargingPoint> {
    const { location, ...rest } = data;

    const updateData: any = {
      ...rest,
      updated_at: new Date().toISOString(),
    };

    if (location) {
      updateData.location = buildPoint({
        coordinates: [location.longitude, location.latitude],
      });
    }

    const { data: result, error } = await this.db
      .from(this.table)
      .update(updateData)
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToDomain(result);
  }

  async softDelete(id: number): Promise<ChargingPoint> {
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
}
import { DbClient } from "../types/db-client";

export class NearbyDAO {
  constructor(private db: DbClient) {}

  async findNearby(params: {
    lat: number;
    lng: number;
    radius: number;
  }): Promise<any[]> {
    const { lat, lng, radius } = params;

    const { data, error } = await this.db.rpc("get_nearby_entities", {
      user_lat: lat,
      user_lng: lng,
      radius_meters: radius,
    });

    if (error) throw error;

    return data ?? [];
  }
}
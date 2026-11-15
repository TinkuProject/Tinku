import { NearbyDAO } from "../dao/nearby.dao";
import { mapNearbyItem } from "../mappers/nearby.mapper";

export class NearbyService {
  constructor(private dao: NearbyDAO) {}

  async getNearby(input: {
    lat: number;
    lng: number;
    radius?: number;
  }) {
    const radius = input.radius ?? 5000;

    const data = await this.dao.findNearby({
      lat: input.lat,
      lng: input.lng,
      radius,
    });

    return data.map(mapNearbyItem);
  }
}
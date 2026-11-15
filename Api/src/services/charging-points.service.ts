import { ChargingPointsDAO } from "../dao/charging-points.dao";
import { ChargingPoint } from "../dto/charging-point.dto";
import { ChargingPointStatus } from "../constants/enums.constants";

export class ChargingPointsService {
  constructor(private dao: ChargingPointsDAO) {}

  async create(data: {
    name: string;
    address: string;
    location: {
      latitude: number;
      longitude: number;
    };
    status?: ChargingPointStatus;
  }): Promise<ChargingPoint> {
    return this.dao.create(data);
  }

  async getAll(): Promise<ChargingPoint[]> {
    return this.dao.findAll();
  }

  async getById(id: number): Promise<ChargingPoint> {
    const point = await this.dao.findById(id);

    if (!point) {
      throw new Error("Charging point not found");
    }

    return point;
  }

  async getActive(): Promise<ChargingPoint[]> {
    return this.dao.findActive();
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
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Charging point not found");
    }

    return this.dao.update(id, data);
  }

  async softDelete(id: number): Promise<ChargingPoint> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Charging point not found");
    }

    return this.dao.softDelete(id);
  }
}
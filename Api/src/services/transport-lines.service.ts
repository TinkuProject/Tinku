import { TransportLinesDAO } from "../dao/transport-lines.dao";
import {
  TransportLineCreateInput, TransportLineUpdateInput, TransportLineIdInput,
} from "../validation/transport-lines.validation";
import { TransportLine } from "../dto/transport-line.dto";
import { EntityTransportRelationsService } from "./entity-transport-relations.service";

export class TransportLinesService {
  constructor(
    private readonly dao: TransportLinesDAO,
    private readonly transportRelationsService: EntityTransportRelationsService
  ) { }

  async create(input: TransportLineCreateInput): Promise<TransportLine> {
    const line = await this.dao.create({
      ...input,
      status: "inactive",
    });

    await this.transportRelationsService.refreshAllNearby();

    return line;
  }

  async getAll(): Promise<TransportLine[]> {
    return this.dao.findAll();
  }

  async getActiveWithRoutes(): Promise<TransportLine[]> {
    return this.dao.findActiveWithRoutes();
  }

  async getById(input: TransportLineIdInput): Promise<TransportLine> {
    const line = await this.dao.findById(input);

    if (!line) {
      throw new Error("Transport line not found");
    }

    return line;
  }

  async getByIds(ids: number[]): Promise<TransportLine[]> {
    if (!ids.length) return [];

    const uniqueIds = [...new Set(ids)];

    return this.dao.findByIds(uniqueIds);
  }

  async getByVehicleType(vehicle_type_id: number): Promise<TransportLine[]> {
    return this.dao.findByVehicleType(vehicle_type_id);
  }

  async update(input: TransportLineUpdateInput): Promise<TransportLine> {
    const exists = await this.dao.exists({ id: input.id });

    if (!exists) {
      throw new Error("Transport line not found");
    }

    if (input.status === "active") {
      const pointCount = await this.dao.countRoutePoints(input.id);

      if (pointCount < 2) {
        throw new Error("Transport line cannot be active without route points");
      }
    }

    const line = await this.dao.update(input);

    await this.transportRelationsService.refreshAllNearby();

    return line;
  }

  async softDelete(input: TransportLineIdInput): Promise<TransportLine> {
    const exists = await this.dao.exists(input);

    if (!exists) {
      throw new Error("Transport line not found");
    }

    const line = await this.dao.softDelete(input);

    await this.transportRelationsService.refreshAllNearby();

    return line;
  }
}

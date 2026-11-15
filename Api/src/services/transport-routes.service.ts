import { TransportRoutesDAO } from "../dao/transport-routes.dao";
import { TransportRouteCreateInput, TransportRouteUpdateInput,
  TransportRouteIdInput, TransportRouteByLineInput,
} from "../validation/transport-routes.validation";
import { TransportRoute } from "../dto/transport-route.dto";
import { EntityTransportRelationsService } from "./entity-transport-relations.service";

export class TransportRoutesService {
  constructor(
    private readonly dao: TransportRoutesDAO,
    private readonly transportRelationsService: EntityTransportRelationsService
  ) { }

  async create(input: TransportRouteCreateInput): Promise<TransportRoute> {
    const route = await this.dao.create(input);

    await this.dao.syncLineStatusByRouteCount(route.transport_line_id);
    await this.transportRelationsService.refreshAllNearby();

    return route;
  }

  async createBulk(inputs: TransportRouteCreateInput[]): Promise<TransportRoute[]> {
    const routes = await this.dao.createBulk(inputs);
    const lineIds = [...new Set(routes.map((route) => route.transport_line_id))];

    for (const lineId of lineIds) {
      await this.dao.syncLineStatusByRouteCount(lineId);
    }

    await this.transportRelationsService.refreshAllNearby();

    return routes;
  }

  async getByLine(
    input: TransportRouteByLineInput
  ): Promise<TransportRoute[]> {
    return this.dao.findByLine(input);
  }

  async getByLineAndDirection(
    transport_line_id: number,
    direction: string
  ): Promise<TransportRoute[]> {
    return this.dao.findByLineAndDirection(
      transport_line_id,
      direction
    );
  }

  async getByLines(
    lineIds: number[],
    direction?: string
  ): Promise<Record<string, TransportRoute[]>> {
    return this.dao.findByLines(lineIds, direction);
  }

  async update(input: TransportRouteUpdateInput): Promise<TransportRoute> {
    const exists = await this.dao.exists({ id: input.id });

    if (!exists) {
      throw new Error("Transport route not found");
    }

    const route = await this.dao.update(input);

    await this.transportRelationsService.refreshAllNearby();

    return route;
  }

  async delete(input: TransportRouteIdInput): Promise<void> {
    const route = await this.dao.findById(input);

    if (!route) {
      throw new Error("Transport route not found");
    }

    await this.dao.delete(input);
    await this.dao.syncLineStatusByRouteCount(route.transport_line_id);
    await this.transportRelationsService.refreshAllNearby();
  }
}

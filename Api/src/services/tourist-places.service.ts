import { TouristPlacesDAO } from "../dao/tourist-places.dao";
import { TouristPlaceCreateInput, TouristPlaceUpdateInput, TouristPlaceIdInput,
  TouristPlaceCategoryInput } from "../validation/tourist-places.validation";
import { TouristPlace } from "../dto/tourist-place.dto";
import { EntityTransportRelationsService } from "./entity-transport-relations.service";

type Actor = {
  id: string;
  role?: string;
};

export class TouristPlacesService {
  constructor(
    private readonly dao: TouristPlacesDAO,
    private readonly transportRelationsService: EntityTransportRelationsService
  ) {}

  private async refreshTransportRelations(place: TouristPlace, radiusMeters = 1000) {
    await this.transportRelationsService.refreshNearby({
      entityType: "tourist_place",
      entityId: place.id,
      latitude: place.location.latitude,
      longitude: place.location.longitude,
      radiusMeters,
    });
  }

  async create(input: TouristPlaceCreateInput, actor?: Actor): Promise<TouristPlace> {
    const place = await this.dao.create(input, actor?.id);

    await this.refreshTransportRelations(place);

    return place;
  }

  async getAll(): Promise<TouristPlace[]> {
    return this.dao.findAll();
  }

  async getMine(userId: string, limit?: number, offset = 0): Promise<TouristPlace[]> {
    return this.dao.findMine(userId, limit, offset);
  }

  async getById(input: TouristPlaceIdInput): Promise<TouristPlace> {
    const place = await this.dao.findById(input);

    if (!place) {
      throw new Error("Tourist place not found");
    }

    return place;
  }

  async getByIds(ids: number[]): Promise<TouristPlace[]> {
    return this.dao.findByIds(ids);
  }

  async getByCategory(
    input: TouristPlaceCategoryInput
  ): Promise<TouristPlace[]> {
    return this.dao.findByCategory(input);
  }

  async update(input: TouristPlaceUpdateInput): Promise<TouristPlace> {
    const exists = await this.dao.exists({ id: input.id });

    if (!exists) {
      throw new Error("Tourist place not found");
    }

    const updated = await this.dao.update(input);

    if (input.location) {
      await this.refreshTransportRelations(updated);
    }

    return updated;
  }

  async softDelete(input: TouristPlaceIdInput): Promise<TouristPlace> {
    const exists = await this.dao.exists(input);

    if (!exists) {
      throw new Error("Tourist place not found");
    }

    return this.dao.softDelete(input);
  }
}

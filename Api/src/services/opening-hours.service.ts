import { OpeningHoursDAO } from "../dao/opening-hours.dao";
import { OpeningHour } from "../dto/opening-hour.dto";
import { CreateOpeningHourInput, UpdateOpeningHourInput,
} from "../validation/opening-hours.validation";
import { OpeningEntity } from "../constants/enums.constants";

export class OpeningHoursService {
  constructor(private dao: OpeningHoursDAO) {}

  async create(data: CreateOpeningHourInput): Promise<OpeningHour> {
    return this.dao.create(data);
  }

  getByEntity(
    entityType: OpeningEntity,
    entityId: number
  ): Promise<OpeningHour[]> {
    return this.dao.getByEntity(entityType, entityId);
  }

  getByEntities(
    entityType: OpeningEntity,
    entityIds: number[]
  ): Promise<Record<string, OpeningHour[]>> {
    return this.dao.getByEntities(entityType, entityIds);
  }

  async getById(id: number): Promise<OpeningHour> {
    const opening = await this.dao.getById(id);

    if (!opening) {
      throw new Error("Opening hour not found");
    }

    return opening;
  }

  async update(
    id: number,
    data: UpdateOpeningHourInput
  ): Promise<OpeningHour> {
    const existing = await this.dao.getById(id);

    if (!existing) {
      throw new Error("Opening hour not found");
    }

    return this.dao.update(id, data);
  }

  delete(id: number): Promise<void> {
    return this.dao.delete(id);
  }

  deleteByEntity(
    entityType: OpeningEntity,
    entityId: number
  ): Promise<void> {
    return this.dao.deleteByEntity(entityType, entityId);
  }

  async replaceAll(
    entityType: OpeningEntity,
    entityId: number,
    items: CreateOpeningHourInput[]
  ): Promise<OpeningHour[]> {
    // validación mínima: todos deben coincidir
    for (const item of items) {
      if (
        item.entity_type !== entityType ||
        item.entity_id !== entityId
      ) {
        throw new Error("Invalid entity data in payload");
      }
    }

    return this.dao.replaceAll(entityType, entityId, items);
  }
}

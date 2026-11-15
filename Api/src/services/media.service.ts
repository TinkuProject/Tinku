import { MediaDAO } from "../dao/media.dao";
import { Media } from "../dto/media.dto";
import { MediaCreateInput, MediaUpdateInput } from "../validation/media.validation";
import { MediaEntityType } from "../constants/enums.constants";

export class MediaService {
  constructor(private dao: MediaDAO) {}

  async create(data: MediaCreateInput): Promise<Media> {
    // si es primary → limpiar anteriores
    if (data.is_primary) {
      await this.clearPrimary(data.entity_id, data.entity_type);
    }

    return this.dao.create(data);
  }

  getAll(): Promise<Media[]> {
    return this.dao.getAll();
  }

  async getById(id: number): Promise<Media> {
    const media = await this.dao.getById(id);

    if (!media) {
      throw new Error("Media not found");
    }

    return media;
  }

  async getByUrl(url: string): Promise<Media> {
    const media = await this.dao.getByUrl(url);

    if (!media) {
      throw new Error("Media not found");
    }

    return media;
  }

  async update(id: number, data: MediaUpdateInput): Promise<Media> {
    const existing = await this.dao.getById(id);

    if (!existing) {
      throw new Error("Media not found");
    }

    // si cambia a primary → limpiar anteriores
    if (data.is_primary === true) {
      await this.clearPrimary(existing.entity_id, existing.entity_type);
    }

    return this.dao.update(id, data);
  }

  delete(id: number): Promise<void> {
    return this.dao.delete(id);
  }

  getByEntity(
    entityId: string | number,
    entityType: MediaEntityType
  ): Promise<Media[]> {
    return this.dao.getByEntity(entityId, entityType);
  }

  async getByEntities(
    entityIds: string[],
    entityType: MediaEntityType
  ): Promise<Record<string, Media[]>> {
    return this.dao.getByEntities(entityIds, entityType);
  }

  getPrimaryByEntity(
    entityId: string | number,
    entityType: MediaEntityType
  ): Promise<Media | null> {
    return this.dao.getPrimaryByEntity(entityId, entityType);
  }

  deleteAllByEntity(
    entityId: string | number,
    entityType: MediaEntityType
  ): Promise<void> {
    return this.dao.deleteAllByEntity(entityId, entityType);
  }

  deleteByUrl(url: string): Promise<void> {
    return this.dao.deleteByUrl(url);
  }

  private async clearPrimary(
    entityId: string | number,
    entityType: MediaEntityType
  ): Promise<void> {
    const current = await this.dao.getPrimaryByEntity(
      entityId,
      entityType
    );

    if (current) {
      await this.dao.update(current.id, { is_primary: false });
    }
  }
}

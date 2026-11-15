import { TouristPlaceTagsDAO } from "../dao/tourist-place-tags.dao";
import { TouristPlaceTagInput, TouristPlaceIdInput, TagIdInput,
} from "../validation/tourist-place-tags.validation";
import { TouristPlaceTag } from "../dto/tourist-place-tag.dto";

export class TouristPlaceTagsService {
  constructor(private readonly dao: TouristPlaceTagsDAO) {}

  async create(input: TouristPlaceTagInput): Promise<TouristPlaceTag> {
    const exists = await this.dao.exists(input);
    if (exists) {
      throw new Error("Tag already assigned to tourist place");
    }

    return this.dao.create(input);
  }

  async getByPlace(input: TouristPlaceIdInput): Promise<any[]> {
    const rows = await this.dao.findByPlace(input);

    return rows.map(r => r.tag);
  }

  async getByTag(input: TagIdInput): Promise<TouristPlaceTag[]> {
    return this.dao.findByTag(input);
  }

  async delete(input: TouristPlaceTagInput): Promise<void> {
    const exists = await this.dao.exists(input);
    if (!exists) {
      throw new Error("Relation not found");
    }

    await this.dao.delete(input);
  }

  async replaceTags(
    place: TouristPlaceIdInput,
    tagIds: number[]
  ): Promise<TouristPlaceTag[]> {
    // limpia todo primero
    await this.dao.deleteByPlace(place);

    // evita duplicados en el payload
    const uniqueTagIds = [...new Set(tagIds)];

    const results = await Promise.all(
      uniqueTagIds.map((tag_id) =>
        this.dao.create({
          tourist_place_id: place.tourist_place_id,
          tag_id,
        })
      )
    );

    return results;
  }
}
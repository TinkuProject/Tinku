import { DbClient } from "../types/db-client";
import { TouristPlaceTag } from "../dto/tourist-place-tag.dto";
import { TouristPlaceTagInput, TouristPlaceIdInput, TagIdInput,
} from "../validation/tourist-place-tags.validation";

export class TouristPlaceTagsDAO {
  private table = "tourist_place_tags";
  constructor(private readonly db: DbClient) {}

  async create(input: TouristPlaceTagInput): Promise<TouristPlaceTag> {
    const { data, error } = await this.db
      .from(this.table)
      .insert(input)
      .select()
      .single();

    if (error) throw error;

    return data as TouristPlaceTag;
  }

  async findByPlace(input: TouristPlaceIdInput): Promise<any[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select(`
        tag:tags (
          id,
          name,
          description,
          status,
          created_at,
          updated_at
        )
      `)
      .eq("tourist_place_id", input.tourist_place_id);

    if (error) throw error;

    return data ?? [];
  }

  async findByTag(input: TagIdInput): Promise<TouristPlaceTag[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("tag_id", input.tag_id);

    if (error) throw error;

    return data ?? [];
  }

  async delete(input: TouristPlaceTagInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("tourist_place_id", input.tourist_place_id)
      .eq("tag_id", input.tag_id);

    if (error) throw error;
  }

  async deleteByPlace(input: TouristPlaceIdInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("tourist_place_id", input.tourist_place_id);

    if (error) throw error;
  }

  async exists(input: TouristPlaceTagInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("tourist_place_id", input.tourist_place_id)
      .eq("tag_id", input.tag_id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}
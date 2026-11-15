import { DbClient } from "../types/db-client";
import { Media } from "../dto/media.dto";
import { MediaCreateInput, MediaUpdateInput } from "../validation/media.validation";
import { MediaEntityType } from "../constants/enums.constants";

export class MediaDAO {
  private table = "media";
  constructor(private db: DbClient) { }

  private mapToDomain(row: any): Media {
    if (!row) return row;

    return {
      ...row,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(entry: MediaCreateInput): Promise<Media> {
    const { data, error } = await this.db
      .from(this.table)
      .insert(entry)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(data);
  }

  async getAll(): Promise<Media[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data || []).map((row) => this.mapToDomain(row));
  }

  async getById(id: number): Promise<Media | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async getByUrl(url: string): Promise<Media | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("url", url)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async getByEntities(
    entityIds: string[],
    entityType: MediaEntityType
  ): Promise<Record<string, Media[]>> {

    const parsedIds = entityType === "user"
      ? entityIds
      : entityIds.map((id) => Number(id));

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("entity_id", parsedIds)
      .eq("entity_type", entityType)
      .order("created_at", { ascending: true });

    if (error) throw error;

    const result: Record<string, Media[]> = {};

    for (const row of data || []) {
      const mapped = this.mapToDomain(row);
      const key = String(mapped.entity_id);

      if (!result[key]) {
        result[key] = [];
      }

      result[key].push(mapped);
    }

    return result;
  }

  async update(id: number, updates: MediaUpdateInput): Promise<Media> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        ...updates,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(data);
  }

  async getByEntity(
    entityId: string | number,
    entityType: MediaEntityType
  ): Promise<Media[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("entity_id", entityId)
      .eq("entity_type", entityType)
      .order("created_at", { ascending: true })

    if (error) throw error;
    return (data || []).map((row) => this.mapToDomain(row));
  }

  async getPrimaryByEntity(
    entityId: string | number,
    entityType: MediaEntityType
  ): Promise<Media | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("entity_id", entityId)
      .eq("entity_type", entityType)
      .eq("is_primary", true)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async delete(id: number): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", id);

    if (error) throw error;
  }

  async deleteAllByEntity(
    entityId: string | number,
    entityType: MediaEntityType
  ): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("entity_id", entityId)
      .eq("entity_type", entityType);

    if (error) throw error;
  }

  async deleteByUrl(url: string): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("url", url);

    if (error) throw error;
  }
}

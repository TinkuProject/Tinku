import { DbClient } from "../types/db-client";
import { OpeningHour } from "../dto/opening-hour.dto";
import { CreateOpeningHourInput, UpdateOpeningHourInput,
} from "../validation/opening-hours.validation";
import { OpeningEntity } from "../constants/enums.constants";

export class OpeningHoursDAO {
  private table = "opening_hours";
  constructor(private db: DbClient) {}

  private mapToDomain(row: any): OpeningHour {
    if (!row) return row;

    return {
      ...row,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(data: CreateOpeningHourInput): Promise<OpeningHour> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(result);
  }

  async getByEntity(
    entityType: OpeningEntity,
    entityId: number
  ): Promise<OpeningHour[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("entity_type", entityType)
      .eq("entity_id", entityId)
      .order("week_day")
      .order("start_time");

    if (error) throw error;

    return (data || []).map((row) => this.mapToDomain(row));
  }

  async getByEntities(
    entityType: OpeningEntity,
    entityIds: number[]
  ): Promise<Record<string, OpeningHour[]>> {
    const uniqueIds = [...new Set(entityIds)];

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("entity_type", entityType)
      .in("entity_id", uniqueIds)
      .order("entity_id")
      .order("week_day")
      .order("start_time");

    if (error) throw error;

    const result: Record<string, OpeningHour[]> = {};

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

  async getById(id: number): Promise<OpeningHour | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async update(
    id: number,
    updates: UpdateOpeningHourInput
  ): Promise<OpeningHour> {
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

  async delete(id: number): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", id);

    if (error) throw error;
  }

  async deleteByEntity(
    entityType: OpeningEntity,
    entityId: number
  ): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("entity_type", entityType)
      .eq("entity_id", entityId);

    if (error) throw error;
  }

  async replaceAll(
    entityType: OpeningEntity,
    entityId: number,
    items: CreateOpeningHourInput[]
  ): Promise<OpeningHour[]> {
    // borrar todo
    await this.deleteByEntity(entityType, entityId);

    if (items.length === 0) return [];

    const payload = items.map((item) => ({
      ...item,
      entity_type: entityType,
      entity_id: entityId,
    }));

    const { data, error } = await this.db
      .from(this.table)
      .insert(payload)
      .select();

    if (error) throw error;

    return (data || []).map((row) => this.mapToDomain(row));
  }
}

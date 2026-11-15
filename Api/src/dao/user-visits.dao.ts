import { DbClient } from "../types/db-client";
import { UserVisit } from "../dto/user-visit.dto";
import { UserVisitCreateInput, UserVisitByUserInput, UserVisitByEntityInput,
} from "../validation/user-visits.validation";

export class UserVisitsDAO {
  private table = "user_visits";
  constructor(private readonly db: DbClient) {}

  private mapToEntity(data: any): UserVisit {
    return {
      id: data.id,
      user_id: data.user_id,
      entity_type: data.entity_type,
      entity_id: data.entity_id,
      type: data.type,
      created_at: new Date(data.created_at),
    };
  }

  async create(
    user_id: string,
    input: UserVisitCreateInput
  ): Promise<UserVisit> {
    const payload = {
      ...input,
      user_id,
    };

    const { data, error } = await this.db
      .from(this.table)
      .insert(payload)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findByUser(
    input: UserVisitByUserInput
  ): Promise<UserVisit[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", input.user_id)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByEntity(
    user_id: string,
    input: UserVisitByEntityInput
  ): Promise<UserVisit[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", user_id)
      .eq("entity_type", input.entity_type)
      .eq("entity_id", input.entity_id);

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async countByEntities(
    entity_type: string,
    entity_ids: number[],
    type: string
  ): Promise<Record<number, number>> {
    const cleanIds = entity_ids.filter((id) => Number.isInteger(id) && id > 0);
    const result: Record<number, number> = {};

    cleanIds.forEach((id) => {
      result[id] = 0;
    });

    if (cleanIds.length === 0) return result;

    const { data, error } = await this.db
      .from(this.table)
      .select("entity_id")
      .eq("entity_type", entity_type)
      .eq("type", type)
      .in("entity_id", cleanIds);

    if (error) throw error;

    for (const row of data ?? []) {
      const entityId = Number(row.entity_id);
      if (Number.isInteger(entityId)) {
        result[entityId] = (result[entityId] ?? 0) + 1;
      }
    }

    return result;
  }

  async delete(
    user_id: string,
    entity_type: string,
    entity_id: number
  ): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("user_id", user_id)
      .eq("entity_type", entity_type)
      .eq("entity_id", entity_id);

    if (error) throw error;
  }

  async exists(
    user_id: string,
    entity_type: string,
    entity_id: number,
    type: string
  ): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("user_id", user_id)
      .eq("entity_type", entity_type)
      .eq("entity_id", entity_id)
      .eq("type", type)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}

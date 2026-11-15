import { DbClient } from "../types/db-client";
import { EntityTransportRelation } from "../dto/entity-transport-relation.dto";
import { VisitEntity } from "../constants/enums.constants";
import { EntityTransportRelationCreateInput } from "../validation/entity-transport-relations.validation";

export class EntityTransportRelationsDAO {
  private table = "entity_transport_relations";
  constructor(private db: DbClient) { }

  async create(
    data: EntityTransportRelationCreateInput
  ): Promise<EntityTransportRelation> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return result as EntityTransportRelation;
  }

  async getByEntity(
    entityType: VisitEntity,
    entityId: number
  ): Promise<EntityTransportRelation[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("entity_type", entityType)
      .eq("entity_id", entityId);

    if (error) throw error;
    return data as EntityTransportRelation[];
  }

  async getByEntities(
    entityType: VisitEntity,
    entityIds: number[]
  ): Promise<Record<string, EntityTransportRelation[]>> {
    const uniqueIds = [...new Set(entityIds)];

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("entity_type", entityType)
      .in("entity_id", uniqueIds);

    if (error) throw error;

    const result: Record<string, EntityTransportRelation[]> = {};

    for (const row of data || []) {
      const item = row as EntityTransportRelation;
      const key = String(item.entity_id);

      if (!result[key]) {
        result[key] = [];
      }

      result[key].push(item);
    }

    return result;
  }

  async delete(
    entityType: VisitEntity,
    entityId: number,
    transportLineId: number
  ): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("entity_type", entityType)
      .eq("entity_id", entityId)
      .eq("transport_line_id", transportLineId);

    if (error) throw error;
  }

  async deleteByEntity(
    entityType: VisitEntity,
    entityId: number
  ): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("entity_type", entityType)
      .eq("entity_id", entityId);

    if (error) throw error;
  }

  async replace(
    entityType: VisitEntity,
    entityId: number,
    newLineIds: number[]
  ): Promise<void> {
    // 1. delete existing
    const { error: deleteError } = await this.db
      .from(this.table)
      .delete()
      .eq("entity_type", entityType)
      .eq("entity_id", entityId);

    if (deleteError) throw deleteError;

    // 2. insert new (si hay)
    if (newLineIds.length === 0) return;

    const payload = newLineIds.map((lineId) => ({
      entity_type: entityType,
      entity_id: entityId,
      transport_line_id: lineId,
    }));

    const { error: insertError } = await this.db
      .from(this.table)
      .insert(payload);

    if (insertError) throw insertError;
  }

  async refreshNearby(
    input: {
      entityType: VisitEntity;
      entityId: number;
      latitude: number;
      longitude: number;
      radiusMeters?: number;
    }
  ): Promise<number> {
    const { data, error } = await this.db.rpc(
      "refresh_entity_transport_relations",
      {
        p_entity_type: input.entityType,
        p_entity_id: input.entityId,
        p_lat: input.latitude,
        p_lng: input.longitude,
        p_radius_m: input.radiusMeters ?? 1000,
      }
    );

    if (error) throw error;

    return Number(data ?? 0);
  }

  async refreshAllNearby(radiusMeters = 1000): Promise<number> {
    const { data, error } = await this.db.rpc(
      "refresh_all_entity_transport_relations",
      {
        p_radius_m: radiusMeters,
      }
    );

    if (error) throw error;

    return Number(data ?? 0);
  }
}

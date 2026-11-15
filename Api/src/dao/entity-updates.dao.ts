import { DbClient } from "../types/db-client";
import { ApprovalStatus, UpdateEntityType } from "../constants/enums.constants";
import {
  CreateEntityUpdateInput,
} from "../validation/entity-updates.validation";

export interface EntityUpdate {
  id: number;
  entity_type: UpdateEntityType;
  entity_id: number;
  creator_id: string;
  data: Record<string, any>;
  status: ApprovalStatus;
  comment?: string | null;
  reviewed_by?: string | null;
  reviewed_at?: Date | null;
  created_at: Date;
}

export class EntityUpdatesDAO {
  private table = "entity_updates";

  constructor(private readonly db: DbClient) {}

  // =========================
  // MAPPER
  // =========================
  private mapToEntity(data: any): EntityUpdate {
    return {
      id: data.id,
      entity_type: data.entity_type,
      entity_id: data.entity_id,
      creator_id: data.creator_id,
      data: data.data,
      status: data.status as ApprovalStatus,
      comment: data.comment ?? null,
      reviewed_by: data.reviewed_by ?? null,
      reviewed_at: data.reviewed_at
        ? new Date(data.reviewed_at)
        : null,
      created_at: new Date(data.created_at),
    };
  }

  // =========================
  // CREATE
  // =========================
  async create(
    input: CreateEntityUpdateInput & { creator_id: string }
  ): Promise<EntityUpdate> {
    const { data, error } = await this.db
      .from(this.table)
      .insert({
        entity_type: input.entity_type,
        entity_id: input.entity_id,
        creator_id: input.creator_id,
        data: input.data,
        status: "pending",
      })
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  // =========================
  // FIND ALL (ADMIN)
  // =========================
  async findAll(): Promise<EntityUpdate[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  // =========================
  // FIND BY STATUS
  // =========================
  async findByStatus(status: ApprovalStatus): Promise<EntityUpdate[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", status)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  // =========================
  // FIND BY ID
  // =========================
  async findById(id: number): Promise<EntityUpdate | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  // =========================
  // FIND BY ENTITY
  // =========================
  async findByEntity(
    entity_type: UpdateEntityType,
    entity_id: number
  ): Promise<EntityUpdate[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("entity_type", entity_type)
      .eq("entity_id", entity_id)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  // =========================
  // FIND BY CREATOR
  // =========================
  async findByCreator(user_id: string): Promise<EntityUpdate[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("creator_id", user_id)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  // =========================
  // UPDATE STATUS (ADMIN)
  // =========================
  async updateStatus({
    id,
    status,
    comment,
    reviewed_by,
  }: {
    id: number;
    status: ApprovalStatus;
    comment?: string;
    reviewed_by: string;
  }): Promise<EntityUpdate> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status,
        comment: comment ?? null,
        reviewed_by,
        reviewed_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  // =========================
  // EXISTS
  // =========================
  async exists(id: number): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}
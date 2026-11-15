import { DbClient } from "../types/db-client";
import { Boost } from "../dto/boost.dto";
import { BoostCreateInput, BoostUpdateInput } from "../validation/boosts.validation";
import { PROMOTION_STATUS, VisitEntity } from "../constants/enums.constants";
import { dbPool } from "../config/database.config";
import { Actor, assertOwnershipAccess, isPrivileged } from "../helper/role.helper";
import { AppError } from "../utils/AppError";

export class BoostsDAO {
  private table = "boosts";
  constructor(private db: DbClient) {}

  private mapToDomain(row: any): Boost {
    const endDate = new Date(row.end_date);
    const status =
      row.status === "active" && endDate.getTime() < Date.now()
        ? "inactive"
        : row.status;

    return {
      ...row,
      start_date: new Date(row.start_date),
      end_date: endDate,
      status,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(data: BoostCreateInput): Promise<Boost> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert(data)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToDomain(result);
  }

  async createWithCharge(data: BoostCreateInput, userId: string) {
    const { data: result, error } = await this.db.rpc(
      "create_boost_with_charge",
      {
        p_user_id: userId,
        p_entity_type: data.entity_type,
        p_entity_id: data.entity_id,
        p_start_date: data.start_date,
        p_end_date: data.end_date,
      }
    );

    if (error) throw error;

    return this.mapToDomain(result);
  }

  async canPromoteBusiness(businessId: number, userId?: string): Promise<boolean> {
    let query = this.db
      .from("businesses")
      .select("id")
      .eq("id", businessId)
      .eq("validated", true)
      .eq("status", "active");

    if (userId) {
      query = query.eq("owner_id", userId);
    }

    const { data, error } = await query.maybeSingle();

    if (error) throw error;

    return !!data;
  }

  async findAll(limit = 50, offset = 0): Promise<Boost[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findMineByBusinessIds(
    businessIds: number[],
    limit = 50,
    offset = 0
  ): Promise<Boost[]> {
    if (businessIds.length === 0) return [];

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("entity_type", "business")
      .in("entity_id", businessIds)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findById(id: number): Promise<Boost | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToDomain(data) : null;
  }

  async findActive(): Promise<Boost[]> {
    const now = new Date().toISOString();

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", "active")
      .lte("start_date", now)
      .gte("end_date", now)
      .order("start_date", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findByEntity(
    entityType: VisitEntity,
    entityId: number,
    limit = 50,
    offset = 0
  ): Promise<Boost[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("entity_type", entityType)
      .eq("entity_id", entityId)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async update(id: number, updates: BoostUpdateInput): Promise<Boost> {
    const { status, ...safeUpdates } = updates;

    const allowedStatus = status && PROMOTION_STATUS.includes(status as any)
      ? status
      : undefined;

    const { data, error } = await this.db
      .from(this.table)
      .update({
        ...safeUpdates,
        ...(allowedStatus ? { status: allowedStatus } : {}),
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToDomain(data);
  }

  async updateWithCharge(id: number, updates: BoostUpdateInput, actor: Actor): Promise<Boost> {
    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");
      const current = await client.query("SELECT * FROM boosts WHERE id = $1 FOR UPDATE", [id]);
      const boost = current.rows[0];
      if (!boost) throw new Error("Boost not found");
      const table = { business: ["businesses", "owner_id"], event: ["events", "creator_id"], tourist_place: ["tourist_places", "created_by"] }[boost.entity_type as VisitEntity]!;
      const owner = await client.query(`SELECT ${table[1]} AS owner_id FROM ${table[0]} WHERE id = $1`, [boost.entity_id]);
      assertOwnershipAccess(owner.rows[0]?.owner_id, actor, "Boost target not found");
      if ((updates.entity_type !== undefined && updates.entity_type !== boost.entity_type) ||
          (updates.entity_id !== undefined && updates.entity_id !== boost.entity_id) ||
          (updates.start_date !== undefined && new Date(updates.start_date).getTime() !== new Date(boost.start_date).getTime())) {
        throw new AppError("Boost target and start date cannot be changed", 409);
      }
      if (boost.status === "cancelled") throw new AppError("Boost already cancelled", 409);
      const end = updates.end_date ?? new Date(boost.end_date).toISOString();
      if (new Date(end).getTime() < Date.now() || new Date(end) < new Date(boost.start_date)) {
        throw new AppError("La fecha y hora de fin no puede estar en el pasado", 400);
      }
      const days = await client.query(
        `SELECT GREATEST(1, ($2::timestamp::date - $1::timestamp::date) + 1) AS total,
                GREATEST(1, (end_date::date - start_date::date) + 1) AS previous
         FROM boosts WHERE id = $3`, [boost.start_date, end, id]
      );
      const paidDays = boost.paid_days ?? days.rows[0].previous;
      const additionalDays = Math.max(days.rows[0].total - paidDays, 0);
      if (additionalDays > 0 && !isPrivileged(actor.role)) {
        const config = await client.query("SELECT value::numeric AS value FROM system_config WHERE key = 'boost_create_cost'");
        if (!config.rows[0]) throw new Error("Boost cost not configured");
        const cost = additionalDays * Number(config.rows[0].value);
        if (cost > 0) await client.query("SELECT perform_tinku_spend($1, $2, 'boost_update', $3, 'Extension de impulso')", [actor.id, cost, id]);
      }
      const result = await client.query(
        `UPDATE boosts SET end_date = $2, status = COALESCE($3::promotion_status, status), paid_days = $4
         WHERE id = $1 RETURNING *`, [id, end, updates.status ?? null, Math.max(paidDays, days.rows[0].total)]
      );
      await client.query("SELECT write_audit_log($1, 'boost_updated', 'boost', $2, jsonb_build_object('additional_days', $3::int))", [actor.id, id, additionalDays]);
      await client.query("COMMIT");
      return this.mapToDomain(result.rows[0]);
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined); throw error;
    } finally { client.release(); }
  }

  async softDelete(id: number): Promise<Boost> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "cancelled",
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .neq("status", "cancelled")
      .select("*")
      .maybeSingle();

    if (error) throw error;

    if (!data) {
      throw new Error("Boost not found or already cancelled");
    }

    return this.mapToDomain(data);
  }
}

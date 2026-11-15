import { query } from "../config/database.config";
import { BasicStatus } from "../constants/enums.constants";
import { Certification } from "../dto/certification.dto";
import { DbClient } from "../types/db-client";
import {
  CertificationCreateInput,
  CertificationUpdateInput,
} from "../validation/certifications.validation";

export class CertificationsDAO {
  private table = "certifications";

  constructor(private db: DbClient) {}

  private mapToDomain(row: any): Certification {
    return {
      ...row,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(data: CertificationCreateInput): Promise<Certification> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert({
        ...data,
        status: "active",
        created_at: new Date().toISOString(),
      })
      .select("*")
      .single();

    if (error) throw error;
    return this.mapToDomain(result);
  }

  async findAll(): Promise<Certification[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findAllPublic(): Promise<Certification[]> {
    const result = await query(
      `SELECT c.*
       FROM certifications c
       JOIN businesses b ON b.id = c.business_id
       WHERE c.status = 'active'
         AND b.status = 'active'
         AND b.validated = true
       ORDER BY c.created_at DESC`
    );

    return result.rows.map((row) => this.mapToDomain(row));
  }

  async findById(id: number): Promise<Certification | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async findPublicById(id: number): Promise<Certification | null> {
    const result = await query(
      `SELECT c.*
       FROM certifications c
       JOIN businesses b ON b.id = c.business_id
       WHERE c.id = $1
         AND c.status = 'active'
         AND b.status = 'active'
         AND b.validated = true
       LIMIT 1`,
      [id]
    );

    const row = result.rows[0];
    return row ? this.mapToDomain(row) : null;
  }

  async findByBusinessId(businessId: number): Promise<Certification[]> {
    const result = await query(
      `SELECT c.*
       FROM certifications c
       JOIN businesses b ON b.id = c.business_id
       WHERE c.business_id = $1
         AND c.status = 'active'
         AND b.status = 'active'
         AND b.validated = true
       ORDER BY c.created_at DESC`,
      [businessId]
    );

    return result.rows.map((row) => this.mapToDomain(row));
  }

  async findByBusinessIdAdmin(businessId: number): Promise<Certification[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("business_id", businessId)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findByBusinessIds(
    businessIds: number[]
  ): Promise<Record<string, Certification[]>> {
    if (businessIds.length === 0) return {};

    const result = await query(
      `SELECT c.*
       FROM certifications c
       JOIN businesses b ON b.id = c.business_id
       WHERE c.business_id = ANY($1::bigint[])
         AND c.status = 'active'
         AND b.status = 'active'
         AND b.validated = true
       ORDER BY c.created_at DESC`,
      [businessIds]
    );

    return this.groupByBusiness(result.rows);
  }

  async findByBusinessIdsAdmin(
    businessIds: number[]
  ): Promise<Record<string, Certification[]>> {
    if (businessIds.length === 0) return {};

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("business_id", businessIds)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return this.groupByBusiness(data ?? []);
  }

  private groupByBusiness(rows: any[]): Record<string, Certification[]> {
    const result: Record<string, Certification[]> = {};

    for (const row of rows) {
      const mapped = this.mapToDomain(row);
      (result[String(mapped.business_id)] ??= []).push(mapped);
    }

    return result;
  }

  async update(
    id: number,
    updates: CertificationUpdateInput
  ): Promise<Certification> {
    const { data, error } = await this.db
      .from(this.table)
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;
    return this.mapToDomain(data);
  }

  async softDelete(id: number): Promise<Certification> {
    return this.update(id, { status: "archived" });
  }

  async deactivate(id: number): Promise<Certification> {
    return this.update(id, { status: "inactive" });
  }

  async activate(id: number): Promise<Certification> {
    return this.update(id, { status: "active" });
  }

  async findByFilters(params: {
    business_id?: number;
    status?: BasicStatus;
  }): Promise<Certification[]> {
    let dbQuery = this.db.from(this.table).select("*");

    if (params.business_id) {
      dbQuery = dbQuery.eq("business_id", params.business_id);
    }
    if (params.status) {
      dbQuery = dbQuery.eq("status", params.status);
    }

    const { data, error } = await dbQuery.order("created_at", {
      ascending: false,
    });

    if (error) throw error;
    return (data ?? []).map((row) => this.mapToDomain(row));
  }
}

import { DbClient } from "../types/db-client";
import { dbPool } from "../config/database.config";
import { BusinessClaimRequest } from "../dto/business-claim-request.dto";
import { CreateBusinessClaimRequestInput, ReviewBusinessClaimRequestInput,
} from "../validation/business-claim-requests.validation";

export class BusinessClaimRequestsDAO {
  private table = "business_claim_requests";
  constructor(private db: DbClient) { }

  private mapToDomain(row: any): BusinessClaimRequest {
    return {
      ...row,
      documents: row.documents ?? [],
      business: row.business ?? null,
      created_at: new Date(row.created_at),
      reviewed_at: row.reviewed_at
        ? new Date(row.reviewed_at)
        : null,
    };
  }

  async create(
    userId: string,
    data: CreateBusinessClaimRequestInput
  ): Promise<BusinessClaimRequest> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert({
        ...data,
        documents: data.documents ?? [],
        user_id: userId,
      })
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToDomain(result);
  }

  async findAll(limit = 50, offset = 0): Promise<BusinessClaimRequest[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findById(id: number): Promise<BusinessClaimRequest | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToDomain(data) : null;
  }

  async findByUser(
    userId: string,
    limit = 50,
    offset = 0
  ): Promise<BusinessClaimRequest[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*, business:businesses(*)")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findByBusiness(
    businessId: number,
    limit = 50,
    offset = 0,
    userId?: string
  ): Promise<BusinessClaimRequest[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .eq("business_id", businessId)
      .order("created_at", { ascending: false });

    if (userId) {
      query = query.eq("user_id", userId);
    }

    const { data, error } = await query.range(offset, offset + limit - 1);

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async findPending(): Promise<BusinessClaimRequest[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*, business:businesses(*)")
      .eq("status", "pending")
      .order("created_at", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapToDomain(row));
  }

  async review(
    id: number,
    reviewerId: string,
    data: ReviewBusinessClaimRequestInput
  ): Promise<BusinessClaimRequest> {
    const { data: result, error } = await this.db
      .from(this.table)
      .update({
        status: data.status,
        comment: data.comment ?? null,
        reviewed_by: reviewerId,
        reviewed_at: new Date().toISOString(),
      })
      .eq("id", id)
      .eq("status", "pending")
      .select("*")
      .maybeSingle();

    if (error) throw error;

    if (!result) {
      throw new Error("Request not found or already reviewed");
    }

    return this.mapToDomain(result);
  }

  async rejectPendingByBusinessExcept(
    businessId: number,
    exceptId: number,
    reviewerId: string,
    comment: string
  ): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .update({
        status: "rejected",
        comment,
        reviewed_by: reviewerId,
        reviewed_at: new Date().toISOString(),
      })
      .eq("business_id", businessId)
      .eq("status", "pending")
      .neq("id", exceptId);

    if (error) throw error;
  }

  async reviewAtomically(id: number, reviewerId: string, input: ReviewBusinessClaimRequestInput): Promise<BusinessClaimRequest> {
    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");
      const lookup = await client.query("SELECT business_id FROM business_claim_requests WHERE id = $1", [id]);
      if (!lookup.rows[0]) throw new Error("Request not found");
      const business = await client.query("SELECT id, name, owner_id FROM businesses WHERE id = $1 FOR UPDATE", [lookup.rows[0].business_id]);
      const request = await client.query("SELECT * FROM business_claim_requests WHERE id = $1 FOR UPDATE", [id]);
      if (request.rows[0]?.status !== "pending") throw new Error("Request already reviewed");
      if (input.status === "approved") {
        if (business.rows[0]?.owner_id) throw new Error("Business already has an owner");
        await client.query("UPDATE businesses SET owner_id = $2, validated = true, status = 'active' WHERE id = $1",
          [lookup.rows[0].business_id, request.rows[0].user_id]);
        await client.query(`UPDATE business_claim_requests SET status = 'rejected', reviewed_by = $3,
          reviewed_at = now(), comment = 'Otro reclamo fue aprobado para este negocio.'
          WHERE business_id = $1 AND id <> $2 AND status = 'pending'`, [lookup.rows[0].business_id, id, reviewerId]);
      }
      const updated = await client.query(`UPDATE business_claim_requests SET status = $2, comment = $3,
        reviewed_by = $4, reviewed_at = now() WHERE id = $1 RETURNING *`, [id, input.status, input.comment ?? null, reviewerId]);
      await client.query("COMMIT");
      return this.mapToDomain({ ...updated.rows[0], business: business.rows[0] });
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined); throw error;
    } finally { client.release(); }
  }

  async existsPending(
    userId: string,
    businessId: number
  ): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("user_id", userId)
      .eq("business_id", businessId)
      .eq("status", "pending")
      .limit(1);

    if (error) throw error;

    return (data?.length ?? 0) > 0;
  }
}

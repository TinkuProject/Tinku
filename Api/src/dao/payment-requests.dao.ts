import { DbClient } from "../types/db-client";
import { PaymentRequest } from "../dto/payment-request.dto";
import { PaymentMethod, PaymentType } from "../constants/enums.constants";

export class PaymentRequestDAO {
  private readonly table = "payment_requests";

  constructor(private readonly db: DbClient) {}

  // =========================
  // MAPPER
  // =========================
  private map(row: any): PaymentRequest {
    return {
      id: row.id,
      userId: row.user_id,
      paymentId: row.payment_id,

      type: row.type,
      targetId: row.target_id,

      status: row.status,

      comment: row.comment,
      reviewedBy: row.reviewed_by,
      reviewedAt: row.reviewed_at,

      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  // =========================
  // CREATE
  // =========================
  async create(
    userId: string,
    data: {
      paymentId: number;
      type: PaymentType;
      targetId?: number;
    }
  ): Promise<PaymentRequest> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert({
        user_id: userId,
        payment_id: data.paymentId,
        type: data.type,
        target_id: data.targetId ?? null,
      })
      .select()
      .single();

    if (error) throw error;

    return this.map(result);
  }

  // =========================
  // GET ALL
  // =========================
  async findAll(): Promise<PaymentRequest[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;

    return data.map((row) => this.map(row));
  }

  // =========================
  // FILTER BY STATUS
  // =========================
  async findAllByStatus(
    status: "pending" | "approved" | "rejected"
  ): Promise<PaymentRequest[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", status)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return data.map((row) => this.map(row));
  }

  async findAllByFilters(filters: {
    status?: "pending" | "approved" | "rejected";
    paymentMethod?: PaymentMethod;
  }): Promise<PaymentRequest[]> {
    let query = this.db
      .from(this.table)
      .select(filters.paymentMethod ? "*, payments!inner(method)" : "*")
      .order("created_at", { ascending: false });

    if (filters.status) {
      query = query.eq("status", filters.status);
    }

    if (filters.paymentMethod) {
      query = query.eq("payments.method", filters.paymentMethod);
    }

    const { data, error } = await query;

    if (error) throw error;

    return data.map((row) => this.map(row));
  }

  // =========================
  // FILTER BY TYPE (nuevo 🔥)
  // =========================
  async findByType(type: PaymentType): Promise<PaymentRequest[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("type", type)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return data.map((row) => this.map(row));
  }

  // =========================
  // GET BY ID
  // =========================
  async findById(id: number): Promise<PaymentRequest | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.map(data) : null;
  }

  async findByPaymentId(paymentId: number): Promise<PaymentRequest | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("payment_id", paymentId)
      .maybeSingle();

    if (error) throw error;

    return data ? this.map(data) : null;
  }

  // =========================
  // GET BY USER
  // =========================
  async findByUser(userId: string): Promise<PaymentRequest[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return data.map((row) => this.map(row));
  }

  async hasPendingPartnerUpgrade(userId: string): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("user_id", userId)
      .eq("type", "partner_upgrade")
      .eq("status", "pending")
      .limit(1);

    if (error) throw error;

    return (data?.length ?? 0) > 0;
  }

  // =========================
  // UPDATE STATUS (solo testing)
  // =========================
  async updateStatusManual(
    id: number,
    status: "approved" | "rejected",
    reviewedBy: string,
    comment?: string
  ): Promise<PaymentRequest> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status,
        reviewed_by: reviewedBy,
        reviewed_at: new Date().toISOString(),
        comment,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;

    return this.map(data);
  }
}

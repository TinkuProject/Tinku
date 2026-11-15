import { DbClient } from "../types/db-client";
import { CashoutRequest } from "../dto/cashout-request.dto";

export class CashoutRequestsDAO {
  private table = "cashout_requests";

  constructor(private readonly db: DbClient) {}

  private map(row: any): CashoutRequest {
    return {
      id: row.id,
      user_id: row.user_id,
      cashout_package_id: row.cashout_package_id,
      status: row.status,
      tinkus_amount: row.tinkus_amount,
      cash_amount: Number(row.cash_amount),
      comment: row.comment ?? null,
      reviewed_by: row.reviewed_by ?? null,
      reviewed_at: row.reviewed_at ? new Date(row.reviewed_at) : null,
      transaction_id: row.transaction_id ?? null,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  async create(input: {
    user_id: string;
    cashout_package_id: number;
    comment?: string | null;
  }): Promise<CashoutRequest> {
    const { data, error } = await this.db.rpc(
      "create_cashout_request",
      {
        p_user_id: input.user_id,
        p_cashout_package_id: input.cashout_package_id,
        p_comment: input.comment ?? null,
      }
    );

    if (error) throw error;

    return this.map(data);
  }

  async approve(input: {
    id: number;
    admin_id: string;
    comment?: string | null;
  }): Promise<CashoutRequest> {
    const { data, error } = await this.db.rpc(
      "approve_cashout_request",
      {
        p_request_id: input.id,
        p_admin_id: input.admin_id,
        p_comment: input.comment ?? null,
      }
    );

    if (error) throw error;

    return this.map(data);
  }

  async reject(input: {
    id: number;
    admin_id: string;
    comment?: string | null;
  }): Promise<CashoutRequest> {
    const { data, error } = await this.db.rpc(
      "reject_cashout_request",
      {
        p_request_id: input.id,
        p_admin_id: input.admin_id,
        p_comment: input.comment ?? null,
      }
    );

    if (error) throw error;

    return this.map(data);
  }

  async findMine(userId: string): Promise<CashoutRequest[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((row) => this.map(row));
  }

  async findAll(limit = 50, offset = 0): Promise<CashoutRequest[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    return (data ?? []).map((row) => this.map(row));
  }

  async findPending(): Promise<CashoutRequest[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", "pending")
      .order("created_at", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((row) => this.map(row));
  }

  async findById(id: number): Promise<CashoutRequest | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.map(data) : null;
  }
}

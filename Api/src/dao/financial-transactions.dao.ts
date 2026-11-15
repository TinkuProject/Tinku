import { DbClient } from "../types/db-client";
import { FinancialTransaction } from "../dto/financial-transaction.dto";
import { TransactionCreateInput, TransactionUpdateInput, TransactionIdInput,
} from "../validation/financial-transactions.validation";
import { TransactionType, TransactionStatus } from "../constants/enums.constants";

export class FinancialTransactionsDAO {
  private table = "financial_transactions";
  constructor(private readonly db: DbClient) { }

  private mapToEntity(data: any): FinancialTransaction {
    return {
      id: data.id,
      user_id: data.user_id,
      type: data.type,
      status: data.status,
      amount: data.amount,
      currency: data.currency,
      purpose: data.purpose,
      reference_id: data.reference_id,
      payment_id: data.payment_id,
      description: data.description,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at
        ? new Date(data.updated_at)
        : null,
    };
  }

  async create(
    input: TransactionCreateInput & {
      user_id: string;
      status?: TransactionStatus;
    }
  ): Promise<FinancialTransaction> {
    const { data, error } = await this.db
      .from(this.table)
      .insert({
        ...input,
        status: input.status ?? "pending",
      })
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findById(
    input: TransactionIdInput
  ): Promise<FinancialTransaction | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findByUser(
    user_id: string,
    filters?: {
      type?: TransactionType;
      status?: TransactionStatus;
    }
  ): Promise<FinancialTransaction[]> {
    let query = this.db
      .from(this.table)
      .select("*")
      .eq("user_id", user_id);

    if (filters?.type) {
      query = query.eq("type", filters.type);
    }

    if (filters?.status) {
      query = query.eq("status", filters.status);
    }

    const { data, error } = await query.order("created_at", {
      ascending: false,
    });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByPayment(payment_id: number): Promise<FinancialTransaction[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("payment_id", payment_id);

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByType(type: TransactionType): Promise<FinancialTransaction[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("type", type)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByStatus(status: TransactionStatus): Promise<FinancialTransaction[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", status)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  /**
   * ⚠️ Ledger: solo metadata / status
   */
  async update(
    input: TransactionUpdateInput & TransactionIdInput
  ): Promise<FinancialTransaction> {
    const { id, ...rest } = input;

    const { data, error } = await this.db
      .from(this.table)
      .update(rest)
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async exists(input: TransactionIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }

  async findByReferenceAndPurpose(params: {
    reference_id: number;
    purpose: string;
    status?: TransactionStatus;
  }): Promise<FinancialTransaction | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("reference_id", params.reference_id)
      .eq("purpose", params.purpose)
      .eq("status", params.status ?? "pending")
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findLatestByUser(userId: string, limit: number = 5) {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(limit);

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }
}
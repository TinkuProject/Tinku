import { DbClient } from "../types/db-client";
import { Payment } from "../dto/payment.dto";
import { PaymentCreateInput, PaymentUpdateInput, PaymentIdInput,
} from "../validation/payments.validation";
import { PaymentMethod, PaymentStatus, PaymentType } from "../constants/enums.constants";

export class PaymentsDAO {
  private table = "payments";
  constructor(private readonly db: DbClient) { }

  private mapToEntity(data: any): Payment {
    return {
      id: data.id,
      user_id: data.user_id,
      method: data.method as PaymentMethod,
      status: data.status as PaymentStatus,
      amount: data.amount,
      amount_minor: data.amount_minor,
      currency_minor_unit: data.currency_minor_unit,
      currency: data.currency,
      external_reference: data.external_reference,
      stripe_client_request_id: data.stripe_client_request_id,
      gateway_target_id: data.gateway_target_id ?? null,
      type: data.type as PaymentType,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at
        ? new Date(data.updated_at)
        : null,
    };
  }

  async create(
    input: PaymentCreateInput & { user_id: string }
  ): Promise<Payment> {
    const { data, error } = await this.db
      .from(this.table)
      .insert({
        ...input,
        status: "pending",
      })
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findById(
    input: PaymentIdInput
  ): Promise<Payment | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findByUser(user_id: string): Promise<Payment[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", user_id)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByStatus(status: PaymentStatus): Promise<Payment[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", status)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findStalePendingGatewayByUser(
    userId: string,
    type: PaymentType,
    before: Date
  ): Promise<Payment[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", userId)
      .eq("type", type)
      .eq("method", "gateway")
      .eq("status", "pending")
      .lt("created_at", before.toISOString())
      .order("created_at", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByExternalReference(
    external_reference: string
  ): Promise<Payment | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("external_reference", external_reference)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findByStripeClientRequestId(
    userId: string,
    clientRequestId: string
  ): Promise<Payment | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", userId)
      .eq("stripe_client_request_id", clientRequestId)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async update(
    input: PaymentUpdateInput & PaymentIdInput
  ): Promise<Payment> {
    const { id, ...rest } = input;

    const { data, error } = await this.db
      .from(this.table)
      .update({
        ...rest,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async delete(input: PaymentIdInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", input.id);

    if (error) throw error;
  }

  async exists(input: PaymentIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}

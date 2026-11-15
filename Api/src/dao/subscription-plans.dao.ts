import { DbClient } from "../types/db-client";
import { SubscriptionPlan } from "../dto/subscription-plan.dto";
import { CreateSubscriptionPlanInput, UpdateSubscriptionPlanInput, SubscriptionPlanIdInput,
  SubscriptionPlanNameInput } from "../validation/subscription-plans.validation";

export class SubscriptionPlansDAO {
  private table = "subscription_plans";
  constructor(private readonly db: DbClient) {}

  private mapToEntity(data: any): SubscriptionPlan {
    return {
      id: data.id,
      name: data.name,
      price: data.price,
      currency: data.currency,
      duration_months: data.duration_months,
      included_tinku: data.included_tinku,
      status: data.status,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at ? new Date(data.updated_at) : null,
    };
  }

  async create(input: CreateSubscriptionPlanInput): Promise<SubscriptionPlan> {
    const { data, error } = await this.db
      .from(this.table)
      .insert(input)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findAll(): Promise<SubscriptionPlan[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("status", "active");

    if (error) throw error;

    return (data ?? []).map((item) => this.mapToEntity(item));
  }

  async findById(input: SubscriptionPlanIdInput): Promise<SubscriptionPlan | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findByName(input: SubscriptionPlanNameInput): Promise<SubscriptionPlan | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("name", input.name)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async update(input: UpdateSubscriptionPlanInput): Promise<SubscriptionPlan> {
    const { id, ...data } = input;

    const { data: result, error } = await this.db
      .from(this.table)
      .update({
        ...data,
        updated_at: new Date(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(result);
  }

  async softDelete(input: SubscriptionPlanIdInput): Promise<SubscriptionPlan> {
  const { data: result, error } = await this.db
    .from(this.table)
    .update({
      status: "archived",
      updated_at: new Date(),
    })
    .eq("id", input.id)
    .select("*")
    .single();

  if (error) throw error;
  return this.mapToEntity(result);
}

  async exists(input: SubscriptionPlanIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}
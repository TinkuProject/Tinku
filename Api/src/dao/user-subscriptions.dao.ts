import { DbClient } from "../types/db-client";
import { UserSubscription } from "../dto/user-subscription.dto";
import { CreateUserSubscriptionInput, UpdateUserSubscriptionInput,
  UserSubscriptionIdInput, UserSubscriptionByUserInput,
} from "../validation/user-subscriptions.validation";

export class UserSubscriptionsDAO {
  private table = "user_subscriptions";
  constructor(private readonly db: DbClient) { }

  private mapToEntity(data: any): UserSubscription {
    return {
      id: data.id,
      user_id: data.user_id,
      plan_id: data.plan_id,
      start_date: new Date(data.start_date),
      ...(data.end_date && {
        end_date: new Date(data.end_date),
      }),
      status: data.status,
    };
  }

  async create(
    input: CreateUserSubscriptionInput
  ): Promise<UserSubscription> {
    const payload = {
      ...input,
      start_date: input.start_date ?? new Date(),
    };

    const { data, error } = await this.db
      .from(this.table)
      .insert(payload)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findAll(): Promise<UserSubscription[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*");

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findById(
    input: UserSubscriptionIdInput
  ): Promise<UserSubscription | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findByUser(
    input: UserSubscriptionByUserInput
  ): Promise<UserSubscription[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", input.user_id);

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findActiveByUser(userId: string): Promise<UserSubscription[]> {
    const now = new Date().toISOString();

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", userId)
      .eq("status", "active")
      .or(`end_date.is.null,end_date.gt.${now}`);

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async update(
    input: UpdateUserSubscriptionInput
  ): Promise<UserSubscription> {
    const { id, ...updates } = input;

    const { data, error } = await this.db
      .from(this.table)
      .update({
        ...updates,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async delete(input: UserSubscriptionIdInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", input.id);

    if (error) throw error;
  }

  async exists(input: UserSubscriptionIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}
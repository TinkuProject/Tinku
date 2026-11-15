import { UserSubscriptionsDAO } from "../dao/user-subscriptions.dao";
import { SubscriptionPlansDAO } from "../dao/subscription-plans.dao";
import { CreateUserSubscriptionInput, UpdateUserSubscriptionInput,
  UserSubscriptionIdInput, UserSubscriptionByUserInput,
} from "../validation/user-subscriptions.validation";
import { UserSubscription } from "../dto/user-subscription.dto";

export class UserSubscriptionsService {
  constructor(
    private readonly dao: UserSubscriptionsDAO,
    private readonly plansDao: SubscriptionPlansDAO
  ) {}

  async create(
    input: CreateUserSubscriptionInput
  ): Promise<UserSubscription> {
    const plan = await this.plansDao.findById({ id: input.plan_id });

    if (!plan) {
      throw new Error("Subscription plan not found");
    }

    const startDate = input.start_date ?? new Date();

    const endDate = new Date(startDate);
    endDate.setMonth(endDate.getMonth() + plan.duration_months);

    return this.dao.create({
      ...input,
      start_date: startDate,
      end_date: endDate,
    });
  }

  async getAll(): Promise<UserSubscription[]> {
    return this.dao.findAll();
  }

  async getById(
    input: UserSubscriptionIdInput
  ): Promise<UserSubscription> {
    const sub = await this.dao.findById(input);

    if (!sub) {
      throw new Error("Subscription not found");
    }

    return sub;
  }

  async getByUser(
    input: UserSubscriptionByUserInput
  ): Promise<UserSubscription[]> {
    return this.dao.findByUser(input);
  }

  async getCurrentByUser(
    input: UserSubscriptionByUserInput
  ): Promise<UserSubscription | null> {

    const subs = await this.dao.findByUser(input);

    const now = new Date();

    const active = subs.filter((s) =>
      s.status === "active" &&
      (!s.end_date || s.end_date > now)
    );

    if (active.length === 0) return null;

    active.sort((a, b) =>
      b.start_date.getTime() - a.start_date.getTime()
    );

    const current = active[0];

    return current ?? null;
  }

  async update(
    input: UpdateUserSubscriptionInput
  ): Promise<UserSubscription> {
    const exists = await this.dao.exists({ id: input.id });

    if (!exists) {
      throw new Error("Subscription not found");
    }

    return this.dao.update(input);
  }

  async delete(input: UserSubscriptionIdInput): Promise<void> {
    const exists = await this.dao.exists(input);

    if (!exists) {
      throw new Error("Subscription not found");
    }

    await this.dao.delete(input);
  }

  async cancel(
    input: UserSubscriptionIdInput
  ): Promise<UserSubscription> {
    const exists = await this.dao.exists(input);

    if (!exists) {
      throw new Error("Subscription not found");
    }

    return this.dao.update({
      id: input.id,
      status: "cancelled",
    });
  }
}
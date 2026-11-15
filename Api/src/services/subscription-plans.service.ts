import { SubscriptionPlansDAO } from "../dao/subscription-plans.dao";
import {
  CreateSubscriptionPlanInput, UpdateSubscriptionPlanInput,
  SubscriptionPlanIdInput
} from "../validation/subscription-plans.validation";
import { SubscriptionPlan } from "../dto/subscription-plan.dto";

export class SubscriptionPlansService {
  constructor(private readonly dao: SubscriptionPlansDAO) { }

  async create(input: CreateSubscriptionPlanInput): Promise<SubscriptionPlan> {
    const existing = await this.dao.findByName({ name: input.name });

    if (existing && existing.status !== "archived") {
      throw new Error("Subscription plan with this name already exists");
    }

    return this.dao.create(input);
  }

  async getAll(): Promise<SubscriptionPlan[]> {
    return this.dao.findAll();
  }

  async getById(input: SubscriptionPlanIdInput): Promise<SubscriptionPlan | null> {
    return this.dao.findById(input);
  }

  async update(input: UpdateSubscriptionPlanInput): Promise<SubscriptionPlan> {
    const existing = await this.dao.findById({ id: input.id });

    if (!existing) {
      throw new Error("Subscription plan not found");
    }

    if (existing.status === "archived") {
      throw new Error("Cannot update archived subscription plan");
    }

    return this.dao.update(input);
  }

  async softDelete(input: SubscriptionPlanIdInput): Promise<SubscriptionPlan> {
    const existing = await this.dao.findById(input);

    if (!existing) {
      throw new Error("Subscription plan not found");
    }

    if (existing.status === "archived") {
      throw new Error("Subscription plan already archived");
    }

    return this.dao.softDelete(input);
  }
}
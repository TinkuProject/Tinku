import { z } from "zod";
import { BASIC_STATUS } from "../constants/enums.constants";

export const createSubscriptionPlanSchema = z.object({
  name: z.string().min(1).max(50),
  price: z.number().min(0),
  currency: z.string().min(1).max(10).default("BOB"),
  duration_months: z.number().int().min(1).optional(),
  included_tinku: z.number().int().min(0),
  status: z.enum(BASIC_STATUS).default("active"),
});

export const updateSubscriptionPlanSchema = z.object({
  id: z.number().int().positive(),
  name: z.string().min(1).max(50).optional(),
  price: z.number().min(0).optional(),
  currency: z.string().min(1).max(10).optional(),
  duration_months: z.number().int().min(1).optional(),
  included_tinku: z.number().int().min(0).optional(),
  status: z.enum(BASIC_STATUS).optional(),
});

export const subscriptionPlanIdSchema = z.object({
  id: z.number().int().positive(),
});

export const subscriptionPlanNameSchema = z.object({
  name: z.string().min(1),
});

export type CreateSubscriptionPlanInput = z.infer<typeof createSubscriptionPlanSchema>;
export type UpdateSubscriptionPlanInput = z.infer<typeof updateSubscriptionPlanSchema>;
export type SubscriptionPlanIdInput = z.infer<typeof subscriptionPlanIdSchema>;
export type SubscriptionPlanNameInput = z.infer<typeof subscriptionPlanNameSchema>;
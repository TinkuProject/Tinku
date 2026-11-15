import { z } from "zod";
import { SUBSCRIPTION_STATUS } from "../constants/enums.constants";

export const createUserSubscriptionSchema = z.object({
  user_id: z.string().uuid(),
  plan_id: z.number().int().positive(),

  start_date: z.coerce.date().optional(),
  end_date: z.coerce.date().optional(),

  status: z.enum(SUBSCRIPTION_STATUS).default("active"),
}).refine(
  (data) =>
    !data.start_date ||
    !data.end_date ||
    data.end_date >= data.start_date,
  {
    message: "end_date must be after start_date",
    path: ["end_date"],
  }
);

export const updateUserSubscriptionSchema = z.object({
  id: z.number().int().positive(),

  user_id: z.string().uuid().optional(),
  plan_id: z.number().int().positive().optional(),

  start_date: z.coerce.date().optional(),
  end_date: z.coerce.date().optional(),

  status: z.enum(SUBSCRIPTION_STATUS).optional(),
}).refine(
  (data) =>
    !data.start_date ||
    !data.end_date ||
    data.end_date >= data.start_date,
  {
    message: "end_date must be after start_date",
    path: ["end_date"],
  }
);

export const userSubscriptionIdSchema = z.object({
  id: z.number().int().positive(),
});

export const userSubscriptionByUserSchema = z.object({
  user_id: z.string().uuid(),
});

export type CreateUserSubscriptionInput = z.infer<typeof createUserSubscriptionSchema>;
export type UpdateUserSubscriptionInput = z.infer<typeof updateUserSubscriptionSchema>;
export type UserSubscriptionIdInput = z.infer<typeof userSubscriptionIdSchema>;
export type UserSubscriptionByUserInput = z.infer<typeof userSubscriptionByUserSchema>;
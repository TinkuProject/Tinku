import { z } from "zod";
import { PAYMENT_TYPE } from "../constants/enums.constants";

export const createStripePaymentIntentSchema = z
  .object({
    type: z.enum(PAYMENT_TYPE),
    targetId: z.number().int().positive().optional(),
    clientRequestId: z.string().trim().min(8).max(120).optional(),
  })
  .superRefine((data, ctx) => {
    if (data.type === "marketplace_order") {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Marketplace orders can only be paid with Tinkus",
        path: ["type"],
      });
    }

    if (
      data.type === "coin_purchase" ||
      data.type === "subscription" ||
      data.type === "marketplace_order"
    ) {
      if (!data.targetId) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "targetId is required for this payment type",
          path: ["targetId"],
        });
      }
    }
  });

export type CreateStripePaymentIntentInput = z.infer<
  typeof createStripePaymentIntentSchema
>;

export const stripePaymentIntentIdSchema = z.object({
  paymentIntentId: z.string().min(1),
});

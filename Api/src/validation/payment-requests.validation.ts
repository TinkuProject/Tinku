import { z } from "zod";
import { PAYMENT_TYPE } from "../constants/enums.constants";

export const createPaymentRequestSchema = z
  .object({
    paymentId: z.number().int().positive(),
    type: z.enum(PAYMENT_TYPE),
    targetId: z.number().int().positive().optional(),
  })
  .superRefine((data, ctx) => {
    if (data.type === "coin_purchase" || data.type === "subscription") {
      if (!data.targetId) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "targetId is required for this payment type",
          path: ["targetId"],
        });
      }
    }
});

export const approvePaymentRequestSchema = z.object({
  requestId: z.number().int().positive(),
  comment: z.string().optional(),
});

export const rejectPaymentRequestSchema = z.object({
  requestId: z.number().int().positive(),
  comment: z.string().optional(),
});

export type CreatePaymentRequestInput = z.infer<typeof createPaymentRequestSchema>;
export type ApprovePaymentRequestInput = z.infer<typeof approvePaymentRequestSchema>;
export type RejectPaymentRequestInput = z.infer<typeof rejectPaymentRequestSchema>;
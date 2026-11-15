import { z } from "zod";
import { PAYMENT_METHODS, PAYMENT_STATUS, PAYMENT_TYPE } from "../constants/enums.constants";

export const createPaymentSchema = z.object({
  method: z.enum(PAYMENT_METHODS),
  amount: z.number().positive(),
  amount_minor: z.number().int().positive().optional().nullable(),
  currency_minor_unit: z.number().int().min(0).max(4).optional().nullable(),
  currency: z.enum(["BOB"]).default("BOB"),
  type: z.enum(PAYMENT_TYPE),
  external_reference: z.string().optional().nullable(),
  stripe_client_request_id: z.string().max(120).optional().nullable(),
  gateway_target_id: z.number().int().positive().optional().nullable(),
  description: z.string().max(255).optional().nullable(),
});

export const updatePaymentSchema = z.object({
  status: z.enum(PAYMENT_STATUS).optional(),
  amount_minor: z.number().int().positive().optional().nullable(),
  currency_minor_unit: z.number().int().min(0).max(4).optional().nullable(),

  external_reference: z.string().optional().nullable(),
  stripe_client_request_id: z.string().max(120).optional().nullable(),
  description: z.string().optional().nullable(),
});

export const paymentIdSchema = z.object({
  id: z.coerce.number().int().positive(),
});


export type PaymentCreateInput = z.infer<typeof createPaymentSchema>;
export type PaymentUpdateInput = z.infer<typeof updatePaymentSchema>;
export type PaymentIdInput = z.infer<typeof paymentIdSchema>;

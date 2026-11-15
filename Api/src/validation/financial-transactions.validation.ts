import { z } from "zod";
import { TRANSACTION_TYPES, TRANSACTION_STATUS } from "../constants/enums.constants";

export const createTransactionSchema = z.object({
  type: z.enum(TRANSACTION_TYPES),

  amount: z.number().int().positive(),

  currency: z.enum(["TINKU"]).default("TINKU"),

  purpose: z.string().max(100).optional().nullable(),
  reference_id: z.number().int().optional().nullable(),
  payment_id: z.number().int().optional().nullable(),
  description: z.string().max(255).optional().nullable(),
});

export const updateTransactionSchema = z.object({
  status: z.enum(TRANSACTION_STATUS).optional(),
  description: z.string().optional().nullable(),
});

export const transactionFilterSchema = z.object({
  type: z.enum(TRANSACTION_TYPES).optional(),
  status: z.enum(TRANSACTION_STATUS).optional(),
});

export const transactionIdSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export type TransactionFilterInput = z.infer<typeof transactionFilterSchema>;
export type TransactionCreateInput = z.infer<typeof createTransactionSchema>;
export type TransactionUpdateInput = z.infer<typeof updateTransactionSchema>;
export type TransactionIdInput = z.infer<typeof transactionIdSchema>;
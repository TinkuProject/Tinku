import { z } from "zod";

export const createCashoutRequestSchema = z.object({
  cashout_package_id: z.number().int().positive(),
  comment: z.string().max(500).optional().nullable(),
});

export const reviewCashoutRequestSchema = z.object({
  comment: z.string().max(500).optional().nullable(),
});

export const cashoutRequestIdSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const cashoutRequestPaginationSchema = z.object({
  limit: z.coerce.number().int().positive().max(100).optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

export type CreateCashoutRequestInput = z.infer<typeof createCashoutRequestSchema>;
export type ReviewCashoutRequestInput = z.infer<typeof reviewCashoutRequestSchema>;
export type CashoutRequestIdInput = z.infer<typeof cashoutRequestIdSchema>;
export type CashoutRequestPaginationInput = z.infer<typeof cashoutRequestPaginationSchema>;

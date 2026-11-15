import { z } from "zod";

export const createBusinessClaimRequestSchema = z.object({
  business_id: z.number().int().positive(),
  comment: z.string().max(500).optional(),
  documents: z.array(z.string().url()).min(1),
});

export const reviewBusinessClaimRequestSchema = z.object({
  status: z.enum(["approved", "rejected"]),
  comment: z.string().trim().max(500).optional(),
}).refine(input => input.status !== "rejected" || !!input.comment, {
  path: ["comment"], message: "Debes indicar el motivo del rechazo",
});

export const businessClaimRequestIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const businessClaimRequestPaginationSchema = z.object({
  limit: z.coerce.number().int().positive().max(100).optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

export const businessClaimRequestByBusinessSchema = z.object({
  businessId: z.coerce.number().int().positive(),
  limit: z.coerce.number().int().positive().max(100).optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

export type CreateBusinessClaimRequestInput = z.infer<
  typeof createBusinessClaimRequestSchema
>;

export type ReviewBusinessClaimRequestInput = z.infer<
  typeof reviewBusinessClaimRequestSchema
>;

export type BusinessClaimRequestIdParam = z.infer<
  typeof businessClaimRequestIdParamSchema
>;

export type BusinessClaimRequestPagination = z.infer<
  typeof businessClaimRequestPaginationSchema
>;

export type BusinessClaimRequestByBusiness = z.infer<
  typeof businessClaimRequestByBusinessSchema
>;

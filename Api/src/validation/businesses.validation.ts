import { z } from "zod";
import { BUSINESS_TYPE, BUSINESS_STATUS } from "../constants/enums.constants";
import { locationSchema } from "../types/location.type";

export const createBusinessSchema = z.object({
  category_id: z.number().int().positive(),
  name: z.string().min(2).max(150),
  nit: z.string().max(50).optional().nullable(),
  description: z.string().trim().min(1).max(500),
  phone: z.string().max(50).optional().nullable(),
  email: z.string().email().optional().nullable(),
  business_type: z.enum(BUSINESS_TYPE),
  address: z.string().min(3).max(250),
  location: locationSchema,
  website: z.preprocess(
  (value) => {
    if (typeof value !== "string") return value;
    const trimmed = value.trim();
    if (trimmed === "") return undefined;
    if (!/^https?:\/\//i.test(trimmed)) return `https://${trimmed}`;
    return trimmed;
  },
  z.string().url().optional().nullable()
),
});

export const updateBusinessSchema = createBusinessSchema.partial();

export const adminUpdateBusinessSchema = z.object({
  owner_id: z.string().uuid().nullable().optional(),
  validated: z.boolean().optional(),
  status: z.enum(BUSINESS_STATUS).optional(),
});

export const businessIdSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const businessCategorySchema = z.object({
  category_id: z.number().int().positive(),
});

export const businessModerationSchema = z.object({
  message: z.preprocess(
    (value) =>
      typeof value === "string" && value.trim() === "" ? undefined : value,
    z.string().trim().max(500).optional()
  ),
});

export const businessRejectSchema = z.object({
  message: z.string().trim().min(1).max(500),
});

export const businessBatchSchema = z.object({
  ids: z.string().transform((value, ctx) => {
    const ids = [
      ...new Set(
        value
          .split(",")
          .map((item) => Number(item.trim()))
          .filter((item) => Number.isInteger(item) && item > 0)
      ),
    ];

    if (ids.length === 0) {
      ctx.addIssue({
        code: "custom",
        message: "ids query param must contain positive integers",
      });
    }

    return ids;
  }),
});

export type BusinessModerationInput = z.infer<typeof businessModerationSchema>;
export type BusinessRejectInput = z.infer<typeof businessRejectSchema>;
export type BusinessCategoryInput = z.infer<typeof businessCategorySchema>;
export type BusinessCreateInput = z.infer<typeof createBusinessSchema>;
export type BusinessUpdateInput = z.infer<typeof updateBusinessSchema>;
export type AdminBusinessUpdateInput = z.infer<typeof adminUpdateBusinessSchema>;
export type BusinessIdInput = z.infer<typeof businessIdSchema>;
export type BusinessBatchInput = z.infer<typeof businessBatchSchema>;

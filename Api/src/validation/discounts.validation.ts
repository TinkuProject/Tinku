import { z } from "zod";
import { PROMOTION_STATUS } from "../constants/enums.constants";

export const discountCreateSchema = z.object({
  business_id: z.number().int().positive(),
  description: z.string().max(500).optional().nullable(),
  discount_percent: z
    .number()
    .min(0)
    .max(100),

  start_date: z.string().datetime(),
  end_date: z.string().datetime(),
  status: z.enum(PROMOTION_STATUS).optional(),
}).refine((data) => {
  return new Date(data.end_date) > new Date(data.start_date);
}, {
  message: "end_date must be greater than start_date",
  path: ["end_date"],
});

export const discountIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const businessIdParamSchema = z.object({
  businessId: z.coerce.number().int().positive(),
});

export const discountBusinessesQuerySchema = z.object({
  business_ids: z
    .string()
    .min(1)
    .transform((value) => value.split(",").map((id) => Number(id.trim())))
    .pipe(z.array(z.number().int().positive()).min(1).max(100)),
  active: z
    .enum(["true", "false"])
    .optional()
    .transform((value) => value === "true"),
});

export const discountUpdateSchema = discountCreateSchema.partial();

export type DiscountCreateInput = z.infer<typeof discountCreateSchema>;
export type DiscountUpdateInput = z.infer<typeof discountUpdateSchema>;
export type DiscountBusinessesQuery = z.infer<typeof discountBusinessesQuerySchema>;

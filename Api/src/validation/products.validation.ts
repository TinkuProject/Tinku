import { z } from "zod";
import { PRODUCT_STATUS } from "../constants/enums.constants";

const productVolumeTierSchema = z.enum(["small", "medium", "large"]);

export const productCreateSchema = z.object({
  business_id: z.number().int().positive(),
  category_id: z.number().int().positive(),
  name: z.string().min(1),
  description: z.string().optional().nullable(),
  price: z.number().positive().optional(),
  tinku_price: z.number().int().positive().optional(),
  stock: z.number().int().min(0).optional(),
  volume_tier: productVolumeTierSchema.optional().default("small"),
});

export const productUpdateSchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional().nullable(),
  price: z.number().positive().optional(),
  tinku_price: z.number().int().positive().optional(),
  stock: z.number().int().min(0).optional(),
  volume_tier: productVolumeTierSchema.optional(),
  status: z.enum(PRODUCT_STATUS).optional(),
});

export const idParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const businessParamSchema = z.object({
  businessId: z.coerce.number().int().positive(),
});

export const productsBusinessesQuerySchema = z.object({
  business_ids: z
    .string()
    .min(1)
    .transform((val) => val.split(",").map(Number)),
});

export type ProductInsert = ProductCreateInput & {
  status: string;
};

export type ProductCreateInput = z.infer<typeof productCreateSchema>;
export type ProductUpdateInput = z.infer<typeof productUpdateSchema>;

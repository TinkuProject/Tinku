import { z } from "zod";
import { CATEGORY_ENTITY_TYPE, BUSINESS_TYPE, BASIC_STATUS } from "../constants/enums.constants";

export const idParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

// CREATE
export const categoryCreateSchema = z
  .object({
    name: z.string().min(1),
    entity_type: z.enum(CATEGORY_ENTITY_TYPE),
    business_type: z.enum(BUSINESS_TYPE).optional().nullable(),
  })
  .refine((data) => {
    if (data.entity_type === "business") {
      return data.business_type !== undefined && data.business_type !== null;
    }
    return true;
  }, {
    message: "business_type is required when entity_type is business",
    path: ["business_type"],
  });

// UPDATE
export const categoryUpdateSchema = z
  .object({
    name: z.string().min(1).optional(),
    entity_type: z.enum(CATEGORY_ENTITY_TYPE).optional(),
    business_type: z.enum(BUSINESS_TYPE).optional().nullable(),
  })
  .refine((data) => {
    if (data.entity_type === "business") {
      return data.business_type !== undefined && data.business_type !== null;
    }
    return true;
  }, {
    message: "business_type is required when entity_type is business",
    path: ["business_type"],
  }).strict();

// FILTER
export const categoryFilterSchema = z.object({
  entity_type: z.enum(CATEGORY_ENTITY_TYPE).optional(),
  business_type: z.enum(BUSINESS_TYPE).optional(),
  status: z.enum(BASIC_STATUS).optional(),
});

export type CategoryCreateInput = z.infer<typeof categoryCreateSchema>;
export type CategoryUpdateInput = z.infer<typeof categoryUpdateSchema>;
export type CategoryFilterInput = z.infer<typeof categoryFilterSchema>;
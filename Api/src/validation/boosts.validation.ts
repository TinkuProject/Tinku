import { z } from "zod";
import { PROMOTION_STATUS, VISIT_ENTITY } from "../constants/enums.constants";

const dateSchema = z.string().datetime(); // ISO 8601

export const boostCreateSchema = z.object({
  entity_type: z.enum(VISIT_ENTITY),
  entity_id: z.number().int().positive(),

  start_date: dateSchema,
  end_date: dateSchema,

  status: z.enum(PROMOTION_STATUS).optional(),
}).refine(
  (data) => new Date(data.end_date) >= new Date(data.start_date),
  {
    message: "end_date debe ser mayor o igual que start_date",
    path: ["end_date"],
  }
);


export const boostIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const paginationSchema = z.object({
  limit: z.coerce.number().int().positive().optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

export const boostByEntitySchema = z.object({
  entityType: z.enum(VISIT_ENTITY),
  entityId: z.coerce.number().int().positive(),
});

export const boostUpdateSchema = boostCreateSchema.partial();

export type BoostCreateInput = z.infer<typeof boostCreateSchema>;
export type BoostUpdateInput = z.infer<typeof boostUpdateSchema>;

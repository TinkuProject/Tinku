import { z } from "zod";
import { VISIT_ENTITY } from "../constants/enums.constants";

export const entityTransportRelationCreateSchema = z.object({
  entity_type: z.enum(VISIT_ENTITY),
  entity_id: z.number().int().positive(),
  transport_line_id: z.number().int().positive(),
});

export const entityTransportRelationParamsSchema = z.object({
  entityType: z.enum(VISIT_ENTITY),
  entityId: z.coerce.number().int().positive(),
});

export const entityTransportRelationsQuerySchema = z.object({
  entity_type: z.enum(VISIT_ENTITY),
  entity_ids: z
    .string()
    .min(1)
    .transform((value) => value.split(",").map((id) => Number(id.trim())))
    .pipe(z.array(z.number().int().positive()).min(1).max(100)),
});

export const entityTransportRelationDeleteSchema = z.object({
  entityType: z.enum(VISIT_ENTITY),
  entityId: z.coerce.number().int().positive(),
  lineId: z.coerce.number().int().positive(),
});

export const entityTransportRelationReplaceSchema = z.object({
  params: entityTransportRelationParamsSchema,
  body: z.object({
    line_ids: z.array(z.number().int().positive()),
  }),
});

export type EntityTransportRelationCreateInput = z.infer<
  typeof entityTransportRelationCreateSchema
>;
export type EntityTransportRelationsQuery = z.infer<
  typeof entityTransportRelationsQuerySchema
>;

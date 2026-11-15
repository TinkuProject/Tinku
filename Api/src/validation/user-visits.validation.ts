import { z } from "zod";
import { VISIT_ENTITY, VISIT_TYPE } from "../constants/enums.constants";

export const userVisitCreateSchema = z.object({
  entity_type: z.enum(VISIT_ENTITY),
  entity_id: z.number().int().positive(),
  type: z.enum(VISIT_TYPE),
});

export const userVisitIdSchema = z.object({
  id: z.number().int().positive(),
});

export const userVisitByUserSchema = z.object({
  user_id: z.string().uuid(),
});

export const userVisitByEntitySchema = z.object({
  entity_type: z.enum(VISIT_ENTITY),
  entity_id: z.number().int().positive(),
});

export const userVisitEntityCountsSchema = z.object({
  entity_type: z.enum(VISIT_ENTITY),
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
  type: z.enum(VISIT_TYPE).optional().default("visited"),
});

export type UserVisitCreateInput = z.infer<typeof userVisitCreateSchema>;
export type UserVisitIdInput = z.infer<typeof userVisitIdSchema>;
export type UserVisitByUserInput = z.infer<typeof userVisitByUserSchema>;
export type UserVisitByEntityInput = z.infer<typeof userVisitByEntitySchema>;
export type UserVisitEntityCountsInput = z.infer<typeof userVisitEntityCountsSchema>;

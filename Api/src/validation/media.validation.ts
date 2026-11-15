import { z } from "zod";
import { MEDIA_TYPE, MEDIA_ENTITY_TYPE } from "../constants/enums.constants";

const NON_USER_ENTITY_TYPES = MEDIA_ENTITY_TYPE.filter(
  (t) => t !== "user"
) as Exclude<typeof MEDIA_ENTITY_TYPE[number], "user">[];

// USER (UUID)
const userMediaSchema = z.object({
  entity_type: z.literal("user"),
  entity_id: z.string().uuid(),
  url: z.string().url(),
  type: z.enum(MEDIA_TYPE),
  description: z.string().optional().nullable(),
  is_primary: z.boolean().optional(),
  display_order: z.number().int().min(0).optional(),
});

// RESTO (number)
const otherMediaSchema = z.object({
  entity_type: z.enum(NON_USER_ENTITY_TYPES),
  entity_id: z.number().int().positive(),
  url: z.string().url(),
  type: z.enum(MEDIA_TYPE),
  description: z.string().optional().nullable(),
  is_primary: z.boolean().optional(),
  display_order: z.number().int().min(0).optional(),
});

export const mediaEntitiesQuerySchema = z.object({
  entity_type: z.enum(MEDIA_ENTITY_TYPE),
  entity_ids: z
    .string()
    .min(1)
    .transform((val) => val.split(",")),
}).superRefine((value, ctx) => {
  for (const id of value.entity_ids) {
    if (value.entity_type === "user") {
      if (!z.string().uuid().safeParse(id).success) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["entity_ids"],
          message: "User media entity_ids must be UUIDs",
        });
      }
      continue;
    }

    if (!z.coerce.number().int().positive().safeParse(id).success) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["entity_ids"],
        message: "Media entity_ids must be positive integers",
      });
    }
  }
});

export type MediaEntitiesQuery = z.infer<typeof mediaEntitiesQuerySchema>;

export const createMediaSchema = z.union([
  userMediaSchema,
  otherMediaSchema,
]);

export const updateMediaSchema = z.object({
  url: z.string().url().optional(),
  type: z.enum(MEDIA_TYPE).optional(),
  description: z.string().optional().nullable(),
  is_primary: z.boolean().optional(),
  display_order: z.number().int().min(0).optional(),
});

export const mediaIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

const userQuerySchema = z.object({
  entity_type: z.literal("user"),
  entity_id: z.string().uuid(),
});

const otherQuerySchema = z.object({
  entity_type: z.enum(NON_USER_ENTITY_TYPES),
  entity_id: z.coerce.number().int().positive(),
});

export const mediaEntityQuerySchema = z.union([
  userQuerySchema,
  otherQuerySchema,
]);

export const mediaUrlSchema = z.object({
  url: z.string().url(),
});

export type MediaCreateInput = z.infer<typeof createMediaSchema>;
export type MediaUpdateInput = z.infer<typeof updateMediaSchema>;
export type MediaEntityQuery = z.infer<typeof mediaEntityQuerySchema>;

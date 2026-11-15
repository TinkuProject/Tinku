import { z } from "zod";
import { UPDATE_ENTITY_TYPE } from "../constants/enums.constants";

import { updateBusinessSchema } from "./businesses.validation";
import { eventUpdateSchema } from "./events.validation";
import { productUpdateSchema } from "./products.validation";
import { updateCertificationSchema } from "./certifications.validation";

const updateSchemasMap = {
  business: updateBusinessSchema,
  event: eventUpdateSchema,
  product: productUpdateSchema,
  certification: updateCertificationSchema,
} as const;

export const createEntityUpdateSchema = z.object({
  entity_type: z.enum(UPDATE_ENTITY_TYPE),
  entity_id: z.number().int().positive(),
  data: z.record(z.string(), z.any()), // 🔥 FIX 1
}).superRefine((val, ctx) => {
  const schema = updateSchemasMap[val.entity_type];

  if (!schema) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Unsupported entity type",
    });
    return;
  }

  const result = schema.safeParse(val.data);

  if (!result.success) {
    result.error.issues.forEach((issue) => {
        ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: issue.message,
        path: issue.path,
        });
    });
    }

  if (Object.keys(val.data).length === 0) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Debe enviar al menos un campo para actualizar",
    });
  }
});

export const reviewEntityUpdateSchema = z.object({
  update_id: z.number().int().positive(),
  comment: z.string().max(500).optional(),
});

export type CreateEntityUpdateInput = z.infer<typeof createEntityUpdateSchema>;
export type ReviewEntityUpdateInput = z.infer<typeof reviewEntityUpdateSchema>;
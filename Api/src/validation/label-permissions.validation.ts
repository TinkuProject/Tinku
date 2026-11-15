import { z } from "zod";

export const assignLabelPermissionSchema = z.object({
  label_id: z.number().int().positive(),
  permission_id: z.number().int().positive(),
});

export const labelPermissionParamsSchema = z.object({
  label_id: z.coerce.number().int().positive(),
  permission_id: z.coerce.number().int().positive(),
});

export const labelIdOnlyParamSchema = z.object({
  label_id: z.coerce.number().int().positive(),
});

export const labelIdParamSchema = z.object({
  label_id: z.coerce.number().int().positive(),
});

export type AssignLabelPermissionInput = z.infer<typeof assignLabelPermissionSchema>;
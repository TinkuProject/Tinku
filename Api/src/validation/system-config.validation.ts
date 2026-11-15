import { z } from "zod";

const baseUpdateConfigSchema = z.object({
  value: z.string().optional(),
  description: z.string().optional().nullable(),
});

export const updateConfigSchema = baseUpdateConfigSchema.refine(
  (data) => data.value !== undefined || data.description !== undefined,
  {
    message: "At least one field must be provided",
  }
);

export const keyParamSchema = z.object({
  key: z.string().min(1),
});

export const updateConfigWithKeySchema = baseUpdateConfigSchema
  .extend({
    key: z.string().min(1),
  })
  .refine(
    (data) => data.value !== undefined || data.description !== undefined,
    {
      message: "At least one field must be provided",
    }
  );

export type UpdateConfigInput = z.infer<typeof updateConfigSchema>;
export type KeyParamInput = z.infer<typeof keyParamSchema>;
export type UpdateConfigWithKeyInput = z.infer<typeof updateConfigWithKeySchema>;
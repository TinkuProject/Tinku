import { z } from "zod";

export const createLabelSchema = z.object({
  code: z.string().min(2).max(100),
  description: z.string().max(500).optional().nullable(),
});

export const updateLabelSchema = createLabelSchema.partial();

export const labelIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export type LabelCreateInput = z.infer<typeof createLabelSchema>;
export type LabelUpdateInput = z.infer<typeof updateLabelSchema>;
import { z } from "zod";

export const assignUserLabelSchema = z.object({
  user_id: z.string().uuid(),
  label_id: z.number().int().positive(),
});

export const userLabelParamsSchema = z.object({
  user_id: z.string().uuid(),
  label_id: z.number().int().positive(),
});

export const userLabelByUserSchema = z.object({
  user_id: z.string().uuid(),
});

export type AssignUserLabelInput = z.infer<typeof assignUserLabelSchema>;
export type UserLabelParamsInput = z.infer<typeof userLabelParamsSchema>;
export type UserLabelByUserInput = z.infer<typeof userLabelByUserSchema>;
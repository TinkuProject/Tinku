import { z } from "zod";
import { BASIC_STATUS } from "../constants/enums.constants";

export const tagCreateSchema = z.object({
  name: z.string().min(1).max(80),
  description: z.string().optional().nullable(),
  status: z.enum(BASIC_STATUS).default("active"),
});

export const tagUpdateSchema = z.object({
  id: z.number().int().positive(),
  name: z.string().min(1).max(80).optional(),
  description: z.string().optional().nullable(),
  status: z.enum(BASIC_STATUS).optional(),
});

export const tagIdSchema = z.object({
  id: z.number().int().positive(),
});

export type TagCreateInput = z.infer<typeof tagCreateSchema>;
export type TagUpdateInput = z.infer<typeof tagUpdateSchema>;
export type TagIdInput = z.infer<typeof tagIdSchema>;
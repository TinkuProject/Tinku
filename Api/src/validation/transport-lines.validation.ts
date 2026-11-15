import { z } from "zod";
import { BASIC_STATUS } from "../constants/enums.constants";

export const transportLineCreateSchema = z.object({
  vehicle_type_id: z.number().int().positive(),
  name: z.string().min(1).max(120),
  status: z.enum(BASIC_STATUS).default("inactive"),
});

export const transportLineUpdateSchema = z.object({
  id: z.number().int().positive(),
  vehicle_type_id: z.number().int().positive().optional(),
  name: z.string().min(1).max(120).optional(),
  status: z.enum(BASIC_STATUS).optional(),
});

export const transportLineIdSchema = z.object({
  id: z.number().int().positive(),
});

export type TransportLineCreateInput = z.infer<typeof transportLineCreateSchema>;
export type TransportLineUpdateInput = z.infer<typeof transportLineUpdateSchema>;
export type TransportLineIdInput = z.infer<typeof transportLineIdSchema>;

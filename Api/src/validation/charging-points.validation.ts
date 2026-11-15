import { z } from "zod";
import { CHARGING_POINT_STATUS } from "../constants/enums.constants";
import { locationSchema } from "../types/location.type";

export const createChargingPointSchema = z.object({
  name: z.string().min(1).max(150),
  address: z.string().min(1).max(250),
  location: locationSchema,
  status: z.enum(CHARGING_POINT_STATUS).default("active"),
});

export const updateChargingPointSchema = createChargingPointSchema.partial();

export const chargingPointIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export type CreateChargingPointInput = z.infer<typeof createChargingPointSchema>;
export type UpdateChargingPointInput = z.infer<typeof updateChargingPointSchema>;
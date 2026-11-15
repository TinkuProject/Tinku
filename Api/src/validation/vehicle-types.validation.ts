import { z } from "zod";

export const vehicleTypeCreateSchema = z.object({
  name: z.string().min(1).max(50),
});

export const vehicleTypeUpdateSchema = z.object({
  id: z.number().int().positive(),
  name: z.string().min(1).max(50).optional(),
});

export const vehicleTypeIdSchema = z.object({
  id: z.number().int().positive(),
});

export type VehicleTypeCreateInput = z.infer<typeof vehicleTypeCreateSchema>;
export type VehicleTypeUpdateInput = z.infer<typeof vehicleTypeUpdateSchema>;
export type VehicleTypeIdInput = z.infer<typeof vehicleTypeIdSchema>;
import { z } from "zod";

export const nearbyQuerySchema = z.object({
  lat: z.coerce.number().finite(),
  lng: z.coerce.number().finite(),
  radius: z.coerce.number().int().positive().optional(),
});
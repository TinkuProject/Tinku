import { z } from "zod";

export const locationSchema = z.object({
  latitude: z.number(),
  longitude: z.number(),
});

export type LocationInput = z.infer<typeof locationSchema>;
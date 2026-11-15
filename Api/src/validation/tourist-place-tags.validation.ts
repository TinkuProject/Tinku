import { z } from "zod";

export const touristPlaceTagSchema = z.object({
  tourist_place_id: z.number().int().positive(),
  tag_id: z.number().int().positive(),
});

export const touristPlaceIdSchema = z.object({
  tourist_place_id: z.number().int().positive(),
});

export const tagIdSchema = z.object({
  tag_id: z.number().int().positive(),
});

export type TouristPlaceTagInput = z.infer<typeof touristPlaceTagSchema>;
export type TouristPlaceIdInput = z.infer<typeof touristPlaceIdSchema>;
export type TagIdInput = z.infer<typeof tagIdSchema>;
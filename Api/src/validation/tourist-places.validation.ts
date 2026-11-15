import { z } from "zod";
import { BASIC_STATUS } from "../constants/enums.constants";
import { locationSchema } from "../types/location.type";

export const touristPlaceCreateSchema = z.object({
  category_id: z.number().int().positive().optional(),

  name: z.string().min(1).max(150),
  description: z.string().optional().nullable(),
  address: z.string().max(250).optional().nullable(),
  location: locationSchema,
  status: z.enum(BASIC_STATUS).default("active"),
});

export const touristPlaceUpdateSchema = z.object({
  id: z.number().int().positive(),

  category_id: z.number().int().positive().optional(),
  name: z.string().min(1).max(150).optional(),
  description: z.string().optional().nullable(),
  address: z.string().max(250).optional().nullable(),
  location: locationSchema.optional(),
  status: z.enum(BASIC_STATUS).optional(),
});

export const touristPlaceIdSchema = z.object({
  id: z.number().int().positive(),
});

export const touristPlaceCategorySchema = z.object({
  category_id: z.number().int().positive(),
});

export const touristPlaceBatchSchema = z.object({
  ids: z.string().transform((value, ctx) => {
    const ids = [
      ...new Set(
        value
          .split(",")
          .map((item) => Number(item.trim()))
          .filter((item) => Number.isInteger(item) && item > 0)
      ),
    ];

    if (ids.length === 0) {
      ctx.addIssue({
        code: "custom",
        message: "ids query param must contain positive integers",
      });
    }

    return ids;
  }),
});

export type TouristPlaceCreateInput = z.infer<typeof touristPlaceCreateSchema>;
export type TouristPlaceUpdateInput = z.infer<typeof touristPlaceUpdateSchema>;
export type TouristPlaceIdInput = z.infer<typeof touristPlaceIdSchema>;
export type TouristPlaceCategoryInput = z.infer<typeof touristPlaceCategorySchema>;
export type TouristPlaceBatchInput = z.infer<typeof touristPlaceBatchSchema>;

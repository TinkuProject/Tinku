import { z } from "zod";
import { OPENING_ENTITY, WEEK_DAY } from "../constants/enums.constants";

const timeRegex = /^([01]\d|2[0-3]):([0-5]\d):([0-5]\d)$/;

export const createOpeningHourSchema = z
  .object({
    entity_type: z.enum(OPENING_ENTITY),
    entity_id: z.number().int().positive(),
    week_day: z.enum(WEEK_DAY),

    start_time: z
      .string()
      .regex(timeRegex, "Invalid time format HH:mm:ss"),

    end_time: z
      .string()
      .regex(timeRegex, "Invalid time format HH:mm:ss"),
  })
  .refine((data) => data.end_time > data.start_time, {
    message: "end_time must be greater than start_time",
    path: ["end_time"],
  });

export const updateOpeningHourSchema = z
  .object({
    start_time: z
      .string()
      .regex(timeRegex, "Invalid time format HH:mm:ss")
      .optional(),

    end_time: z
      .string()
      .regex(timeRegex, "Invalid time format HH:mm:ss")
      .optional(),
  })
  .refine(
    (data) =>
      !data.start_time ||
      !data.end_time ||
      data.end_time > data.start_time,
    {
      message: "end_time must be greater than start_time",
      path: ["end_time"],
    }
  );

export const idParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const openingEntityParamSchema = z.object({
  entityType: z.enum(OPENING_ENTITY),
  entityId: z.coerce.number().int().positive(),
});

export const openingHoursEntitiesQuerySchema = z.object({
  entity_type: z.enum(OPENING_ENTITY),
  entity_ids: z
    .string()
    .min(1)
    .transform((value) => value.split(",").map((id) => Number(id.trim())))
    .pipe(z.array(z.number().int().positive()).min(1).max(100)),
});

export const openingHoursReplaceAllSchema = z.array(
  createOpeningHourSchema
);

export type CreateOpeningHourInput = z.infer<typeof createOpeningHourSchema>;
export type UpdateOpeningHourInput = z.infer<typeof updateOpeningHourSchema>;
export type OpeningHoursEntitiesQuery = z.infer<typeof openingHoursEntitiesQuerySchema>;

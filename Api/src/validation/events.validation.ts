import { z } from "zod";
import { EVENT_STATUS } from "../constants/enums.constants";
import { locationSchema } from "../types/location.type";
import { getEventDateIssue } from "../helper/event-dates.helper";

export const eventPageQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

const eventBaseSchema = z.object({
  business_id: z.number().int().positive().optional().nullable(),
  category_id: z.number().int().positive(),
  name: z.string().min(1).max(150),
  description: z.string().trim().min(1).max(1000),
  start_date: z.coerce.date(),
  end_date: z.coerce.date(),
  capacity: z.number().int().positive().optional().nullable(),
  tinku_price: z.number().int().nonnegative().optional(),
  address: z.string().min(3).max(250),
  location: locationSchema,
});

function validateEventDates(
  data: {
    start_date?: Date | undefined;
    end_date?: Date | undefined;
  },
  ctx: z.RefinementCtx
) {
  const { start_date, end_date } = data;

  if (start_date && end_date) {
    const issue = getEventDateIssue(start_date, end_date);
    if (issue) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: issue.message,
        path: [issue.field],
      });
    }
  } else if (end_date && end_date.getTime() < Date.now()) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "La fecha y hora de fin no puede estar en el pasado",
      path: ["end_date"],
    });
  }
}

export const eventCreateSchema = eventBaseSchema.superRefine(
  validateEventDates
);

export const eventUpdateSchema = eventBaseSchema
  .partial()
  .superRefine(validateEventDates);


export const getByStatusQuerySchema = z.object({
  status: z.enum(EVENT_STATUS),
});

export const adminEventUpdateSchema = z.object({
  status: z.enum(EVENT_STATUS).optional(),
});

export const eventIdSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const eventBatchSchema = z.object({
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

export const eventModerationSchema = z.object({
  message: z.preprocess(
    (value) =>
      typeof value === "string" && value.trim() === "" ? undefined : value,
    z.string().trim().max(500).optional()
  ),
});

export const eventRejectSchema = z.object({
  message: z.string().trim().min(1).max(500),
});

export type EventModerationInput = z.infer<typeof eventModerationSchema>;

export type EventCreateInput = z.infer<typeof eventCreateSchema>;
export type EventUpdateInput = z.infer<typeof eventUpdateSchema>;
export type AdminEventUpdateInput = z.infer<typeof adminEventUpdateSchema>;
export type EventIdInput = z.infer<typeof eventIdSchema>;

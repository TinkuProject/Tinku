import { z } from "zod";
import { RESERVATION_STATUS } from "../constants/enums.constants";

export const reservationCreateSchema = z.object({
  event_id: z.number(),
  quantity: z.number().int().min(1).default(1),
});

export const reservationUpdateSchema = z.object({
  status: z.enum(RESERVATION_STATUS),
});

export const reservationIdSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export type ReservationIdInput = z.infer<
  typeof reservationIdSchema
>;

export type ReservationCreateInput = z.infer<typeof reservationCreateSchema>;
export type ReservationUpdateInput = z.infer<typeof reservationUpdateSchema>;
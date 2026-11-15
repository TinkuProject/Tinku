import { z } from "zod";

export const eventTicketIdParamSchema = z.object({
  id: z.string().uuid(),
});

export const eventTicketDayIdParamSchema = z.object({
  ticketDayId: z.string().uuid(),
});

export const eventTicketReservationParamSchema = z.object({
  reservationId: z.coerce.number().int().positive(),
});

export const eventTicketEventParamSchema = z.object({
  eventId: z.coerce.number().int().positive(),
});

export const eventTicketCheckInSchema = z.object({
  token: z.string().min(1),
  event_id: z.number().int().positive(),
});

export type EventTicketIdParam = z.infer<typeof eventTicketIdParamSchema>;
export type EventTicketDayIdParam = z.infer<typeof eventTicketDayIdParamSchema>;
export type EventTicketReservationParam = z.infer<typeof eventTicketReservationParamSchema>;
export type EventTicketEventParam = z.infer<typeof eventTicketEventParamSchema>;
export type EventTicketCheckInInput = z.infer<typeof eventTicketCheckInSchema>;

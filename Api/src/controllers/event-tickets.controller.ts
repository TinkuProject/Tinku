import { Request, Response } from "express";
import { EventTicketsDAO } from "../dao/event-tickets.dao";
import { EventTicketsService } from "../services/event-tickets.service";
import { getUserClientFromRequest, supabaseAdmin } from "../config/supabase-client.config";
import { handleError } from "../utils/handleError";
import { OwnershipService } from "../services/ownership.service";
import {
  eventTicketCheckInSchema,
  eventTicketDayIdParamSchema,
  eventTicketEventParamSchema,
  eventTicketIdParamSchema,
  eventTicketReservationParamSchema,
} from "../validation/event-tickets.validation";

export class EventTicketsController {
  private getService(req: Request): EventTicketsService {
    const db = getUserClientFromRequest(req);
    const dao = new EventTicketsDAO(db);

    return new EventTicketsService(dao);
  }

  private getAdminService(): EventTicketsService {
    const dao = new EventTicketsDAO(supabaseAdmin);
    return new EventTicketsService(dao);
  }

  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const service = this.getAdminService();
      const result = await service.getMine(userId);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByReservation = async (req: Request, res: Response): Promise<void> => {
    try {
      const { reservationId } =
        eventTicketReservationParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "reservation",
        reservationId,
        req.user!
      );

      const service = this.getService(req);
      const result = await service.getByReservation(reservationId);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByEvent = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const { eventId } = eventTicketEventParamSchema.parse(req.params);

      await new OwnershipService(supabaseAdmin).validate(
        "event",
        eventId,
        req.user!
      );

      const service = this.getAdminService();
      const result = await service.getByEvent(eventId);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = eventTicketIdParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "event_ticket",
        id,
        req.user!
      );

      const service = this.getService(req);
      const result = await service.getById(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  issueQr = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const { ticketDayId } = eventTicketDayIdParamSchema.parse(req.params);

      const service = this.getAdminService();
      const result = await service.issueQr(ticketDayId, userId);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  checkIn = async (req: Request, res: Response): Promise<void> => {
    try {
      const scannerId = req.user?.id;
      if (!scannerId) throw new Error("Unauthorized");

      const input = eventTicketCheckInSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.checkIn({
        ...input,
        scanner_id: scannerId,
      });

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}

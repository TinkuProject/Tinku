import { Request, Response } from "express";
import { ReservationsService } from "../services/reservations.service";
import { ReservationsDAO } from "../dao/reservations.dao";
import { EventsDAO } from "../dao/events.dao";
import { reservationCreateSchema, reservationUpdateSchema, reservationIdSchema,
} from "../validation/reservations.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin } from "../config/supabase-client.config";
import { NotificationsDAO } from "../dao/notifications.dao";
import { NotificationsService } from "../services/notifications.service";
import { AuditLogsDAO } from "../dao/audit-logs.dao";

export class ReservationsController {
  private getService(req: Request): ReservationsService {
    const db = getUserClientFromRequest(req);

    const dao = new ReservationsDAO(db);
    const eventsDao = new EventsDAO(db);
    const notificationsDao = new NotificationsDAO(supabaseAdmin);
    const notificationsService = new NotificationsService(notificationsDao);
    const auditDao = new AuditLogsDAO(supabaseAdmin);

    return new ReservationsService(
      dao,
      eventsDao,
      notificationsService,
      auditDao
    );
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const input = reservationCreateSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(input, userId);

      res.status(201).json(result);

    } catch (err: any) {

      // manejar errores conocidos del RPC
      if (err.message?.includes("Insufficient balance")) {
        res.status(400).json({ message: "No tienes suficientes tinkus" });
        return;
      }

      if (err.message?.includes("Not enough capacity")) {
        res.status(400).json({ message: "No hay cupos disponibles" });
        return;
      }

      if (err.message?.includes("Event not found")) {
        res.status(404).json({ message: "Evento no encontrado" });
        return;
      }

      return handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const result = await service.getAll();

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = reservationIdSchema.parse(req.params);

      const service = this.getService(req);
      const result = await service.getById(input, req.user!);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const service = this.getService(req);
      const result = await service.getByUser(userId);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByEvent = async (req: Request, res: Response): Promise<void> => {
    try {
      const eventId = Number(req.params.eventId);

      const service = this.getService(req);
      const result = await service.getByEvent(eventId, req.user!);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMineByEvent = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const eventId = Number(req.params.eventId);

      const service = this.getService(req);
      const result = await service.getMineByEvent(userId, eventId);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const data = reservationUpdateSchema.parse(req.body);
      const { id } = reservationIdSchema.parse(req.params);

      const service = this.getService(req);
      const result = await service.update({ ...data, id }, req.user!);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const input = reservationIdSchema.parse(req.params);

      const service = this.getService(req);
      await service.delete(input, req.user!);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };
}

import { Request, Response } from "express";
import { NotificationsService } from "../services/notifications.service";
import { NotificationsDAO } from "../dao/notifications.dao";
import { notificationCreateSchema, notificationUpdateSchema, notificationIdParamSchema,
  notificationQuerySchema, notificationPaginationSchema, broadcastSchema, deviceTokenSchema } from "../validation/notifications.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin } from "../config/supabase-client.config";
import { OwnershipService } from "../services/ownership.service";

export class NotificationsController {

  private getService(req: Request): NotificationsService {
    const db = getUserClientFromRequest(req);
    const dao = new NotificationsDAO(db);
    return new NotificationsService(dao);
  }

  private getAdminService(): NotificationsService {
    const dao = new NotificationsDAO(supabaseAdmin);
    return new NotificationsService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = notificationCreateSchema.parse(req.body);

      const result = await service.create(data);
      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = notificationIdParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "notification",
        id,
        req.user!
      );

      const row = await service.getById(id);
      res.json(row);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMyNotifications = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const { limit } = notificationQuerySchema.parse(req.query);

      const userId = req.user!.id;

      const rows = await service.getByUser(userId, limit);
      res.json(rows);
    } catch (err) {
      return handleError(res, err);
    }
  };

  markAsRead = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = notificationIdParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "notification",
        id,
        req.user!
      );

      const updated = await service.markAsRead(id);
      res.json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };

  markAllAsRead = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const userId = req.user!.id;

      await service.markAllAsRead(userId);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = notificationIdParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "notification",
        id,
        req.user!
      );

      const data = notificationUpdateSchema.parse(req.body);
      const updated = await service.update(id, data);

      res.json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = notificationIdParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "notification",
        id,
        req.user!
      );

      await service.delete(id);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  getUnreadCount = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const userId = req.user!.id;

      const unread = await service.getUnreadCount(userId);

      res.json({ unread, count: unread });
    } catch (err) {
      return handleError(res, err);
    }
  };

  deleteAll = async (req: Request, res: Response): Promise<void> => {
    try {
      await this.getService(req).deleteAllByUser(req.user!.id);
      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMyNotificationsPage = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const { limit, offset } = notificationPaginationSchema.parse(req.query);
      const result = await service.getByUserPage(req.user!.id, limit, offset);

      res.json({
        items: result.items,
        total: result.total,
        limit,
        offset,
        has_more: offset + result.items.length < result.total,
      });
    } catch (err) {
      return handleError(res, err);
    }
  };

  registerDeviceToken = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const input = deviceTokenSchema.parse(req.body);
      const userId = req.user!.id;

      await service.registerDeviceToken(userId, input);
      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  unregisterDeviceToken = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const input = deviceTokenSchema.parse(req.body);
      const userId = req.user!.id;

      await service.unregisterDeviceToken(userId, input);
      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  broadcastToAdmins = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getAdminService();
      const { message, sender_id } = broadcastSchema.parse(req.body);

      const payload = {
        message,
        ...(sender_id ? { sender_id } : {}),
      };

      const results = await service.broadcastToAdmins(payload);

      res.status(201).json({
        message: `Notificaciones enviadas a ${results.length} administradores.`,
        notifications: results,
      });
    } catch (err) {
      return handleError(res, err);
    }
  };
}

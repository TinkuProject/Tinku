import { Request, Response } from "express";
import { CashoutRequestsDAO } from "../dao/cashout-requests.dao";
import { CashoutRequestsService } from "../services/cashout-requests.service";
import { getUserClientFromRequest, supabaseAdmin } from "../config/supabase-client.config";
import { handleError } from "../utils/handleError";
import { NotificationsDAO } from "../dao/notifications.dao";
import { NotificationsService } from "../services/notifications.service";
import {
  cashoutRequestIdSchema,
  cashoutRequestPaginationSchema,
  createCashoutRequestSchema,
  reviewCashoutRequestSchema,
} from "../validation/cashout-requests.validation";

export class CashoutRequestsController {
  private getService(req: Request): CashoutRequestsService {
    const db = getUserClientFromRequest(req);
    const dao = new CashoutRequestsDAO(db);
    const notificationsDao = new NotificationsDAO(supabaseAdmin);
    const notificationsService = new NotificationsService(notificationsDao);
    return new CashoutRequestsService(dao, notificationsService);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const input = createCashoutRequestSchema.parse(req.body);
      const result = await this.getService(req).create(userId, input);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const result = await this.getService(req).getMine(userId);
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const { limit = 50, offset = 0 } =
        cashoutRequestPaginationSchema.parse(req.query);

      const result = await this.getService(req).getAll(limit, offset);
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getPending = async (req: Request, res: Response): Promise<void> => {
    try {
      const result = await this.getService(req).getPending();
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = cashoutRequestIdSchema.parse(req.params);
      const result = await this.getService(req).getById(id);
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  approve = async (req: Request, res: Response): Promise<void> => {
    try {
      const adminId = req.user?.id;
      if (!adminId) throw new Error("Unauthorized");

      const { id } = cashoutRequestIdSchema.parse(req.params);
      const input = reviewCashoutRequestSchema.parse(req.body);

      const result = await this.getService(req).approve(id, adminId, input);
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  reject = async (req: Request, res: Response): Promise<void> => {
    try {
      const adminId = req.user?.id;
      if (!adminId) throw new Error("Unauthorized");

      const { id } = cashoutRequestIdSchema.parse(req.params);
      const input = reviewCashoutRequestSchema.parse(req.body);

      const result = await this.getService(req).reject(id, adminId, input);
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}

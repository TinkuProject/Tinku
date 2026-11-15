import { Request, Response } from "express";
import { PaymentRequestService } from "../services/payment-requests.service";
import { PaymentRequestDAO } from "../dao/payment-requests.dao";
import { PaymentsDAO } from "../dao/payments.dao";
import { MediaDAO } from "../dao/media.dao";
import { createPaymentRequestSchema, approvePaymentRequestSchema, rejectPaymentRequestSchema,
} from "../validation/payment-requests.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin,
} from "../config/supabase-client.config";
import { assertUser } from "../helper/role.helper";
import { NotificationsDAO } from "../dao/notifications.dao";
import { NotificationsService } from "../services/notifications.service";
import { PAYMENT_METHODS } from "../constants/enums.constants";

export class PaymentRequestsController {
  private getService(req: Request): PaymentRequestService {
    const db = getUserClientFromRequest(req);

    const dao = new PaymentRequestDAO(db);
    const paymentsDao = new PaymentsDAO(supabaseAdmin);
    const mediaDao = new MediaDAO(db);
    const notificationsDao = new NotificationsDAO(supabaseAdmin);
    const notificationsService = new NotificationsService(notificationsDao);

    return new PaymentRequestService(dao, paymentsDao, mediaDao, db, notificationsService);
  }

  // =========================
  // GET ALL (ADMIN)
  // =========================
  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const status = req.query.status as
        | "pending"
        | "approved"
        | "rejected"
        | undefined;
      const methodQuery = req.query.method;
      const paymentMethod =
        typeof methodQuery === "string" &&
        PAYMENT_METHODS.includes(methodQuery as any)
          ? (methodQuery as (typeof PAYMENT_METHODS)[number])
          : undefined;

      const service = this.getService(req);
      const result = await service.getAll(status, paymentMethod);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // GET BY ID (ADMIN)
  // =========================
  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const id = Number(req.params.id);

      const service = this.getService(req);
      const result = await service.getById(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // GET MINE (USER)
  // =========================
  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const service = this.getService(req);
      const result = await service.getMine(user.id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  hasPendingPartnerUpgrade = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const service = this.getService(req);
      const result = await service.hasPendingPartnerUpgrade(user.id);

      res.json({ hasPending: result });
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // CREATE
  // =========================
  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = createPaymentRequestSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(user.id, input);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // APPROVE
  // =========================
  approve = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = approvePaymentRequestSchema.parse({
        requestId: Number(req.params.id),
        ...req.body,
      });

      const service = this.getService(req);
      const result = await service.approve(user.id, input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // REJECT
  // =========================
  reject = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = rejectPaymentRequestSchema.parse({
        requestId: Number(req.params.id),
        ...req.body,
      });

      const service = this.getService(req);
      const result = await service.reject(user.id, input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}

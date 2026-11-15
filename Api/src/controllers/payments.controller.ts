import { Request, Response } from "express";
import { PaymentsService } from "../services/payments.service";
import { PaymentsDAO } from "../dao/payments.dao";
import {
  createPaymentSchema, paymentIdSchema,
} from "../validation/payments.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin } from "../config/supabase-client.config";
import { OwnershipService } from "../services/ownership.service";

export class PaymentsController {
  private getService(req: Request): PaymentsService {
    const db = getUserClientFromRequest(req);
    const dao = new PaymentsDAO(db);

    return new PaymentsService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const input = createPaymentSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(input, userId);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = paymentIdSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "payment",
        input.id,
        req.user!
      );

      const service = this.getService(req);
      const payment = await service.getById(input);

      res.json(payment);
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

  softDelete = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const input = paymentIdSchema.parse(req.params);

      const service = this.getService(req);
      const result = await service.softDelete(input, userId);

      res.status(200).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}

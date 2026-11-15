import { Request, Response } from "express";
import { SubscriptionPlansService } from "../services/subscription-plans.service";
import { SubscriptionPlansDAO } from "../dao/subscription-plans.dao";
import { createSubscriptionPlanSchema, updateSubscriptionPlanSchema,
  subscriptionPlanIdSchema } from "../validation/subscription-plans.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic } from "../config/supabase-client.config";

export class SubscriptionPlansController {
  private getService(req: Request): SubscriptionPlansService {
    const db = getUserClientFromRequest(req);
    const dao = new SubscriptionPlansDAO(db);
    return new SubscriptionPlansService(dao);
  }

  private getPublicService(): SubscriptionPlansService {
    const dao = new SubscriptionPlansDAO(supabasePublic);
    return new SubscriptionPlansService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = createSubscriptionPlanSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(input);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const data = await service.getAll();

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = subscriptionPlanIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getPublicService();
      const data = await service.getById(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = updateSubscriptionPlanSchema.parse({
        ...req.body,
        id: Number(req.params.id),
      });

      const service = this.getService(req);
      const result = await service.update(input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  softDelete = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = subscriptionPlanIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getService(req);
      const result = await service.softDelete(input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}
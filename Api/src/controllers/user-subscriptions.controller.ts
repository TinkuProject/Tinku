import { Request, Response } from "express";
import { UserSubscriptionsService } from "../services/user-subscriptions.service";
import { UserSubscriptionsDAO } from "../dao/user-subscriptions.dao";
import { SubscriptionPlansDAO } from "../dao/subscription-plans.dao";
import { createUserSubscriptionSchema, updateUserSubscriptionSchema, userSubscriptionIdSchema,
  userSubscriptionByUserSchema } from "../validation/user-subscriptions.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest } from "../config/supabase-client.config";

export class UserSubscriptionsController {
  private getService(req: Request): UserSubscriptionsService {
    const db = getUserClientFromRequest(req);

    const dao = new UserSubscriptionsDAO(db);
    const plansDao = new SubscriptionPlansDAO(db);

    return new UserSubscriptionsService(dao, plansDao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = createUserSubscriptionSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(input);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = await service.getAll();

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = userSubscriptionIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getService(req);
      const data = await service.getById(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByUser = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = userSubscriptionByUserSchema.parse({
        user_id: req.params.userId,
      });

      const service = this.getService(req);
      const data = await service.getByUser(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getCurrent = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      throw new Error("Unauthorized");
    }

    const userId = req.user.id;

    const input = userSubscriptionByUserSchema.parse({
      user_id: userId,
    });

    const service = this.getService(req);
    const data = await service.getCurrentByUser(input);

    if (!data) {
      res.status(204).send();
      return;
    }

    res.json(data);
  } catch (err) {
    return handleError(res, err);
  }
};

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = updateUserSubscriptionSchema.parse({
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

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = userSubscriptionIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getService(req);
      await service.delete(input);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  cancel = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = userSubscriptionIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getService(req);
      const result = await service.cancel(input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}
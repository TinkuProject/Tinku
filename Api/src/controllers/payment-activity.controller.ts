import { Request, Response } from "express";
import { PaymentActivityDAO } from "../dao/payment-activity.dao";
import { PaymentActivityService } from "../services/payment-activity.service";
import { handleError } from "../utils/handleError";
import { assertUser } from "../helper/role.helper";

export class PaymentActivityController {
  private getService(): PaymentActivityService {
    const dao = new PaymentActivityDAO();

    return new PaymentActivityService(dao);
  }

  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const limit = this.readBoundedNumber(req.query.limit, 20, 1, 100);
      const offset = this.readBoundedNumber(req.query.offset, 0, 0, 100000);

      const service = this.getService();
      const result = await service.getMine(user.id, limit, offset);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMinePage = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const limit = this.readBoundedNumber(req.query.limit, 20, 1, 100);
      const offset = this.readBoundedNumber(req.query.offset, 0, 0, 100000);
      const result = await this.getService().getMinePage(
        user.id,
        limit,
        offset
      );

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  private readBoundedNumber(
    value: unknown,
    fallback: number,
    min: number,
    max: number
  ): number {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) return fallback;
    return Math.min(Math.max(Math.trunc(parsed), min), max);
  }
}

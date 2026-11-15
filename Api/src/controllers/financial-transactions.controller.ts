import { Request, Response } from "express";
import { FinancialTransactionsService } from "../services/financial-transactions.service";
import { FinancialTransactionsDAO } from "../dao/financial-transactions.dao";
import { transactionFilterSchema, transactionIdSchema,
} from "../validation/financial-transactions.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin } from "../config/supabase-client.config";
import { OwnershipService } from "../services/ownership.service";

export class FinancialTransactionsController {
  private getService(req: Request): FinancialTransactionsService {
    const db = getUserClientFromRequest(req);
    const dao = new FinancialTransactionsDAO(db);

    return new FinancialTransactionsService(dao);
  }

  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const parsed = transactionFilterSchema.parse(req.query);
      const filters = Object.fromEntries(
        Object.entries(parsed).filter(([_, v]) => v !== undefined)
      );
      const service = this.getService(req);
      const data = await service.getByUser(userId, filters);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = transactionIdSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "financial_transaction",
        input.id,
        req.user!
      );

      const service = this.getService(req);
      const data = await service.getById(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getLatest = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const service = this.getService(req);
      const data = await service.getLatestByUser(userId);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };
}

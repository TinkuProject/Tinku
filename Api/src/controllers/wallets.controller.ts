import { Request, Response } from "express";
import { WalletsService } from "../services/wallets.service";
import { WalletsDAO } from "../dao/wallets.dao";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest } from "../config/supabase-client.config";

export class WalletsController {
  private getService(req: Request): WalletsService {
    const db = getUserClientFromRequest(req);
    const dao = new WalletsDAO(db);
    return new WalletsService(dao);
  }

  // ✔ SOLO MI WALLET
  getMyWallet = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      if (!user) throw new Error("Unauthorized");

      const service = this.getService(req);
      const wallet = await service.getByUser({
        user_id: user.id,
      });

      res.json(wallet);
    } catch (err) {
      return handleError(res, err);
    }
  };
}
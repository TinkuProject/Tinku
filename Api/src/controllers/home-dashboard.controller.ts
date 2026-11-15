import { Request, Response } from "express";
import { HomeDashboardDAO } from "../dao/home-dashboard.dao";
import { HomeDashboardService } from "../services/home-dashboard.service";
import { handleError } from "../utils/handleError";

export class HomeDashboardController {
  get = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id || !req.user.role) throw new Error("Unauthorized");
      const service = new HomeDashboardService(new HomeDashboardDAO());
      res.json(await service.get(req.user.id, req.user.role));
    } catch (error) {
      handleError(res, error);
    }
  };
}

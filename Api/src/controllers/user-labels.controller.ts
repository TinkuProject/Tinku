import { Request, Response } from "express";
import { UserLabelsService } from "../services/user-labels.service";
import { UserLabelsDAO } from "../dao/user-labels.dao";
import { assignUserLabelSchema, userLabelByUserSchema, userLabelParamsSchema,
} from "../validation/user-labels.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest } from "../config/supabase-client.config";

export class UserLabelsController {
  private getService(req: Request): UserLabelsService {
    const db = getUserClientFromRequest(req);
    const dao = new UserLabelsDAO(db);
    return new UserLabelsService(dao);
  }

  assign = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = assignUserLabelSchema.parse(req.body);

      const service = this.getService(req);
      await service.assign(input);

      res.status(201).json({
        message: "Label assigned to user",
      });
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByUser = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = userLabelByUserSchema.parse(req.params);

      const service = this.getService(req);
      const data = await service.getByUser(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMyLabels = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);

      const data = await service.getMyLabels();
      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = userLabelParamsSchema.parse(req.body);

      const service = this.getService(req);
      await service.remove(input);

      res.json({
        message: "Label removed from user",
      });
    } catch (err) {
      return handleError(res, err);
    }
  };
}
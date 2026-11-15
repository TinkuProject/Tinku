import { Request, Response } from "express";
import { UserVisitsService } from "../services/user-visits.service";
import { UserVisitsDAO } from "../dao/user-visits.dao";
import { userVisitCreateSchema, userVisitByEntitySchema,
  userVisitEntityCountsSchema,
} from "../validation/user-visits.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest } from "../config/supabase-client.config";

export class UserVisitsController {
  private getService(req: Request): UserVisitsService {
    const db = getUserClientFromRequest(req);
    const dao = new UserVisitsDAO(db);
    return new UserVisitsService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const user_id = req.user?.id;
      if (!user_id) throw new Error("Unauthorized");

      const input = userVisitCreateSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(user_id, input);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByUser = async (req: Request, res: Response): Promise<void> => {
    try {
      const user_id = req.user?.id;
      if (!user_id) throw new Error("Unauthorized");

      const service = this.getService(req);
      const result = await service.getByUser({ user_id });

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByEntity = async (req: Request, res: Response): Promise<void> => {
    try {
      const user_id = req.user?.id;
      if (!user_id) throw new Error("Unauthorized");

      const input = userVisitByEntitySchema.parse({
        entity_type: req.params.entityType,
        entity_id: Number(req.params.entityId),
      });

      const service = this.getService(req);
      const result = await service.getByEntity(user_id, input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  countByEntities = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = userVisitEntityCountsSchema.parse({
        entity_type: req.query.entity_type,
        ids: req.query.ids,
        type: req.query.type,
      });

      const service = this.getService(req);
      const result = await service.countByEntities(input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const user_id = req.user?.id;
      if (!user_id) throw new Error("Unauthorized");

      const input = userVisitByEntitySchema.parse({
        entity_type: req.params.entityType,
        entity_id: Number(req.params.entityId),
      });

      const service = this.getService(req);
      await service.delete(user_id, input.entity_type, input.entity_id);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };
}

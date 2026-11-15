import { Request, Response } from "express";
import { LabelPermissionsService } from "../services/label-permissions.service";
import { LabelPermissionsDAO } from "../dao/label-permissions.dao";
import { assignLabelPermissionSchema, labelIdParamSchema, labelPermissionParamsSchema
} from "../validation/label-permissions.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest } from "../config/supabase-client.config";

export class LabelPermissionsController {

  private getService(req: Request): LabelPermissionsService {
    const db = getUserClientFromRequest(req);
    const dao = new LabelPermissionsDAO(db);
    return new LabelPermissionsService(dao);
  }

  assign = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = assignLabelPermissionSchema.parse(req.body);

      await service.assign(data);

      res.status(201).json({
        message: "Permission assigned to label",
      });
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByLabel = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { label_id } = labelIdParamSchema.parse(req.params);

      const data = await service.getByLabel(label_id);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  removeAllByLabel = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const { label_id } = labelIdParamSchema.parse(req.params);

      await service.removeAllByLabel(label_id);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { label_id, permission_id } = labelPermissionParamsSchema.parse(req.params);

      await service.remove(label_id, permission_id);

      res.json({
        message: "Permission removed from label",
      });
    } catch (err) {
      return handleError(res, err);
    }
  };
}
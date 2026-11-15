import { Request, Response } from "express";
import { RolePermissionsService } from "../services/role-permissions.service";
import { RolePermissionsDAO } from "../dao/role-permissions.dao";
import { assignPermissionSchema, rolePermissionFilterSchema, removePermissionSchema,
} from "../validation/role-permissions.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest } from "../config/supabase-client.config";

export class RolePermissionsController {
  private getService(req: Request): RolePermissionsService {
    const db = getUserClientFromRequest(req);
    const dao = new RolePermissionsDAO(db);
    return new RolePermissionsService(dao);
  }

  assign = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = assignPermissionSchema.parse(req.body);

      const service = this.getService(req);
      await service.assign(input);

      res.status(201).json({
        message: "Permission assigned successfully",
      });
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByRole = async (req: Request, res: Response): Promise<void> => {
    try {
      const filter = rolePermissionFilterSchema.parse(req.params);

      const service = this.getService(req);
      const data = await service.getByRole(filter);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = removePermissionSchema.parse(req.params);

      const service = this.getService(req);
      await service.remove(input);

      res.json({
        message: "Permission removed successfully",
      });
    } catch (err) {
      return handleError(res, err);
    }
  };
}
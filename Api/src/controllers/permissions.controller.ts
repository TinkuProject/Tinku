import { Request, Response } from "express";
import { PermissionsService } from "../services/permissions.service";
import { PermissionsDAO } from "../dao/permissions.dao";
import { createPermissionSchema, updatePermissionSchema, idParamSchema, codeParamSchema,
} from "../validation/permissions.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest } from "../config/supabase-client.config";

export class PermissionsController {

  private getService(req: Request): PermissionsService {
    const db = getUserClientFromRequest(req);
    const dao = new PermissionsDAO(db);
    return new PermissionsService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = createPermissionSchema.parse(req.body);

      const result = await service.create(data);
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
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);

      const data = await service.getById(id);
      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByCode = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { code } = codeParamSchema.parse(req.params);

      const data = await service.getByCode(code);
      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMyPermissions = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = await service.getByCodes(req.user?.permissions ?? []);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);

      const rawData = updatePermissionSchema.parse(req.body);

      const data = Object.fromEntries(
        Object.entries(rawData).filter(([_, v]) => v !== undefined)
      );

      const updated = await service.update(id, data);
      res.json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);

      await service.delete(id);
      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };
}

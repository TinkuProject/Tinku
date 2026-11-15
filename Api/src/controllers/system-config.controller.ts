import { Request, Response } from "express";
import { SystemConfigService } from "../services/system-config.service";
import { SystemConfigDAO } from "../dao/system-config.dao";
import { keyParamSchema, updateConfigWithKeySchema } from "../validation/system-config.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic } from "../config/supabase-client.config";

export class SystemConfigController {
  private getService(req: Request): SystemConfigService {
    const db = req.user?.id ? getUserClientFromRequest(req) : supabasePublic;
    const dao = new SystemConfigDAO(db);
    return new SystemConfigService(dao);
  }

  private getPublicService(): SystemConfigService {
    const dao = new SystemConfigDAO(supabasePublic);
    return new SystemConfigService(dao);
  }


  get = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = keyParamSchema.parse(req.params);

      const service = this.getService(req);
      const config = await service.get(input);

      res.json(config);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getNumberByKey = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = keyParamSchema.parse(req.params);

      const service = this.getPublicService();
      const value = await service.getNumber(input.key);

      res.json({
        key: input.key,
        value,
      });
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const configs = await service.getAll();

      res.json(configs);
    } catch (err) {
      return handleError(res, err);
    }
  };


  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = updateConfigWithKeySchema.parse({
        ...req.body,
        key: req.params.key,
      });

      const service = this.getService(req);
      const updated = await service.upsert(input);

      res.json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };
}
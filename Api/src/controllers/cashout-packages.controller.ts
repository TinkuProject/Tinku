import { Request, Response } from "express";
import { CashoutPackagesService } from "../services/cashout-packages.service";
import { CashoutPackagesDAO } from "../dao/cashout-packages.dao";
import { createCashoutPackageSchema, updateCashoutPackageSchema, idParamSchema,
} from "../validation/cashout-packages.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic } from "../config/supabase-client.config";

export class CashoutPackagesController {

  private getService(req: Request): CashoutPackagesService {
    const supabase = getUserClientFromRequest(req);

    const dao = new CashoutPackagesDAO(supabase);
    return new CashoutPackagesService(dao);
  }

  private getPublicService(): CashoutPackagesService {
    const dao = new CashoutPackagesDAO(supabasePublic);
    return new CashoutPackagesService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = createCashoutPackageSchema.parse(req.body);
      const result = await service.create(data);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const data = await service.getAll();
      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAllAdmin = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = await service.getAllAdmin();
      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { id } = idParamSchema.parse(req.params);
      const data = await service.getById(id);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getActiveById = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { id } = idParamSchema.parse(req.params);
      const data = await service.getActiveById(id);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);
      const data = updateCashoutPackageSchema.parse(req.body);
      const updated = await service.update(id, data);

      res.json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };

  softDelete = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);
      const result = await service.softDelete(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  deactivate = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);
      const result = await service.deactivate(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  activate = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);
      const result = await service.activate(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}
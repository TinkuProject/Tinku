import { Request, Response } from "express";
import { CoinPackagesService } from "../services/coin-packages.service";
import { CoinPackagesDAO } from "../dao/coin-packages.dao";
import { createCoinPackageSchema, updateCoinPackageSchema, coinPackageIdParamSchema,
  coinPackageFilterSchema } from "../validation/coin-packages.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic } from "../config/supabase-client.config";

export class CoinPackagesController {

  private getService(req: Request): CoinPackagesService {
    const db = getUserClientFromRequest(req);
    const dao = new CoinPackagesDAO(db);
    return new CoinPackagesService(dao);
  }

  private getPublicService(): CoinPackagesService {
    const dao = new CoinPackagesDAO(supabasePublic);
    return new CoinPackagesService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = createCoinPackageSchema.parse(req.body);
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
      const { id } = coinPackageIdParamSchema.parse(req.params);
      const data = await service.getById(id);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getPartnerUpgradePackage = async (req: Request, res: Response): Promise<void> => {
  try {
    const service = this.getPublicService();

    const data = await service.getPartnerUpgradePackage();

    res.json(data);
  } catch (err) {
    return handleError(res, err);
  }
};

  getActiveById = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { id } = coinPackageIdParamSchema.parse(req.params);
      const data = await service.getActiveById(id);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = coinPackageIdParamSchema.parse(req.params);
      const rawData = updateCoinPackageSchema.parse(req.body);
      const data = Object.fromEntries(
        Object.entries(rawData).filter(([_, v]) => v !== undefined)
      );
      const updated = await service.update(id, data);

      res.json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };

  softDelete = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = coinPackageIdParamSchema.parse(req.params);
      const result = await service.softDelete(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  activate = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = coinPackageIdParamSchema.parse(req.params);
      const result = await service.activate(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  deactivate = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = coinPackageIdParamSchema.parse(req.params);
      const result = await service.deactivate(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByFilters = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const query = coinPackageFilterSchema.parse(req.query);
      const params = Object.fromEntries(
        Object.entries(query).filter(([_, v]) => v !== undefined)
      );
      const data = await service.getByFilters(params);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };
}
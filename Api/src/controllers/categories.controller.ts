import { Request, Response } from "express";
import { CategoriesService } from "../services/categories.service";
import { CategoriesDAO } from "../dao/categories.dao";
import { categoryCreateSchema, categoryUpdateSchema, idParamSchema,
  categoryFilterSchema } from "../validation/categories.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic } from "../config/supabase-client.config";

export class CategoriesController {

  private getService(req: Request): CategoriesService {
    const db = getUserClientFromRequest(req);
    const dao = new CategoriesDAO(db);
    return new CategoriesService(dao);
  }

  private getPublicService(): CategoriesService {
    const dao = new CategoriesDAO(supabasePublic);
    return new CategoriesService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = categoryCreateSchema.parse(req.body);
      const result = await service.create(data);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const result = await service.getAll();
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAllAdmin = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const result = await service.getAllAdmin();
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { id } = idParamSchema.parse(req.params);
      const result = await service.getById(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByIds = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();

      const idsParam = req.query.ids;

      if (!idsParam || typeof idsParam !== "string") {
        throw new Error("ids query param is required");
      }

      const ids = idsParam
        .split(",")
        .map((id) => Number(id))
        .filter((id) => !isNaN(id));

      if (ids.length === 0) {
        res.json([]);
        return;
      }

      const result = await service.getByIds(ids);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getActiveById = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { id } = idParamSchema.parse(req.params);
      const result = await service.getActiveById(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);
      const data = categoryUpdateSchema.parse(req.body);
      const result = await service.update(id, data);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  softDelete = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);
      await service.softDelete(id);
      const updated = await service.getById(id);

      res.json(updated);
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

  getActiveByType = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const query = categoryFilterSchema.parse(req.query);

      const result = await service.getActiveByType(
        query.entity_type!,
        query.business_type
      );

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByFilters = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const query = categoryFilterSchema.parse(req.query);
      const params = Object.fromEntries(
        Object.entries(query).filter(([_, v]) => v !== undefined)
      );

      const result = await service.getByFilters(params);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}
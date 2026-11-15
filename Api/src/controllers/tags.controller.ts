import { Request, Response } from "express";
import { TagsService } from "../services/tags.service";
import { TagsDAO } from "../dao/tags.dao";
import { tagCreateSchema, tagUpdateSchema, tagIdSchema,
} from "../validation/tags.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic } from "../config/supabase-client.config";

export class TagsController {
  private getService(req: Request): TagsService {
    const db = getUserClientFromRequest(req);
    const dao = new TagsDAO(db);
    return new TagsService(dao);
  }

  private getPublicService(): TagsService {
    const dao = new TagsDAO(supabasePublic);
    return new TagsService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = tagCreateSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(input);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAll = async (_: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const data = await service.getAll();

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = tagIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getPublicService();
      const data = await service.getById(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = tagUpdateSchema.parse({
        ...req.body,
        id: Number(req.params.id),
      });

      const service = this.getService(req);
      const result = await service.update(input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  softDelete = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = tagIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getService(req);
      const result = await service.softDelete(input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}
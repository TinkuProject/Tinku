import { Request, Response } from "express";
import { LabelsService } from "../services/labels.service";
import { LabelsDAO } from "../dao/labels.dao";
import { createLabelSchema, updateLabelSchema, labelIdParamSchema,
} from "../validation/labels.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest } from "../config/supabase-client.config";

export class LabelsController {

  private getService(req: Request): LabelsService {
    const db = getUserClientFromRequest(req);
    const dao = new LabelsDAO(db);
    return new LabelsService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = createLabelSchema.parse(req.body);
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
      const { id } = labelIdParamSchema.parse(req.params);
      const data = await service.getById(id);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = labelIdParamSchema.parse(req.params);

      const rawData = updateLabelSchema.parse(req.body);

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
      const { id } = labelIdParamSchema.parse(req.params);

      await service.delete(id);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };
}
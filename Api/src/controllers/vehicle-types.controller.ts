import { Request, Response } from "express";
import { VehicleTypesService } from "../services/vehicle-types.service";
import { VehicleTypesDAO } from "../dao/vehicle-types.dao";
import { vehicleTypeCreateSchema, vehicleTypeUpdateSchema, vehicleTypeIdSchema,
} from "../validation/vehicle-types.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic } from "../config/supabase-client.config";

export class VehicleTypesController {
  private getService(req: Request): VehicleTypesService {
    const db = getUserClientFromRequest(req);
    const dao = new VehicleTypesDAO(db);
    return new VehicleTypesService(dao);
  }

  private getPublicService(): VehicleTypesService {
    const dao = new VehicleTypesDAO(supabasePublic);
    return new VehicleTypesService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = vehicleTypeCreateSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(input);

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

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = vehicleTypeIdSchema.parse({
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
      const input = vehicleTypeUpdateSchema.parse({
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

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = vehicleTypeIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getService(req);
      await service.delete(input);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };
}
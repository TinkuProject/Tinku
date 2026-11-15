import { Request, Response } from "express";
import { ChargingPointsService } from "../services/charging-points.service";
import { ChargingPointsDAO } from "../dao/charging-points.dao";
import { createChargingPointSchema, updateChargingPointSchema,
  chargingPointIdParamSchema } from "../validation/charging-points.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic } from "../config/supabase-client.config";

export class ChargingPointsController {

  private getService(req: Request): ChargingPointsService {
    const db = getUserClientFromRequest(req);
    const dao = new ChargingPointsDAO(db);
    return new ChargingPointsService(dao);
  }

  private getPublicService(): ChargingPointsService {
    const dao = new ChargingPointsDAO(supabasePublic);
    return new ChargingPointsService(dao);
  }

  create = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);
      const data = createChargingPointSchema.parse(req.body);
      const result = await service.create(data);

      res.status(201).json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response) => {
    try {
      const service = this.getPublicService();
      const data = await service.getAll();

      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getActive = async (req: Request, res: Response) => {
    try {
      const service = this.getPublicService();
      const data = await service.getActive();

      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response) => {
    try {
      const service = this.getPublicService();
      const { id } = chargingPointIdParamSchema.parse(req.params);
      const data = await service.getById(id);

      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  update = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);
      const { id } = chargingPointIdParamSchema.parse(req.params);
      const rawData = updateChargingPointSchema.parse(req.body);
      const data = Object.fromEntries(
        Object.entries(rawData).filter(([_, v]) => v !== undefined)
      );
      const result = await service.update(id, data);

      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  softDelete = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);
      const { id } = chargingPointIdParamSchema.parse(req.params);
      const result = await service.softDelete(id);

      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };
}
import { Request, Response } from "express";
import { TransportLinesService } from "../services/transport-lines.service";
import { TransportLinesDAO } from "../dao/transport-lines.dao";
import {
  transportLineCreateSchema, transportLineUpdateSchema,
  transportLineIdSchema
} from "../validation/transport-lines.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";
import { EntityTransportRelationsDAO } from "../dao/entity-transport-relations.dao";
import { EntityTransportRelationsService } from "../services/entity-transport-relations.service";

export class TransportLinesController {
  private getService(req: Request): TransportLinesService {
    const db = getUserClientFromRequest(req);
    const dao = new TransportLinesDAO(db);
    const relationsDao = new EntityTransportRelationsDAO(supabaseAdmin);
    const relationsService = new EntityTransportRelationsService(relationsDao);
    return new TransportLinesService(dao, relationsService);
  }

  private getPublicService(): TransportLinesService {
    const dao = new TransportLinesDAO(supabasePublic);
    const relationsDao = new EntityTransportRelationsDAO(supabasePublic);
    const relationsService = new EntityTransportRelationsService(relationsDao);
    return new TransportLinesService(dao, relationsService);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = transportLineCreateSchema.parse(req.body);

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

  getActiveWithRoutes = async (_req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const data = await service.getActiveWithRoutes();

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = transportLineIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getPublicService();
      const data = await service.getById(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByIds = async (req: Request, res: Response): Promise<void> => {
    try {
      const idsParam = req.query.ids as string;

      if (!idsParam) {
        throw new Error("ids are required");
      }

      const ids = idsParam
        .split(",")
        .map((id) => Number(id))
        .filter((id) => !isNaN(id));

      if (!ids.length) {
        throw new Error("Invalid ids");
      }

      const service = this.getPublicService();
      const data = await service.getByIds(ids);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByVehicleType = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const vehicle_type_id = Number(req.params.vehicleTypeId);

      if (isNaN(vehicle_type_id)) {
        throw new Error("Invalid vehicleTypeId");
      }

      const service = this.getPublicService();
      const data = await service.getByVehicleType(vehicle_type_id);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = transportLineUpdateSchema.parse({
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
      const input = transportLineIdSchema.parse({
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

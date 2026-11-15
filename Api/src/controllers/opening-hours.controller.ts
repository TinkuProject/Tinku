import { Request, Response } from "express";
import { OpeningHoursService } from "../services/opening-hours.service";
import { OpeningHoursDAO } from "../dao/opening-hours.dao";
import { createOpeningHourSchema, updateOpeningHourSchema, openingEntityParamSchema,
  openingHoursReplaceAllSchema, idParamSchema, openingHoursEntitiesQuerySchema } from "../validation/opening-hours.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";
import { OwnershipService } from "../services/ownership.service";

export class OpeningHoursController {

  private getService(req: Request): OpeningHoursService {
    const db = getUserClientFromRequest(req);
    const dao = new OpeningHoursDAO(db);
    return new OpeningHoursService(dao);
  }

  private getPublicService(): OpeningHoursService {
    const dao = new OpeningHoursDAO(supabasePublic);
    return new OpeningHoursService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = createOpeningHourSchema.parse(req.body);
      await new OwnershipService(supabaseAdmin).validate(
        data.entity_type,
        data.entity_id,
        req.user!
      );

      const result = await service.create(data);
      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByEntity = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { entityType, entityId } = openingEntityParamSchema.parse(
        req.params
      );

      const data = await service.getByEntity(entityType, entityId);
      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByEntities = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { entity_type, entity_ids } = openingHoursEntitiesQuerySchema.parse({
        entity_type: req.query.entity_type,
        entity_ids: req.query.entity_ids,
      });

      const data = await service.getByEntities(entity_type, entity_ids);
      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  deleteByEntity = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const { entityType, entityId } = openingEntityParamSchema.parse(
        req.params
      );
      await new OwnershipService(supabaseAdmin).validate(
        entityType,
        entityId,
        req.user!
      );

      await service.deleteByEntity(entityType, entityId);

      res.status(204).send();
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

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "opening_hour",
        id,
        req.user!
      );

      const rawData = updateOpeningHourSchema.parse(req.body);

      const data = Object.fromEntries(
        Object.entries(rawData).filter(([_, v]) => v !== undefined)
      );

      const result = await service.update(id, data);
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "opening_hour",
        id,
        req.user!
      );

      await service.delete(id);
      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  replaceAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { entityType, entityId } = openingEntityParamSchema.parse(
        req.params
      );
      await new OwnershipService(supabaseAdmin).validate(
        entityType,
        entityId,
        req.user!
      );

      const data = openingHoursReplaceAllSchema.parse(req.body);

      const result = await service.replaceAll(
        entityType,
        entityId,
        data
      );

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}

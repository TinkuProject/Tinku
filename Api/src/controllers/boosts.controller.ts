import { Request, Response } from "express";
import { BoostsService } from "../services/boosts.service";
import { BoostsDAO } from "../dao/boosts.dao";
import { boostCreateSchema, boostUpdateSchema, boostIdParamSchema, paginationSchema,
  boostByEntitySchema } from "../validation/boosts.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";
import { OwnershipService } from "../services/ownership.service";
import { BusinessesDAO } from "../dao/businesses.dao";

export class BoostsController {

  private getService(req: Request): BoostsService {
    const db = getUserClientFromRequest(req);
    const dao = new BoostsDAO(db);
    return new BoostsService(dao);
  }

  private getPublicService(): BoostsService {
    const dao = new BoostsDAO(supabasePublic);
    return new BoostsService(dao);
  }

  create = async (req: Request, res: Response) => {
  try {
    const service = this.getService(req);

    const data = boostCreateSchema.parse(req.body);
    await new OwnershipService(supabaseAdmin).validate(
      data.entity_type,
      data.entity_id,
      req.user!
    );
    const result = await service.create(data, req.user);

    res.status(201).json(result);
  } catch (err) {
    handleError(res, err);
  }
};

  getAll = async (req: Request, res: Response) => {
    try {
      const service = this.getPublicService();
      const { limit = 50, offset = 0 } = paginationSchema.parse(req.query);
      const result = await service.getAll(limit, offset);

      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response) => {
    try {
      const service = this.getPublicService();
      const { id } = boostIdParamSchema.parse(req.params);
      const result = await service.getById(id);

      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getActive = async (req: Request, res: Response) => {
    try {
      const service = this.getPublicService();

      const result = await service.getActive();
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getByEntity = async (req: Request, res: Response) => {
    try {
      const service = this.getPublicService();

      const { entityType, entityId } = boostByEntitySchema.parse(req.params);

      const result = await service.getByEntity(
        entityType,
        entityId
      );

      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  update = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);

      const { id } = boostIdParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "boost",
        id,
        req.user!
      );
      const data = boostUpdateSchema.parse(req.body);
      const result = await service.update(id, data, req.user!);

      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getMine = async (req: Request, res: Response) => {
    try {
      const boostService = this.getService(req);
      const db = getUserClientFromRequest(req);
      const businessesDao = new BusinessesDAO(db);

      const { limit = 50, offset = 0 } = paginationSchema.parse(req.query);
      const userId = req.user?.id;

      if (!userId) {
        throw new Error("Unauthorized");
      }

      const businessIds = await businessesDao.findIdsByOwner(userId);

      const result = await boostService.getMineByBusinessIds(
        businessIds,
        limit,
        offset
      );

      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getPromotableBusinesses = async (req: Request, res: Response) => {
    try {
      const boostService = this.getService(req);
      const db = getUserClientFromRequest(req);
      const businessesDao = new BusinessesDAO(db);

      const result = await boostService.getPromotableBusinesses(
        businessesDao,
        req.user?.id
      );

      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  softDelete = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);

      const { id } = boostIdParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "boost",
        id,
        req.user!
      );
      const result = await service.softDelete(id);

      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };
}

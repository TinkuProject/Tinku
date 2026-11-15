import { Request, Response } from "express";
import { DiscountsService } from "../services/discounts.service";
import { DiscountsDAO } from "../dao/discounts.dao";
import { discountCreateSchema,discountUpdateSchema, discountIdParamSchema, 
  businessIdParamSchema, discountBusinessesQuerySchema } from "../validation/discounts.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";
import { OwnershipService } from "../services/ownership.service";

export class DiscountsController {

  private getService(req: Request): DiscountsService {
    const db = getUserClientFromRequest(req);
    const dao = new DiscountsDAO(db);
    return new DiscountsService(dao);
  }

  private getPublicService(): DiscountsService {
    const dao = new DiscountsDAO(supabasePublic);
    return new DiscountsService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = discountCreateSchema.parse(req.body);
      await new OwnershipService(supabaseAdmin).validate(
        "business",
        data.business_id,
        req.user!
      );
      const result = await service.create(data, req.user);

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
      const service = this.getPublicService();
      const { id } = discountIdParamSchema.parse(req.params);
      const data = await service.getById(id);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      if (!req.user?.id) {
        throw new Error("Unauthorized");
      }

      const service = this.getService(req);
      const data = await service.getMine(req.user.id);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByBusinessId = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { businessId } = businessIdParamSchema.parse(req.params);
      const data = await service.getByBusinessId(businessId);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByBusinesses = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { business_ids, active } = discountBusinessesQuerySchema.parse({
        business_ids: req.query.business_ids,
        active: req.query.active,
      });

      const data = await service.getByBusinessIds(business_ids, active);
      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getActive = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const data = await service.getActive();

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getActiveByBusinessId = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { businessId } = businessIdParamSchema.parse(req.params);
      const data = await service.getActiveByBusinessId(businessId);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = discountIdParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "discount",
        id,
        req.user!
      );

      const rawData = discountUpdateSchema.parse(req.body);

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
      const { id } = discountIdParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "discount",
        id,
        req.user!
      );

      const updated = await service.softDelete(id);

      res.status(200).json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };
}

import { Request, Response } from "express";
import { ProductsService } from "../services/products.service";
import { ProductsDAO } from "../dao/products.dao";
import {
  productCreateSchema, productUpdateSchema, idParamSchema, businessParamSchema,
  productsBusinessesQuerySchema
} from "../validation/products.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";
import { OwnershipService } from "../services/ownership.service";
import { isPrivileged } from "../helper/role.helper";

export class ProductsController {
  private getService(req: Request): ProductsService {
    const db = getUserClientFromRequest(req);
    const dao = new ProductsDAO(db);
    return new ProductsService(dao);
  }

  private getPublicService(): ProductsService {
    const dao = new ProductsDAO(supabasePublic);
    return new ProductsService(dao);
  }

  private parseBusinessesQuery(req: Request) {
    return productsBusinessesQuerySchema.parse({
      business_ids: req.query.business_ids,
    });
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = productCreateSchema.parse(req.body);
      await new OwnershipService(supabaseAdmin).validate(
        "business",
        data.business_id,
        req.user!
      );

      const result = await service.create(data);
      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const result = privileged
        ? await service.getAll()
        : await service.getActive();

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAllAdmin = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const result = await service.getAll();

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const { id } = idParamSchema.parse(req.params);

      const result = privileged
        ? await service.getById(id)
        : await service.getPublicById(id);
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByBusiness = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const { businessId } = businessParamSchema.parse(req.params);

      const result = privileged
        ? await service.getByBusinessAdmin(businessId)
        : await service.getByBusiness(businessId);
      res.json(result);
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

  getByBusinesses = async (req: Request, res: Response): Promise<void> => {
    try {
      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const validated = this.parseBusinessesQuery(req);

      const result = privileged
        ? await service.getByBusinessesAdmin(validated.business_ids)
        : await service.getByBusinesses(validated.business_ids);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByBusinessAdmin = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const { businessId } = businessParamSchema.parse(req.params);

      const result = await service.getByBusinessAdmin(
        businessId
      );
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = idParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "product",
        id,
        req.user!
      );

      const rawData = productUpdateSchema.parse(req.body);

      const data = Object.fromEntries(
        Object.entries(rawData).filter(([_, v]) => v !== undefined)
      );

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
      await new OwnershipService(supabaseAdmin).validate(
        "product",
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

import { Request, Response } from "express";
import { CertificationsService } from "../services/certifications.service";
import { CertificationsDAO } from "../dao/certifications.dao";
import { createCertificationSchema, updateCertificationSchema, 
  certificationIdParamSchema, certificationByBusinessSchema,
  certificationFilterSchema,
  certificationBusinessesQuerySchema } from "../validation/certifications.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";
import { OwnershipService } from "../services/ownership.service";
import { isPrivileged } from "../helper/role.helper";

export class CertificationsController {

  private getService(req: Request): CertificationsService {
    const db = getUserClientFromRequest(req);
    const dao = new CertificationsDAO(db);
    return new CertificationsService(dao);
  }

  private getPublicService(): CertificationsService {
    const dao = new CertificationsDAO(supabasePublic);
    return new CertificationsService(dao);
  }

  create = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);
      const data = createCertificationSchema.parse(req.body);
      await new OwnershipService(supabaseAdmin).validate(
        "business",
        data.business_id,
        req.user!
      );
      const result = await service.create(data);

      res.status(201).json(result);
    } catch (err) {
      handleError(res, err, req);
    }
  };

  getAll = async (req: Request, res: Response) => {
    try {
      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const data = await service.getAll(privileged);

      res.json(data);
    } catch (err) {
      handleError(res, err, req);
    }
  };

  getById = async (req: Request, res: Response) => {
    try {
      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const { id } = certificationIdParamSchema.parse(req.params);
      const data = await service.getById(id, privileged);

      res.json(data);
    } catch (err) {
      handleError(res, err, req);
    }
  };

  getByBusiness = async (req: Request, res: Response) => {
    try {
      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const { businessId } = certificationByBusinessSchema.parse(req.params);
      const data = privileged
        ? await service.getByBusinessAdmin(businessId)
        : await service.getByBusiness(businessId);

      res.json(data);
    } catch (err) {
      handleError(res, err, req);
    }
  };

  getByBusinesses = async (req: Request, res: Response) => {
    try {
      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const { business_ids } = certificationBusinessesQuerySchema.parse(req.query);
      const data = privileged
        ? await service.getByBusinessesAdmin(business_ids)
        : await service.getByBusinesses(business_ids);

      res.json(data);
    } catch (err) {
      handleError(res, err, req);
    }
  };

  update = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);
      const { id } = certificationIdParamSchema.parse(req.params);
      await new OwnershipService(supabaseAdmin).validate(
        "certification",
        id,
        req.user!
      );
      const data = updateCertificationSchema.parse(req.body);
      const result = await service.update(id, data);

      res.json(result);
    } catch (err) {
      handleError(res, err, req);
    }
  };

  softDelete = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);
      const { id } = certificationIdParamSchema.parse(req.params);
      const result = await service.softDelete(id);

      res.json(result);
    } catch (err) {
      handleError(res, err, req);
    }
  };

  activate = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);
      const { id } = certificationIdParamSchema.parse(req.params);
      const result = await service.activate(id);

      res.json(result);
    } catch (err) {
      handleError(res, err, req);
    }
  };

  deactivate = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);
      const { id } = certificationIdParamSchema.parse(req.params);
      const result = await service.deactivate(id);

      res.json(result);
    } catch (err) {
      handleError(res, err, req);
    }
  };

  getByFilters = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req);
      const query = certificationFilterSchema.parse(req.query);
      const params = Object.fromEntries(
        Object.entries(query).filter(([_, v]) => v !== undefined)
      );
      const result = await service.getByFilters(params);

      res.json(result);
    } catch (err) {
      handleError(res, err, req);
    }
  };
}

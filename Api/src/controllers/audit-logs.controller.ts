import { Request, Response } from "express";
import { AuditLogsService } from "../services/audit-logs.service";
import { AuditLogsDAO } from "../dao/audit-logs.dao";
import { handleError } from "../utils/handleError";
import { auditLogFilterSchema, auditLogByUserSchema, auditLogByEntitySchema,
  auditLogIdParamSchema, paginationSchema
} from "../validation/audit-logs.validation";
import { getUserClientFromRequest } from "../config/supabase-client.config";
import { isPrivileged } from "../helper/role.helper";

export class AuditLogsController {

  private getService(req: Request): AuditLogsService {
    const supabase = getUserClientFromRequest(req);
    const dao = new AuditLogsDAO(supabase);
    return new AuditLogsService(dao);
  }

  private ensureAdmin(req: Request, res: Response): boolean {
    if (!req.user || !isPrivileged(req.user.role)) {
      res.status(403).json({ message: "Forbidden" });
      return false;
    }
    return true;
  }

  getAll = async (req: Request, res: Response) => {
    try {
      if (!this.ensureAdmin(req, res)) return;

      const service = this.getService(req);
      const { limit = 50, offset = 0 } = paginationSchema.parse(req.query);
      const data = await service.getAll(limit, offset);

      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response) => {
    try {
      if (!this.ensureAdmin(req, res)) return;

      const service = this.getService(req);
      const { id } = auditLogIdParamSchema.parse(req.params);
      const data = await service.getById(id);

      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getByUser = async (req: Request, res: Response) => {
    try {
      if (!this.ensureAdmin(req, res)) return;

      const service = this.getService(req);

      const query = auditLogByUserSchema.parse({
        user_id: req.params.userId,
        limit: req.query.limit,
        offset: req.query.offset,
      });

      const data = await service.getByUser(
        query.user_id,
        query.limit,
        query.offset
      );

      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getByEntity = async (req: Request, res: Response) => {
    try {
      if (!this.ensureAdmin(req, res)) return;

      const service = this.getService(req);

      const params = auditLogByEntitySchema.parse({
        entity_type: req.params.entityType,
        entity_id: req.params.entityId,
      });

      const data = await service.getByEntity(
        params.entity_type,
        params.entity_id
      );

      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getByFilters = async (req: Request, res: Response) => {
    try {
      if (!this.ensureAdmin(req, res)) return;

      const service = this.getService(req);
      const query = auditLogFilterSchema.parse(req.query);

      const params = Object.fromEntries(
        Object.entries(query).filter(([_, v]) => v !== undefined)
      );

      const data = await service.getByFilters(params);

      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };
}

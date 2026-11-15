import { Request, Response } from "express";
import { v4 as uuidv4 } from "uuid";
import { BusinessClaimRequestsService } from "../services/business-claim-requests.service";
import { BusinessesDAO } from "../dao/businesses.dao";
import { BusinessClaimRequestsDAO } from "../dao/business-claim-requests.dao";
import { AuditLogsDAO } from "../dao/audit-logs.dao";
import { NotificationsDAO } from "../dao/notifications.dao";
import { NotificationsService } from "../services/notifications.service";
import { createBusinessClaimRequestSchema, reviewBusinessClaimRequestSchema,
  businessClaimRequestIdParamSchema, businessClaimRequestPaginationSchema, businessClaimRequestByBusinessSchema,
} from "../validation/business-claim-requests.validation";
import { handleError } from "../utils/handleError";
import {
  getUserClientFromRequest,
  supabaseAdmin,
} from "../config/supabase-client.config";
import { processFile } from "../utils/fileProcessor";
import { StorageService } from "../services/storage.service";

export class BusinessClaimRequestsController {

  private getService(req: Request, useAdmin = false): BusinessClaimRequestsService {
    const db = useAdmin
      ? supabaseAdmin
      : getUserClientFromRequest(req);

    const claimDao = new BusinessClaimRequestsDAO(db);
    const businessDao = new BusinessesDAO(db);
    const auditDao = new AuditLogsDAO(supabaseAdmin);
    const notificationsDao = new NotificationsDAO(supabaseAdmin);
    const notificationsService = new NotificationsService(notificationsDao);

    return new BusinessClaimRequestsService(
      claimDao,
      businessDao,
      auditDao,
      notificationsService
    );
  }

  // =============================
  // CREATE (partner)
  // =============================

  create = async (req: Request, res: Response) => {
    try {
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const service = this.getService(req);
      const data = createBusinessClaimRequestSchema.parse(req.body);

      const result = await service.create(req.user.id, data);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  uploadDocuments = async (req: Request, res: Response) => {
    const uploadedPaths: string[] = [];

    try {
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const files = req.files as Express.Multer.File[];

      if (!files || files.length === 0) {
        return res.status(400).json({ message: "No files uploaded" });
      }

      const urls: string[] = [];

      for (const file of files) {
        const processed = await processFile(file);
        const fileName = `${uuidv4()}.${processed.extension}`;
        const filePath = `business_claim_requests/${req.user.id}/${fileName}`;
        const url = await StorageService.uploadFile({
          filePath,
          buffer: processed.buffer,
          contentType: processed.contentType,
          isPublic: false,
        });

        uploadedPaths.push(filePath);
        urls.push(url);
      }

      return res.status(201).json({ urls });
    } catch (err) {
      if (uploadedPaths.length > 0) {
        await Promise.all(
          uploadedPaths.map((path) => StorageService.deleteFile(path))
        );
      }

      return handleError(res, err, req);
    }
  };

  // =============================
  // REVIEW (admin/master)
  // =============================

  review = async (req: Request, res: Response) => {
    try {
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const service = this.getService(req, true);
      const { id } = businessClaimRequestIdParamSchema.parse(req.params);
      const data = reviewBusinessClaimRequestSchema.parse(req.body);

      const result = await service.review(
        id,
        req.user.id,
        data
      );

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =============================
  // ADMIN
  // =============================

  getAll = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req, true);

      const { limit = 50, offset = 0 } =
        businessClaimRequestPaginationSchema.parse(req.query);

      const result = await service.getAll(limit, offset);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getPending = async (req: Request, res: Response) => {
    try {
      const service = this.getService(req, true);
      const result = await service.getPending();

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =============================
  // USER
  // =============================

  getMyRequests = async (req: Request, res: Response) => {
    try {
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const service = this.getService(req);

      const { limit = 50, offset = 0 } =
        businessClaimRequestPaginationSchema.parse(req.query);

      const result = await service.getByUser(
        req.user.id,
        limit,
        offset
      );

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =============================
  // BUSINESS
  // =============================

  getByBusiness = async (req: Request, res: Response) => {
    try {
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const service = this.getService(req);

      const { businessId, limit = 50, offset = 0 } =
        businessClaimRequestByBusinessSchema.parse({
          ...req.params,
          ...req.query,
        });

      const result = await service.getByBusiness(
        businessId,
        limit,
        offset,
        req.user
      );

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =============================
  // GENERAL
  // =============================

  getById = async (req: Request, res: Response) => {
    try {
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const service = this.getService(req, true);

      const { id } = businessClaimRequestIdParamSchema.parse(req.params);
      const result = await service.getById(id, req.user);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}

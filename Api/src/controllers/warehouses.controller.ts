import { Request, Response } from "express";
import { WarehousesDAO } from "../dao/warehouses.dao";
import { NotificationsDAO } from "../dao/notifications.dao";
import { WarehousesService } from "../services/warehouses.service";
import { NotificationsService } from "../services/notifications.service";
import { handleError } from "../utils/handleError";
import { supabaseAdmin } from "../config/supabase-client.config";
import {
  businessFulfillmentParamSchema,
  businessFulfillmentSchema,
  warehouseCreateSchema,
  warehouseInventoryIdParamSchema,
  warehouseInventoryLocationSchema,
  warehouseIdParamSchema,
  warehouseInventoryUpsertSchema,
  warehouseListQuerySchema,
  warehouseLocationCreateSchema,
  warehouseLocationIdParamSchema,
  warehouseLocationUpdateSchema,
  warehouseModerationSchema,
  warehouseRejectSchema,
  warehouseStockRequestApproveSchema,
  warehouseStockRequestCreateSchema,
  warehouseStockRequestIdParamSchema,
  warehouseStockRequestQuerySchema,
  warehouseStockRequestReceiveSchema,
  warehouseStockRequestRejectSchema,
  warehouseStatusSchema,
  warehouseUpdateSchema,
} from "../validation/warehouses.validation";

export class WarehousesController {
  private getService() {
    return new WarehousesService(
      new WarehousesDAO(),
      new NotificationsService(new NotificationsDAO(supabaseAdmin))
    );
  }

  getActive = async (_req: Request, res: Response) => {
    try {
      const data = await this.getService().getActive();
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getMine = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const data = await this.getService().getMine(req.user.id);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response) => {
    try {
      const query = warehouseListQuerySchema.parse(req.query);
      const data = await this.getService().getAll(query.status);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response) => {
    try {
      const { id } = warehouseIdParamSchema.parse(req.params);
      const data = await this.getService().getById(id);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  create = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const data = warehouseCreateSchema.parse(req.body);
      const result = await this.getService().create(data, req.user);
      res.status(201).json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  update = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const data = warehouseUpdateSchema.parse(req.body);
      const result = await this.getService().update(id, data, req.user);
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  updateStatus = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const data = warehouseStatusSchema.parse(req.body);
      const result = await this.getService().update(id, data, req.user);
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  approve = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const { message } = warehouseModerationSchema.parse(req.body);
      const result = await this.getService().approve(id, req.user, message);
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  reject = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const { message } = warehouseRejectSchema.parse(req.body);
      const result = await this.getService().reject(id, req.user, message);
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getInventory = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const data = await this.getService().listInventory(id, req.user);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getProductHistory = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const data = await this.getService().listProductHistory(id, req.user);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  upsertInventory = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const data = warehouseInventoryUpsertSchema.parse(req.body);
      const result = await this.getService().upsertInventory(id, data, req.user);
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getLocations = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const data = await this.getService().listLocations(id, req.user);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  createLocation = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const data = warehouseLocationCreateSchema.parse(req.body);
      const result = await this.getService().createLocation(id, data, req.user);
      res.status(201).json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  updateLocation = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const { locationId } = warehouseLocationIdParamSchema.parse(req.params);
      const data = warehouseLocationUpdateSchema.parse(req.body);
      const result = await this.getService().updateLocation(
        id,
        locationId,
        data,
        req.user
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  deleteLocation = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const { locationId } = warehouseLocationIdParamSchema.parse(req.params);
      const result = await this.getService().archiveLocation(
        id,
        locationId,
        req.user
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  setInventoryLocation = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = warehouseIdParamSchema.parse(req.params);
      const { inventoryId } = warehouseInventoryIdParamSchema.parse(req.params);
      const data = warehouseInventoryLocationSchema.parse(req.body);
      const result = await this.getService().setInventoryLocation(
        id,
        inventoryId,
        data,
        req.user
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  createStockRequest = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const data = warehouseStockRequestCreateSchema.parse(req.body);
      const result = await this.getService().createStockRequest(data, req.user);
      res.status(201).json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getReceivedStockRequests = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { status } = warehouseStockRequestQuerySchema.parse(req.query);
      const data = await this.getService().listReceivedStockRequests(
        req.user,
        status
      );
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getSentStockRequests = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { status } = warehouseStockRequestQuerySchema.parse(req.query);
      const data = await this.getService().listSentStockRequests(
        req.user,
        status
      );
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  approveStockRequest = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { requestId } = warehouseStockRequestIdParamSchema.parse(req.params);
      const data = warehouseStockRequestApproveSchema.parse(req.body);
      const result = await this.getService().approveStockRequest(
        requestId,
        req.user,
        data
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  markStockRequestSent = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { requestId } = warehouseStockRequestIdParamSchema.parse(req.params);
      const result = await this.getService().markStockRequestSent(
        requestId,
        req.user
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  receiveStockRequest = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { requestId } = warehouseStockRequestIdParamSchema.parse(req.params);
      const data = warehouseStockRequestReceiveSchema.parse(req.body);
      const result = await this.getService().receiveStockRequest(
        requestId,
        req.user,
        data
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  rejectStockRequest = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { requestId } = warehouseStockRequestIdParamSchema.parse(req.params);
      const { message } = warehouseStockRequestRejectSchema.parse(req.body);
      const result = await this.getService().rejectStockRequest(
        requestId,
        message,
        req.user
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getBusinessFulfillment = async (req: Request, res: Response) => {
    try {
      const { businessId } = businessFulfillmentParamSchema.parse(req.params);
      const data = await this.getService().getBusinessFulfillment(businessId);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  setBusinessFulfillment = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { businessId } = businessFulfillmentParamSchema.parse(req.params);
      const data = businessFulfillmentSchema.parse(req.body);
      const result = await this.getService().setBusinessFulfillment(
        businessId,
        data,
        req.user
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };
}

import { Request, Response } from "express";
import { MarketplaceDAO } from "../dao/marketplace.dao";
import { MarketplaceService } from "../services/marketplace.service";
import { NotificationsDAO } from "../dao/notifications.dao";
import { NotificationsService } from "../services/notifications.service";
import { supabaseAdmin } from "../config/supabase-client.config";
import { handleError } from "../utils/handleError";
import {
  businessParamSchema,
  businessViewBatchQuerySchema,
  deliveryStatusSchema,
  idParamSchema,
  marketplaceAdminListQuerySchema,
  marketplaceListQuerySchema,
  marketplaceOrderCreateSchema,
  marketplaceOrderListQuerySchema,
  marketplaceOrderRejectionSchema,
  marketplaceOrderStatusSchema,
  marketplacePickupValidationSchema,
  publicationCreateSchema,
  publicationStatusUpdateSchema,
  publicationStockUpdateSchema,
} from "../validation/marketplace.validation";

export class MarketplaceController {
  private getService() {
    return new MarketplaceService(
      new MarketplaceDAO(),
      new NotificationsService(new NotificationsDAO(supabaseAdmin))
    );
  }

  listPublic = async (req: Request, res: Response) => {
    try {
      const filters = marketplaceListQuerySchema.parse(req.query);
      const data = await this.getService().listPublic(filters);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  listMine = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const filters = marketplaceListQuerySchema.parse(req.query);
      const data = await this.getService().listMine(req.user.id, filters);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  listAdmin = async (req: Request, res: Response) => {
    try {
      const filters = marketplaceAdminListQuerySchema.parse(req.query);
      const data = await this.getService().listAdmin(filters);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getPublicationById = async (req: Request, res: Response) => {
    try {
      const { id } = idParamSchema.parse(req.params);
      const data = await this.getService().getPublicationById(id);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  createPublication = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const data = publicationCreateSchema.parse(req.body);
      const result = await this.getService().createPublication(
        req.user,
        data.product_id,
        data.published_stock,
        undefined,
        data.unit_tinku_price,
        data.payment_mode
      );
      res.status(201).json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  estimatePublication = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const data = publicationCreateSchema.parse(req.body);
      const result = await this.getService().estimatePublication(
        req.user,
        data.published_stock,
        undefined,
        data.unit_tinku_price,
        data.payment_mode
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  updatePublicationStock = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = idParamSchema.parse(req.params);
      const data = publicationStockUpdateSchema.parse(req.body);
      const result = await this.getService().updatePublicationStock(
        req.user,
        id,
        data.published_stock,
        undefined,
        data.unit_tinku_price,
        data.payment_mode
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  updatePublicationStatus = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = idParamSchema.parse(req.params);
      const data = publicationStatusUpdateSchema.parse(req.body);
      const result = await this.getService().updatePublicationStatus(
        id,
        data.status,
        req.user
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  publicationHistory = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = idParamSchema.parse(req.params);
      const data = await this.getService().publicationHistory(id, req.user);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  createOrder = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const data = marketplaceOrderCreateSchema.parse(req.body);
      const result = await this.getService().createOrder(req.user.id, data);
      res.status(201).json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  getOrderById = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = idParamSchema.parse(req.params);
      const data = await this.getService().getOrderById(id, req.user);
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  listMyOrders = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const filters = marketplaceOrderListQuerySchema.parse(req.query);
      const data = await this.getService().listMyOrders(
        req.user.id,
        filters.limit,
        filters.offset
      );
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  listAdminOrders = async (req: Request, res: Response) => {
    try {
      const filters = marketplaceOrderListQuerySchema.parse(req.query);
      const data = await this.getService().listAdminOrders(
        filters.status,
        filters.limit,
        filters.offset
      );
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  listSalesOrders = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const filters = marketplaceOrderListQuerySchema.parse(req.query);
      const data = await this.getService().listSalesOrders(
        req.user.id,
        filters.status,
        filters.limit,
        filters.offset
      );
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  listWarehouseOrders = async (req: Request, res: Response) => {
    try {
      const filters = marketplaceOrderListQuerySchema.parse(req.query);
      res.json(await this.getService().listWarehouseOrders(req.user!.id, filters.limit, filters.offset));
    } catch (error) { handleError(res, error, req); }
  };

  markWarehouseOrderReady = async (req: Request, res: Response) => {
    try {
      const { id } = idParamSchema.parse(req.params);
      res.json(await this.getService().markWarehouseOrderReady(id, req.user!));
    } catch (error) { handleError(res, error, req); }
  };

  updateSalesOrderStatus = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = idParamSchema.parse(req.params);
      const data = marketplaceOrderStatusSchema.parse(req.body);
      const result = await this.getService().updateSalesOrderStatus(
        id,
        data.status,
        req.user
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  rejectSalesOrder = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = idParamSchema.parse(req.params);
      const { reason } = marketplaceOrderRejectionSchema.parse(req.body);
      const result = await this.getService().rejectSalesOrder(
        id,
        reason,
        req.user
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  updateOrderStatus = async (req: Request, res: Response) => {
    try {
      const { id } = idParamSchema.parse(req.params);
      const data = marketplaceOrderStatusSchema.parse(req.body);
      const result = await this.getService().updateOrderStatus(id, data.status);
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  cancelOrder = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { id } = idParamSchema.parse(req.params);
      const result = await this.getService().cancelOrder(
        id,
        req.user.id
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  validatePickupCode = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const data = marketplacePickupValidationSchema.parse(req.body);
      const result = await this.getService().validatePickupCode(
        data.code,
        req.user
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  updateDeliveryStatus = async (req: Request, res: Response) => {
    try {
      const { id } = idParamSchema.parse(req.params);
      const data = deliveryStatusSchema.parse(req.body);
      const result = await this.getService().updateDeliveryStatus(
        id,
        data.status
      );
      res.json(result);
    } catch (err) {
      handleError(res, err);
    }
  };

  registerBusinessView = async (req: Request, res: Response) => {
    try {
      const { businessId } = businessParamSchema.parse(req.params);
      await this.getService().registerBusinessView(businessId, req.user);
      res.status(204).send();
    } catch (err) {
      handleError(res, err);
    }
  };

  getBusinessViewStatsBatch = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { ids } = businessViewBatchQuerySchema.parse(req.query);
      const data = await this.getService().getBusinessViewStatsBatch(
        ids,
        req.user
      );
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };

  getBusinessViewStats = async (req: Request, res: Response) => {
    try {
      if (!req.user?.id) throw new Error("Unauthorized");
      const { businessId } = businessParamSchema.parse(req.params);
      const days = Math.min(
        Math.max(Number(req.query.days ?? 30), 1),
        365
      );
      const data = await this.getService().getBusinessViewStats(
        businessId,
        days,
        req.user
      );
      res.json(data);
    } catch (err) {
      handleError(res, err);
    }
  };
}

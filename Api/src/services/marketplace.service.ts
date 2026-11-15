import { query } from "../config/database.config";
import { MarketplaceDAO } from "../dao/marketplace.dao";
import {
  MarketplaceAdminListQuery,
  MarketplaceListQuery,
  MarketplaceOrderCreateInput,
} from "../validation/marketplace.validation";
import {
  Actor,
  assertOwnershipAccess,
  isPrivileged,
} from "../helper/role.helper";
import { NotificationsService } from "./notifications.service";

export function withoutPickupSecret<T extends Record<string, any>>(order: T) {
  const { pickup_code: _code, client_request_id: _key, request_hash: _hash, ...safe } = order;
  return safe;
}

export class MarketplaceService {
  constructor(
    private dao: MarketplaceDAO,
    private notificationsService?: NotificationsService
  ) {}

  listPublic(filters: MarketplaceListQuery) {
    return this.dao.listPublic(filters);
  }

  listAdmin(filters: MarketplaceAdminListQuery) {
    return this.dao.listAdmin(filters);
  }

  listMine(userId: string, filters: MarketplaceListQuery) {
    return this.dao.listMine(userId, filters);
  }

  async getPublicationById(id: number) {
    const publication = await this.dao.findPublicationById(id);

    if (!publication) {
      throw new Error("Marketplace publication not found");
    }

    return publication;
  }

  createPublication(
    actor: Actor,
    productId: number,
    stock: number,
    unitPrice?: number | null,
    unitTinkuPrice?: number | null,
    paymentMode?: string
  ) {
    if (isPrivileged(actor.role)) {
      return this.dao.createPublicationWithoutCharge(
        actor.id,
        productId,
        stock,
        unitTinkuPrice
      );
    }

    return this.dao.createPublication(
      actor.id,
      productId,
      stock,
      unitPrice,
      unitTinkuPrice,
      paymentMode
    );
  }

  async estimatePublication(
    actor: Actor,
    stock: number,
    unitPrice?: number | null,
    unitTinkuPrice?: number | null,
    paymentMode?: string
  ) {
    const estimate = await this.dao.estimatePublication(
      stock,
      unitPrice,
      unitTinkuPrice,
      paymentMode
    );

    if (isPrivileged(actor.role)) {
      return { ...estimate, cost_tinkus: 0 };
    }

    return estimate;
  }

  updatePublicationStock(
    actor: Actor,
    publicationId: number,
    stock: number,
    unitPrice?: number | null,
    unitTinkuPrice?: number | null,
    paymentMode?: string
  ) {
    if (isPrivileged(actor.role)) {
      return this.dao.updatePublicationWithoutCharge(
        actor.id,
        publicationId,
        stock,
        unitTinkuPrice
      );
    }

    return this.dao.updatePublicationStock(
      actor.id,
      publicationId,
      stock,
      unitPrice,
      unitTinkuPrice,
      paymentMode
    );
  }

  async updatePublicationStatus(
    publicationId: number,
    status: string,
    actor: Actor
  ) {
    await this.assertPublicationOwner(publicationId, actor);

    const result = await this.dao.updatePublicationStatus(publicationId, status);

    if (!result) {
      throw new Error("Marketplace publication not found");
    }

    return result;
  }

  async publicationHistory(publicationId: number, actor: Actor) {
    await this.assertPublicationOwner(publicationId, actor);
    return this.dao.publicationHistory(publicationId);
  }

  async createOrder(userId: string, data: MarketplaceOrderCreateInput) {
    const items = this.mergeItems(data.items);

    if (data.fulfillment === "pickup" && !data.pickup_business_id) {
      throw new Error("Pickup business is required");
    }

    if (data.fulfillment === "warehouse_delivery" && !data.warehouse_id) {
      throw new Error("Warehouse is required");
    }

    const order = await this.dao.createOrder(userId, {
      ...data,
      items,
    });

    return order;
  }

  async getOrderById(id: number, actor: Actor) {
    const order = await this.dao.findOrderById(id);

    if (!order) {
      throw new Error("Marketplace order not found");
    }

    assertOwnershipAccess(order.buyer_id, actor, "Marketplace order not found");

    return actor.id === order.buyer_id ? order : withoutPickupSecret(order);
  }

  listMyOrders(userId: string, limit: number, offset: number) {
    return this.dao.listMyOrders(userId, limit, offset);
  }

  async listSalesOrders(
    userId: string,
    status: string | undefined,
    limit: number,
    offset: number
  ) {
    return (await this.dao.listSalesOrders(userId, status, limit, offset)).map(withoutPickupSecret);
  }

  async updateSalesOrderStatus(id: number, status: string, actor: Actor) {
    if (!['preparing', 'ready_for_pickup'].includes(status)) {
      throw new Error("Invalid marketplace order transition");
    }

    const result = await this.dao.updateSalesOrderStatus(id, actor.id, status);
    if (!result) {
      throw new Error("Marketplace order cannot transition to this status");
    }
    const order = await this.dao.findOrderById(id);
    if (order?.buyer_id) {
      await this.notificationsService?.createSafely({
        user_id: order.buyer_id,
        sender_id: actor.id,
        title: "Pedido actualizado",
        message: status === "preparing"
          ? `Tu pedido #${id} está en preparación.`
          : `Tu pedido #${id} está listo para retirar.`,
        type: "marketplace_order",
        entity_type: "marketplace_order",
        entity_id: id,
        route: "/myMarketplaceOrders",
        read: false,
      });
    }
    return withoutPickupSecret(result);
  }

  async rejectSalesOrder(id: number, reason: string, actor: Actor) {
    const result = await this.dao.rejectOrderBySeller(
      id,
      actor.id,
      reason,
      actor.role === "admin" || actor.role === "master"
    );
    if (!result) {
      throw new Error("Marketplace order cannot be rejected");
    }

    return withoutPickupSecret(result);
  }

  async listAdminOrders(status: string | undefined, limit: number, offset: number) {
    return (await this.dao.listAdminOrders(status, limit, offset)).map(withoutPickupSecret);
  }

  async updateOrderStatus(id: number, status: string) {
    if (!["preparing", "ready_for_pickup", "in_delivery"].includes(status)) {
      throw new Error("Invalid marketplace order transition");
    }
    const result = await this.dao.updateOrderStatus(id, status);

    if (!result) {
      throw new Error("Marketplace order not found");
    }

    return withoutPickupSecret(result);
  }

  async listWarehouseOrders(userId: string, limit: number, offset: number) {
    return (await this.dao.listWarehouseOrders(userId, limit, offset)).map(withoutPickupSecret);
  }

  async markWarehouseOrderReady(id: number, actor: Actor) {
    const result = await this.dao.markWarehouseOrderReady(id, actor.id);
    if (!result) throw new Error("Marketplace order cannot transition to this status");
    await this.notificationsService?.createSafely({
      user_id: result.buyer_id, title: "Pedido listo para retirar",
      message: `Tu pedido #${id} ya puede retirarse en el almacén.`,
      type: "marketplace_order", entity_type: "marketplace_order", entity_id: id,
      route: "/myMarketplaceOrders",
    });
    return withoutPickupSecret(result);
  }

  async cancelOrder(id: number, userId: string) {
    const result = await this.dao.cancelOrderByBuyer(id, userId);
    if (result?.seller_id) {
      await this.notificationsService?.createSafely({
        user_id: result.seller_id,
        sender_id: userId,
        title: "Pedido cancelado",
        message: `El comprador canceló el pedido #${id}. El stock fue restituido.`,
        type: "marketplace_order",
        entity_type: "marketplace_order",
        entity_id: id,
        route: "/marketplaceSalesOrders",
        read: false,
      });
    }
    return withoutPickupSecret(result);
  }

  async validatePickupCode(code: string, actor: Actor) {
    const result = await this.dao.validatePickupCode(
      this.normalizePickupCode(code),
      actor
    );
    return withoutPickupSecret(result);
  }

  private normalizePickupCode(rawCode: string) {
    const trimmed = rawCode.trim();
    if (!trimmed) return trimmed;

    try {
      const decoded = JSON.parse(trimmed);
      if (decoded && typeof decoded === "object") {
        const nested = decoded.pickup_code ?? decoded.code;
        if (nested !== undefined && nested !== null) {
          return String(nested).trim();
        }
      }
    } catch {
      // El QR actual usa el codigo directo; JSON queda soportado por compatibilidad.
    }

    return trimmed;
  }

  updateDeliveryStatus(id: number, status: string) {
    return this.dao.updateDeliveryStatus(id, status);
  }

  async registerBusinessView(businessId: number, actor?: Actor) {
    if (actor?.id) {
      const business = await query<{ owner_id: string | null }>(
        "SELECT owner_id FROM businesses WHERE id = $1",
        [businessId]
      );
      if (business.rows[0]?.owner_id === actor.id) return;
    }
    return this.dao.registerBusinessView(businessId);
  }

  getBusinessViewStatsBatch(businessIds: number[], actor: Actor) {
    return this.dao.getBusinessViewStatsBatch(
      businessIds,
      isPrivileged(actor.role) ? undefined : actor.id
    );
  }

  async getBusinessViewStats(businessId: number, days: number, actor: Actor) {
    await this.assertBusinessOwner(businessId, actor);
    return this.dao.getBusinessViewStats(businessId, days);
  }

  private mergeItems(items: MarketplaceOrderCreateInput["items"]) {
    const byPublication = new Map<number, number>();

    for (const item of items) {
      byPublication.set(
        item.publication_id,
        (byPublication.get(item.publication_id) ?? 0) + item.quantity
      );
    }

    return [...byPublication.entries()].map(([publication_id, quantity]) => ({
      publication_id,
      quantity,
    }));
  }

  private async assertPublicationOwner(publicationId: number, actor: Actor) {
    const result = await query<{ owner_id: string | null }>(
      `SELECT b.owner_id
       FROM product_publications pp
       JOIN businesses b ON b.id = pp.business_id
       WHERE pp.id = $1`,
      [publicationId]
    );
    const row = result.rows[0];

    assertOwnershipAccess(
      row?.owner_id,
      actor,
      "Marketplace publication not found"
    );
  }

  private async assertBusinessOwner(businessId: number, actor: Actor) {
    const result = await query<{ owner_id: string | null }>(
      "SELECT owner_id FROM businesses WHERE id = $1",
      [businessId]
    );
    const business = result.rows[0];

    assertOwnershipAccess(business?.owner_id, actor, "Business not found");
  }
}

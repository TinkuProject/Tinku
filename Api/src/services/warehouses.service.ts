import { query } from "../config/database.config";
import { WarehousesDAO } from "../dao/warehouses.dao";
import { buildStatusNotification } from "../helper/notification.helper";
import { NotificationsService } from "./notifications.service";
import {
  Actor,
  assertOwnershipAccess,
  assertPrivileged,
  isPrivileged,
} from "../helper/role.helper";
import {
  BusinessFulfillmentInput,
  WarehouseCreateInput,
  WarehouseInventoryLocationInput,
  WarehouseInventoryUpsertInput,
  WarehouseLocationCreateInput,
  WarehouseLocationUpdateInput,
  WarehouseStockRequestApproveInput,
  WarehouseStockRequestCreateInput,
  WarehouseStockRequestReceiveInput,
  WarehouseUpdateInput,
} from "../validation/warehouses.validation";

export class WarehousesService {
  constructor(
    private dao: WarehousesDAO,
    private notificationsService?: NotificationsService
  ) {}

  getActive() {
    return this.dao.findActive();
  }

  getMine(userId: string) {
    return this.dao.findMine(userId);
  }

  getAll(status?: string) {
    return this.dao.findAll(status);
  }

  async getById(id: number) {
    const warehouse = await this.dao.findById(id);

    if (!warehouse) {
      throw new Error("Warehouse not found");
    }

    return warehouse;
  }

  async create(data: WarehouseCreateInput, actor: Actor) {
    if (data.owner_id && data.owner_id !== actor.id) {
      throw new Error("Warehouse owner must match charged user");
    }

    const warehouse = await this.dao.createWithCharge(
      {
        ...data,
        owner_id: actor.id,
        validated: false,
        status: "pending",
      },
      actor.id,
      actor.role
    );

    const notif = buildStatusNotification({
      entityLabel: "Almacén",
      entityName: data.name,
      status: "pending",
    });

    await this.notificationsService?.createSafely({
      user_id: actor.id,
      title: notif.title,
      message: notif.message,
      type: "warehouse",
      entity_type: "warehouse",
      entity_id: warehouse.id,
      route: "/warehouses",
      read: false,
    });

    return warehouse;
  }

  async update(id: number, data: WarehouseUpdateInput, actor: Actor) {
    await this.assertWarehouseAccess(id, actor);
    if (!isPrivileged(actor.role) &&
        [data.owner_id, data.status, data.validated].some(value => value !== undefined)) {
      throw new Error("Forbidden");
    }
    const result = await this.dao.update(id, data);

    if (!result) {
      throw new Error("Warehouse not found");
    }

    return result;
  }

  async approve(
    id: number,
    admin: Actor,
    message?: string
  ) {
    this.assertAdmin(admin);

    const warehouse = await this.dao.findById(id);
    if (!warehouse) {
      throw new Error("Warehouse not found");
    }

    if (warehouse.status !== "pending") {
      throw new Error("Warehouse already processed");
    }

    const updated = await this.dao.approve(id);
    if (!updated) {
      throw new Error("Warehouse not found");
    }

    if (warehouse.owner_id) {
      const notif = buildStatusNotification({
        entityLabel: "Almacén",
        entityName: warehouse.name,
        status: "approved",
        ...(message?.trim() ? { adminMessage: message.trim() } : {}),
      });

      await this.notificationsService?.createSafely({
        user_id: warehouse.owner_id,
        sender_id: admin.id,
        title: notif.title,
        message: notif.message,
        type: "warehouse",
        entity_type: "warehouse",
        entity_id: warehouse.id,
        route: "/warehouses",
        read: false,
      });
    }

    return updated;
  }

  async markStockRequestSent(id: number, actor: Actor) {
    await this.assertStockRequestBusinessAccess(id, actor);

    const updated = await this.dao.markStockRequestSent(id);
    if (!updated) {
      throw new Error("Warehouse stock request must be approved before sending");
    }

    if (updated.warehouse_owner_id) {
      await this.notificationsService?.createSafely({
        user_id: updated.warehouse_owner_id,
        sender_id: actor.id,
        title: "Productos enviados al almacén",
        message: `${updated.business_name} marcó como enviado ${updated.quantity} uds. de ${updated.product_name}.`,
        type: "warehouse",
        entity_type: "warehouse_stock_request",
        entity_id: updated.id,
        route: "/warehouses",
        read: false,
      });
    }

    return updated;
  }

  async receiveStockRequest(
    id: number,
    actor: Actor,
    data: WarehouseStockRequestReceiveInput = {}
  ) {
    await this.assertStockRequestWarehouseAccess(id, actor);

    const updated = await this.dao.receiveStockRequest(id, actor.id, data);

    if (updated?.requested_by) {
      await this.notificationsService?.createSafely({
        user_id: updated.requested_by,
        sender_id: actor.id,
        title: "Productos recibidos por el almacén",
        message: `${updated.warehouse_name} recibió ${updated.quantity} uds. de ${updated.product_name}. Ya están disponibles para retiro.`,
        type: "warehouse",
        entity_type: "warehouse_stock_request",
        entity_id: updated.id,
        route: "/warehouses",
        read: false,
      });
    }

    return updated;
  }

  async reject(
    id: number,
    admin: Actor,
    message: string
  ) {
    this.assertAdmin(admin);

    const warehouse = await this.dao.findById(id);
    if (!warehouse) {
      throw new Error("Warehouse not found");
    }

    if (warehouse.status !== "pending") {
      throw new Error("Warehouse already processed");
    }

    const updated = await this.dao.reject(id);
    if (!updated) {
      throw new Error("Warehouse not found");
    }

    if (warehouse.owner_id) {
      const notif = buildStatusNotification({
        entityLabel: "Almacén",
        entityName: warehouse.name,
        status: "rejected",
        adminMessage: message.trim(),
      });

      await this.notificationsService?.createSafely({
        user_id: warehouse.owner_id,
        sender_id: admin.id,
        title: notif.title,
        message: notif.message,
        type: "warehouse",
        entity_type: "warehouse",
        entity_id: warehouse.id,
        route: "/warehouses",
        read: false,
      });
    }

    return updated;
  }

  async listInventory(id: number, actor: Actor) {
    await this.assertWarehouseAccess(id, actor);
    return this.dao.listInventory(id);
  }

  async listProductHistory(id: number, actor: Actor) {
    await this.assertWarehouseAccess(id, actor);
    return this.dao.listProductHistory(id);
  }

  async upsertInventory(
    id: number,
    data: WarehouseInventoryUpsertInput,
    actor: Actor
  ) {
    await this.assertWarehouseAccess(id, actor);
    await this.assertLocationBelongsToWarehouse(id, data.location_id ?? null);
    return this.dao.upsertInventory(id, actor.id, data);
  }

  async listLocations(id: number, actor: Actor) {
    await this.assertWarehouseAccess(id, actor);
    return this.dao.listLocations(id);
  }

  async createLocation(
    id: number,
    data: WarehouseLocationCreateInput,
    actor: Actor
  ) {
    await this.assertWarehouseAccess(id, actor);
    await this.assertLocationParent(id, data.parent_id ?? null);
    return this.dao.createLocation(id, actor.id, data);
  }

  async updateLocation(
    id: number,
    locationId: number,
    data: WarehouseLocationUpdateInput,
    actor: Actor
  ) {
    await this.assertWarehouseAccess(id, actor);
    if (data.parent_id !== undefined) {
      if (data.parent_id === locationId) {
        throw new Error("Invalid warehouse location parent");
      }
      await this.assertLocationParent(id, data.parent_id ?? null);
    }

    const updated = await this.dao.updateLocation(id, locationId, data);
    if (!updated) throw new Error("Warehouse location not found");
    return updated;
  }

  async archiveLocation(id: number, locationId: number, actor: Actor) {
    await this.assertWarehouseAccess(id, actor);
    const updated = await this.dao.archiveLocation(id, locationId);
    if (!updated) throw new Error("Warehouse location not found");
    return updated;
  }

  async setInventoryLocation(
    id: number,
    inventoryId: number,
    data: WarehouseInventoryLocationInput,
    actor: Actor
  ) {
    await this.assertWarehouseAccess(id, actor);
    const updated = await this.dao.setInventoryLocation(id, inventoryId, data);
    if (!updated) throw new Error("Warehouse inventory not found");
    return updated;
  }

  async createStockRequest(data: WarehouseStockRequestCreateInput, actor: Actor) {
    await this.assertBusinessOwner(data.business_id, actor);
    await this.assertProductBelongsToBusiness(data.product_id, data.business_id);
    await this.assertWarehousesAreActive([data.warehouse_id]);

    const created = await this.dao.createStockRequest(data, actor.id);

    if (created?.warehouse_owner_id) {
      await this.notificationsService?.createSafely({
        user_id: created.warehouse_owner_id,
        sender_id: actor.id,
        title: "Nueva solicitud de almacén",
        message: `${created.business_name} solicita enviar ${created.quantity} uds. de ${created.product_name} a ${created.warehouse_name}.`,
        type: "warehouse",
        entity_type: "warehouse_stock_request",
        entity_id: created.id,
        route: "/warehouses",
        read: false,
      });
    }

    return created;
  }

  listReceivedStockRequests(actor: Actor, status?: string) {
    return this.dao.listReceivedStockRequests(
      actor.id,
      status,
      isPrivileged(actor.role)
    );
  }

  listSentStockRequests(actor: Actor, status?: string) {
    return this.dao.listSentStockRequests(
      actor.id,
      status,
      isPrivileged(actor.role)
    );
  }

  async approveStockRequest(
    id: number,
    actor: Actor,
    data: WarehouseStockRequestApproveInput = {}
  ) {
    await this.assertStockRequestWarehouseAccess(id, actor);

    const updated = await this.dao.approveStockRequest(
      id,
      actor.id,
      data.location_id ?? null
    );

    if (updated?.requested_by) {
      await this.notificationsService?.createSafely({
        user_id: updated.requested_by,
        sender_id: actor.id,
        title: "Solicitud de almacén aprobada",
        message: `${updated.warehouse_name} aceptó recibir ${updated.quantity} uds. de ${updated.product_name}.`,
        type: "warehouse",
        entity_type: "warehouse_stock_request",
        entity_id: updated.id,
        route: "/warehouses",
        read: false,
      });
    }

    return updated;
  }

  async rejectStockRequest(id: number, message: string, actor: Actor) {
    await this.assertStockRequestWarehouseAccess(id, actor);

    const updated = await this.dao.rejectStockRequest(id, actor.id, message.trim());
    if (!updated) {
      throw new Error("Warehouse stock request already processed");
    }

    if (updated.requested_by) {
      await this.notificationsService?.createSafely({
        user_id: updated.requested_by,
        sender_id: actor.id,
        title: "Solicitud de almacén rechazada",
        message: `${updated.warehouse_name} rechazó recibir ${updated.product_name}. Motivo: ${message.trim()}`,
        type: "warehouse",
        entity_type: "warehouse_stock_request",
        entity_id: updated.id,
        route: "/warehouses",
        read: false,
      });
    }

    return updated;
  }

  async getBusinessFulfillment(businessId: number) {
    const result = await this.dao.getBusinessFulfillment(businessId);
    return { ...result, warehouses: result.warehouses.filter(warehouse =>
      warehouse.validated && warehouse.status === "active" && warehouse.relation_status === "active") };
  }

  async setBusinessFulfillment(
    businessId: number,
    data: BusinessFulfillmentInput,
    actor: Actor
  ) {
    await this.assertBusinessOwner(businessId, actor);

    if (data.warehouse_ids?.length) {
      await this.assertWarehousesAreActive(data.warehouse_ids);
      const accepted = await query<{ total: number }>(
        `SELECT COUNT(DISTINCT warehouse_id)::int AS total FROM warehouse_stock_requests
         WHERE business_id = $1 AND warehouse_id = ANY($2::bigint[])
           AND status IN ('approved', 'sent', 'received')`, [businessId, data.warehouse_ids]
      );
      if (accepted.rows[0]?.total !== new Set(data.warehouse_ids).size) {
        throw new Error("Warehouse must accept a stock request first");
      }
    }

    return this.dao.setBusinessFulfillment(businessId, data);
  }

  private async assertWarehouseAccess(id: number, actor: Actor) {
    const result = await query<{ owner_id: string | null }>(
      "SELECT owner_id FROM warehouses WHERE id = $1",
      [id]
    );
    const warehouse = result.rows[0];

    assertOwnershipAccess(warehouse?.owner_id, actor, "Warehouse not found");
  }

  private async assertBusinessOwner(businessId: number, actor: Actor) {
    const result = await query<{ owner_id: string | null; validated: boolean; status: string }>(
      "SELECT owner_id, validated, status FROM businesses WHERE id = $1",
      [businessId]
    );
    const business = result.rows[0];

    assertOwnershipAccess(business?.owner_id, actor, "Business not found");
    if (!business?.validated || business.status !== "active") throw new Error("Business must be approved before configuring fulfillment");
  }

  private async assertProductBelongsToBusiness(productId: number, businessId: number) {
    const result = await query<{ id: number }>(
      `SELECT id
       FROM products
       WHERE id = $1
         AND business_id = $2
         AND status = 'active'`,
      [productId, businessId]
    );

    if (!result.rowCount) {
      throw new Error("Invalid product selection");
    }
  }

  private async assertStockRequestWarehouseAccess(id: number, actor: Actor) {
    const result = await query<{ owner_id: string | null }>(
      `SELECT w.owner_id
       FROM warehouse_stock_requests wsr
       JOIN warehouses w ON w.id = wsr.warehouse_id
       WHERE wsr.id = $1`,
      [id]
    );
    const row = result.rows[0];

    assertOwnershipAccess(
      row?.owner_id,
      actor,
      "Warehouse stock request not found"
    );
  }

  private async assertStockRequestBusinessAccess(id: number, actor: Actor) {
    const result = await query<{ owner_id: string | null }>(
      `SELECT b.owner_id
       FROM warehouse_stock_requests wsr
       JOIN businesses b ON b.id = wsr.business_id
       WHERE wsr.id = $1`,
      [id]
    );
    const row = result.rows[0];

    assertOwnershipAccess(
      row?.owner_id,
      actor,
      "Warehouse stock request not found"
    );
  }

  private async assertWarehousesAreActive(ids: number[]) {
    const uniqueIds = [...new Set(ids)];
    const result = await query<{ id: number }>(
      `SELECT id
       FROM warehouses
       WHERE id = ANY($1::bigint[])
         AND status = 'active'
         AND validated = true`,
      [uniqueIds]
    );

    if (result.rowCount !== uniqueIds.length) {
      throw new Error("Invalid warehouse selection");
    }
  }

  private assertAdmin(actor: Actor) {
    assertPrivileged(actor);
  }

  private async assertLocationParent(warehouseId: number, parentId?: number | null) {
    if (parentId === undefined || parentId === null) return;
    await this.assertLocationBelongsToWarehouse(warehouseId, parentId);
  }

  private async assertLocationBelongsToWarehouse(
    warehouseId: number,
    locationId?: number | null
  ) {
    if (locationId === undefined || locationId === null) return;

    const result = await query<{ id: number }>(
      `SELECT id
       FROM warehouse_locations
       WHERE id = $1
         AND warehouse_id = $2
         AND status = 'active'`,
      [locationId, warehouseId]
    );

    if (!result.rowCount) {
      throw new Error("Warehouse location not found");
    }
  }
}

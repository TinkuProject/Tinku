import { dbPool, query } from "../config/database.config";
import {
  BusinessFulfillmentInput,
  WarehouseCreateInput,
  WarehouseInventoryLocationInput,
  WarehouseInventoryUpsertInput,
  WarehouseLocationCreateInput,
  WarehouseLocationUpdateInput,
  WarehouseStockRequestCreateInput,
  WarehouseStockRequestReceiveInput,
  WarehouseUpdateInput,
} from "../validation/warehouses.validation";

function mapWarehouse(row: any) {
  if (!row) return row;

  return {
    ...row,
    location:
      row.latitude !== null && row.latitude !== undefined
        ? {
            latitude: Number(row.latitude),
            longitude: Number(row.longitude),
          }
        : null,
    latitude: undefined,
    longitude: undefined,
  };
}

function warehouseSelect(alias = "") {
  const prefix = alias ? `${alias}.` : "";

  return `
    ${prefix}id,
    ${prefix}owner_id,
    ${prefix}name,
    ${prefix}description,
    ${prefix}phone,
    ${prefix}email,
    ${prefix}address,
    ${prefix}validated,
    ${prefix}status,
    ST_Y(${prefix}location::geometry) AS latitude,
    ST_X(${prefix}location::geometry) AS longitude,
    ${prefix}created_at,
    ${prefix}updated_at
  `;
}

function buildLocationSql(index: number) {
  return `ST_SetSRID(ST_MakePoint($${index + 1}, $${index}), 4326)::geography`;
}

export class WarehousesDAO {
  async findActive() {
    const result = await query(
      `SELECT ${warehouseSelect()}
       FROM warehouses
       WHERE status = 'active'
         AND validated = true
       ORDER BY name ASC`
    );

    return result.rows.map(mapWarehouse);
  }

  async findMine(userId: string) {
    const result = await query(
      `SELECT ${warehouseSelect()}
       FROM warehouses
       WHERE owner_id = $1
       ORDER BY created_at DESC`,
      [userId]
    );

    return result.rows.map(mapWarehouse);
  }

  async findAll(status?: string) {
    const params: unknown[] = [];
    const where = status ? "WHERE status = $1" : "";

    if (status) {
      params.push(status);
    }

    const result = await query(
      `SELECT ${warehouseSelect()}
       FROM warehouses
       ${where}
       ORDER BY created_at DESC`,
      params
    );

    return result.rows.map(mapWarehouse);
  }

  async findById(id: number) {
    const result = await query(
      `SELECT ${warehouseSelect()}
       FROM warehouses
       WHERE id = $1
       LIMIT 1`,
      [id]
    );

    return mapWarehouse(result.rows[0] ?? null);
  }

  async create(data: WarehouseCreateInput) {
    const result = await query(
      `INSERT INTO warehouses (
         owner_id,
         name,
         description,
         phone,
         email,
         address,
         location,
         validated,
         status,
         created_at
       )
       VALUES (
         $1,
         $2,
         $3,
         $4,
         $5,
         $6,
         CASE
           WHEN $7::numeric IS NULL OR $8::numeric IS NULL THEN NULL
           ELSE ST_SetSRID(ST_MakePoint($8, $7), 4326)::geography
         END,
         $9,
         $10,
         CURRENT_TIMESTAMP
       )
       RETURNING ${warehouseSelect()}`,
      [
        data.owner_id ?? null,
        data.name,
        data.description ?? null,
        data.phone ?? null,
        data.email ?? null,
        data.address ?? null,
        data.location?.latitude,
        data.location?.longitude,
        data.validated ?? false,
        data.status ?? "pending",
      ]
    );

    return mapWarehouse(result.rows[0]);
  }

  async createWithCharge(data: WarehouseCreateInput, userId: string, role?: string) {
    const result = await query(
      `SELECT ${warehouseSelect()}
       FROM create_warehouse_with_charge($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        userId,
        data.name,
        data.description ?? null,
        data.phone ?? null,
        data.email ?? null,
        data.address ?? null,
        data.location?.latitude ?? null,
        data.location?.longitude ?? null,
      ],
      { userId, role: role as any }
    );

    return mapWarehouse(result.rows[0]);
  }

  async update(id: number, data: WarehouseUpdateInput) {
    const sets: string[] = [];
    const values: unknown[] = [];

    const add = (column: string, value: unknown) => {
      values.push(value);
      sets.push(`${column} = $${values.length}`);
    };

    if (data.owner_id !== undefined) add("owner_id", data.owner_id);
    if (data.name !== undefined) add("name", data.name);
    if (data.description !== undefined) add("description", data.description);
    if (data.phone !== undefined) add("phone", data.phone);
    if (data.email !== undefined) add("email", data.email);
    if (data.address !== undefined) add("address", data.address);
    if (data.validated !== undefined) add("validated", data.validated);
    if (data.status !== undefined) add("status", data.status);
    if (data.location !== undefined) {
      if (data.location === null) {
        sets.push("location = NULL");
      } else {
        values.push(data.location.latitude, data.location.longitude);
        sets.push(`location = ${buildLocationSql(values.length - 1)}`);
      }
    }

    if (sets.length === 0) {
      return this.findById(id);
    }

    values.push(id);
    const result = await query(
      `UPDATE warehouses
       SET ${sets.join(", ")}, updated_at = CURRENT_TIMESTAMP
       WHERE id = $${values.length}
       RETURNING ${warehouseSelect()}`,
      values
    );

    return mapWarehouse(result.rows[0] ?? null);
  }

  async approve(id: number) {
    const result = await query(
      `UPDATE warehouses
       SET status = 'active',
           validated = true,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING ${warehouseSelect()}`,
      [id]
    );

    return mapWarehouse(result.rows[0] ?? null);
  }

  async reject(id: number) {
    const result = await query(
      `UPDATE warehouses
       SET status = 'inactive',
           validated = false,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING ${warehouseSelect()}`,
      [id]
    );

    return mapWarehouse(result.rows[0] ?? null);
  }

  async listInventory(warehouseId: number) {
    const result = await query(
      `SELECT
         wi.*,
         p.name AS product_name,
         p.business_id,
         b.name AS business_name,
         wl.name AS location_name,
         wl.code AS location_code,
         wl.parent_id AS location_parent_id
       FROM warehouse_inventory wi
       JOIN products p ON p.id = wi.product_id
       JOIN businesses b ON b.id = p.business_id
       LEFT JOIN warehouse_locations wl ON wl.id = wi.location_id
       WHERE wi.warehouse_id = $1
       ORDER BY wi.updated_at DESC NULLS LAST, wi.created_at DESC`,
      [warehouseId]
    );

    return result.rows;
  }

  async listProductHistory(warehouseId: number) {
    const result = await query(
      `SELECT
         h.*,
         p.name AS product_name,
         u.username AS changed_by_username
       FROM warehouse_product_history h
       JOIN products p ON p.id = h.product_id
       LEFT JOIN users u ON u.id = h.changed_by
       WHERE h.warehouse_id = $1
       ORDER BY h.created_at DESC`,
      [warehouseId]
    );

    return result.rows;
  }

  async upsertInventory(
    warehouseId: number,
    changedBy: string,
    data: WarehouseInventoryUpsertInput
  ) {
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");

      const previous = await client.query(
        `SELECT quantity, reserved_quantity
         FROM warehouse_inventory
         WHERE warehouse_id = $1
           AND product_id = $2
         FOR UPDATE`,
        [warehouseId, data.product_id]
      );

      const inventory = previous.rows[0];
      if (!inventory) throw new Error("Receive a stock request before adjusting inventory");
      if (data.reserved_quantity !== undefined && data.reserved_quantity !== inventory.reserved_quantity) {
        throw new Error("Reserved stock cannot be changed manually");
      }
      if (data.quantity < inventory.reserved_quantity) throw new Error("Insufficient warehouse stock");

      const result = await client.query(
        `INSERT INTO warehouse_inventory (
           warehouse_id,
           product_id,
           location_id,
           quantity,
           reserved_quantity,
           status,
           created_at,
           updated_at
         )
         VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         ON CONFLICT (warehouse_id, product_id)
         DO UPDATE SET
           location_id = EXCLUDED.location_id,
           quantity = EXCLUDED.quantity,
           reserved_quantity = EXCLUDED.reserved_quantity,
           status = EXCLUDED.status,
           updated_at = CURRENT_TIMESTAMP
         RETURNING *`,
        [
          warehouseId,
          data.product_id,
          data.location_id ?? null,
          data.quantity,
          inventory.reserved_quantity,
          data.status,
        ]
      );

      await client.query(
        `INSERT INTO warehouse_product_history (
           warehouse_id,
           product_id,
           changed_by,
           previous_quantity,
           new_quantity,
           reason,
           created_at
         )
         VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)`,
        [
          warehouseId,
          data.product_id,
          changedBy,
          previous.rows[0]?.quantity ?? null,
          data.quantity,
          data.reason ?? null,
        ]
      );

      await client.query("COMMIT");
      return result.rows[0];
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  async createStockRequest(data: WarehouseStockRequestCreateInput, requestedBy: string) {
    const result = await query(
      `INSERT INTO warehouse_stock_requests (
         business_id,
         warehouse_id,
         product_id,
         requested_by,
         quantity,
         notes,
         created_at,
         updated_at
       )
       VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING *`,
      [
        data.business_id,
        data.warehouse_id,
        data.product_id,
        requestedBy,
        data.quantity,
        data.notes ?? null,
      ]
    );

    return this.findStockRequestById(result.rows[0].id);
  }

  async findStockRequestById(id: number) {
    const result = await query(
      `SELECT
         wsr.*,
         b.name AS business_name,
         w.name AS warehouse_name,
         w.owner_id AS warehouse_owner_id,
         p.name AS product_name,
         p.stock AS product_stock,
         requester.username AS requested_by_username,
         processor.username AS processed_by_username,
         receiver.username AS received_by_username,
         wl.name AS location_name,
         wl.code AS location_code
       FROM warehouse_stock_requests wsr
       JOIN businesses b ON b.id = wsr.business_id
       JOIN warehouses w ON w.id = wsr.warehouse_id
       JOIN products p ON p.id = wsr.product_id
       LEFT JOIN users requester ON requester.id = wsr.requested_by
       LEFT JOIN users processor ON processor.id = wsr.processed_by
       LEFT JOIN users receiver ON receiver.id = wsr.received_by
       LEFT JOIN warehouse_locations wl ON wl.id = wsr.location_id
       WHERE wsr.id = $1
       LIMIT 1`,
      [id]
    );

    return result.rows[0] ?? null;
  }

  async listReceivedStockRequests(userId: string, status?: string, admin = false) {
    const params: unknown[] = [];
    const where: string[] = [];

    if (!admin) {
      params.push(userId);
      where.push(`w.owner_id = $${params.length}`);
    }

    if (status) {
      params.push(status);
      where.push(`wsr.status = $${params.length}`);
    }

    const result = await query(
      `SELECT
         wsr.*,
         b.name AS business_name,
         w.name AS warehouse_name,
         w.owner_id AS warehouse_owner_id,
         p.name AS product_name,
         p.stock AS product_stock,
         requester.username AS requested_by_username,
         processor.username AS processed_by_username,
         receiver.username AS received_by_username,
         wl.name AS location_name,
         wl.code AS location_code
       FROM warehouse_stock_requests wsr
       JOIN businesses b ON b.id = wsr.business_id
       JOIN warehouses w ON w.id = wsr.warehouse_id
       JOIN products p ON p.id = wsr.product_id
       LEFT JOIN users requester ON requester.id = wsr.requested_by
       LEFT JOIN users processor ON processor.id = wsr.processed_by
       LEFT JOIN users receiver ON receiver.id = wsr.received_by
       LEFT JOIN warehouse_locations wl ON wl.id = wsr.location_id
       ${where.length ? `WHERE ${where.join(" AND ")}` : ""}
       ORDER BY wsr.created_at DESC`,
      params
    );

    return result.rows;
  }

  async listSentStockRequests(userId: string, status?: string, admin = false) {
    const params: unknown[] = [];
    const where: string[] = [];

    if (!admin) {
      params.push(userId);
      where.push(`b.owner_id = $${params.length}`);
    }

    if (status) {
      params.push(status);
      where.push(`wsr.status = $${params.length}`);
    }

    const result = await query(
      `SELECT
         wsr.*,
         b.name AS business_name,
         w.name AS warehouse_name,
         w.owner_id AS warehouse_owner_id,
         p.name AS product_name,
         p.stock AS product_stock,
         requester.username AS requested_by_username,
         processor.username AS processed_by_username,
         receiver.username AS received_by_username,
         wl.name AS location_name,
         wl.code AS location_code
       FROM warehouse_stock_requests wsr
       JOIN businesses b ON b.id = wsr.business_id
       JOIN warehouses w ON w.id = wsr.warehouse_id
       JOIN products p ON p.id = wsr.product_id
       LEFT JOIN users requester ON requester.id = wsr.requested_by
       LEFT JOIN users processor ON processor.id = wsr.processed_by
       LEFT JOIN users receiver ON receiver.id = wsr.received_by
       LEFT JOIN warehouse_locations wl ON wl.id = wsr.location_id
       ${where.length ? `WHERE ${where.join(" AND ")}` : ""}
       ORDER BY wsr.created_at DESC`,
      params
    );

    return result.rows;
  }

  async approveStockRequest(
    id: number,
    processedBy: string,
    locationId?: number | null
  ) {
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");

      const request = await client.query(
        `SELECT *
         FROM warehouse_stock_requests
         WHERE id = $1
         FOR UPDATE`,
        [id]
      );

      const stockRequest = request.rows[0];
      if (!stockRequest) {
        throw new Error("Warehouse stock request not found");
      }

      if (stockRequest.status !== "pending") {
        throw new Error("Warehouse stock request already processed");
      }

      await client.query(
        `INSERT INTO business_warehouses (
           business_id,
           warehouse_id,
           status,
           created_at,
           updated_at
         )
         VALUES ($1, $2, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         ON CONFLICT (business_id, warehouse_id)
         DO UPDATE SET
           status = 'active',
           updated_at = CURRENT_TIMESTAMP`,
        [stockRequest.business_id, stockRequest.warehouse_id]
      );

      await client.query(
        `INSERT INTO business_fulfillment_options (
           business_id,
           pickup_in_store,
           warehouse_delivery,
           notes,
           created_at,
           updated_at
         )
         VALUES ($1, false, true, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         ON CONFLICT (business_id)
         DO UPDATE SET
           warehouse_delivery = true,
           updated_at = CURRENT_TIMESTAMP`,
        [stockRequest.business_id]
      );

      if (locationId !== undefined && locationId !== null) {
        const location = await client.query(
          `SELECT 1
           FROM warehouse_locations
           WHERE id = $1
             AND warehouse_id = $2
             AND status = 'active'
           LIMIT 1`,
          [locationId, stockRequest.warehouse_id]
        );

        if (!location.rowCount) {
          throw new Error("Warehouse location not found");
        }
      }

      await client.query(
        `UPDATE warehouse_stock_requests
         SET status = 'approved',
             processed_by = $2,
             location_id = $3,
             processed_at = CURRENT_TIMESTAMP,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [id, processedBy, locationId ?? null]
      );

      await client.query("COMMIT");
      return this.findStockRequestById(id);
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  async markStockRequestSent(id: number) {
    const result = await query(
      `UPDATE warehouse_stock_requests
       SET status = 'sent',
           sent_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
         AND status = 'approved'
       RETURNING *`,
      [id]
    );

    if (!result.rows[0]) {
      return null;
    }

    return this.findStockRequestById(id);
  }

  async receiveStockRequest(
    id: number,
    receivedBy: string,
    data: WarehouseStockRequestReceiveInput = {}
  ) {
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");

      const request = await client.query(
        `SELECT *
         FROM warehouse_stock_requests
         WHERE id = $1
         FOR UPDATE`,
        [id]
      );

      const stockRequest = request.rows[0];
      if (!stockRequest) {
        throw new Error("Warehouse stock request not found");
      }

      if (!["approved", "sent"].includes(stockRequest.status)) {
        throw new Error("Warehouse stock request cannot be received");
      }

      const locationId = data.location_id ?? stockRequest.location_id ?? null;

      if (locationId !== null) {
        const location = await client.query(
          `SELECT 1
           FROM warehouse_locations
           WHERE id = $1
             AND warehouse_id = $2
             AND status = 'active'
           LIMIT 1`,
          [locationId, stockRequest.warehouse_id]
        );

        if (!location.rowCount) {
          throw new Error("Warehouse location not found");
        }
      }

      const previous = await client.query(
        `SELECT quantity
         FROM warehouse_inventory
         WHERE warehouse_id = $1
           AND product_id = $2
         FOR UPDATE`,
        [stockRequest.warehouse_id, stockRequest.product_id]
      );

      const previousQuantity = previous.rows[0]?.quantity ?? 0;
      const nextQuantity = previousQuantity + stockRequest.quantity;

      await client.query(
        `INSERT INTO warehouse_inventory (
           warehouse_id,
           product_id,
           location_id,
           quantity,
           reserved_quantity,
           status,
           created_at,
           updated_at
         )
         VALUES ($1, $2, $3, $4, 0, 'available', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         ON CONFLICT (warehouse_id, product_id)
         DO UPDATE SET
           quantity = $4,
           location_id = COALESCE($3, warehouse_inventory.location_id),
           status = 'available',
           updated_at = CURRENT_TIMESTAMP`,
        [
          stockRequest.warehouse_id,
          stockRequest.product_id,
          locationId,
          nextQuantity,
        ]
      );

      await client.query(
        `INSERT INTO warehouse_product_history (
           warehouse_id,
           product_id,
           changed_by,
           previous_quantity,
           new_quantity,
           reason,
           created_at
         )
         VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)`,
        [
          stockRequest.warehouse_id,
          stockRequest.product_id,
          receivedBy,
          previous.rows[0]?.quantity ?? null,
          nextQuantity,
          `Solicitud de envío #${stockRequest.id} recibida`,
        ]
      );

      await client.query(
        `UPDATE warehouse_stock_requests
         SET status = 'received',
             received_by = $2,
             location_id = $3,
             received_at = CURRENT_TIMESTAMP,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [id, receivedBy, locationId]
      );

      await client.query("COMMIT");
      return this.findStockRequestById(id);
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  async rejectStockRequest(id: number, processedBy: string, message: string) {
    const result = await query(
      `UPDATE warehouse_stock_requests
       SET status = 'rejected',
           processed_by = $2,
           response_message = $3,
           processed_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
         AND status = 'pending'
       RETURNING *`,
      [id, processedBy, message]
    );

    if (!result.rows[0]) {
      return null;
    }

    return this.findStockRequestById(id);
  }

  async getBusinessFulfillment(businessId: number) {
    const options = await query(
      `SELECT *
       FROM business_fulfillment_options
       WHERE business_id = $1`,
      [businessId]
    );

    const warehouses = await query(
      `SELECT
         bw.status AS relation_status,
         ${warehouseSelect("w")}
       FROM business_warehouses bw
       JOIN warehouses w ON w.id = bw.warehouse_id
       WHERE bw.business_id = $1
       ORDER BY w.name ASC`,
      [businessId]
    );

    return {
      options: options.rows[0] ?? {
        business_id: businessId,
        pickup_in_store: false,
        warehouse_delivery: false,
        notes: null,
      },
      warehouses: warehouses.rows.map(mapWarehouse),
    };
  }

  async listLocations(warehouseId: number) {
    const result = await query(
      `SELECT *
       FROM warehouse_locations
       WHERE warehouse_id = $1
       ORDER BY sort_order ASC, name ASC, id ASC`,
      [warehouseId]
    );

    return result.rows;
  }

  async createLocation(
    warehouseId: number,
    createdBy: string,
    data: WarehouseLocationCreateInput
  ) {
    const result = await query(
      `INSERT INTO warehouse_locations (
         warehouse_id,
         parent_id,
         name,
         code,
         description,
         status,
         sort_order,
         created_by,
         created_at,
         updated_at
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING *`,
      [
        warehouseId,
        data.parent_id ?? null,
        data.name,
        data.code,
        data.description ?? null,
        data.status ?? "active",
        data.sort_order ?? 0,
        createdBy,
      ]
    );

    return result.rows[0];
  }

  async updateLocation(
    warehouseId: number,
    locationId: number,
    data: WarehouseLocationUpdateInput
  ) {
    const sets: string[] = [];
    const values: unknown[] = [];

    const add = (column: string, value: unknown) => {
      values.push(value);
      sets.push(`${column} = $${values.length}`);
    };

    if (data.parent_id !== undefined) add("parent_id", data.parent_id);
    if (data.name !== undefined) add("name", data.name);
    if (data.code !== undefined) add("code", data.code);
    if (data.description !== undefined) add("description", data.description);
    if (data.status !== undefined) add("status", data.status);
    if (data.sort_order !== undefined) add("sort_order", data.sort_order);

    if (!sets.length) {
      const result = await query(
        `SELECT *
         FROM warehouse_locations
         WHERE warehouse_id = $1
           AND id = $2
         LIMIT 1`,
        [warehouseId, locationId]
      );
      return result.rows[0] ?? null;
    }

    values.push(warehouseId, locationId);
    const result = await query(
      `UPDATE warehouse_locations
       SET ${sets.join(", ")},
           updated_at = CURRENT_TIMESTAMP
       WHERE warehouse_id = $${values.length - 1}
         AND id = $${values.length}
       RETURNING *`,
      values
    );

    return result.rows[0] ?? null;
  }

  async archiveLocation(warehouseId: number, locationId: number) {
    const result = await query(
      `UPDATE warehouse_locations
       SET status = 'inactive',
           updated_at = CURRENT_TIMESTAMP
       WHERE warehouse_id = $1
         AND id = $2
       RETURNING *`,
      [warehouseId, locationId]
    );

    return result.rows[0] ?? null;
  }

  async setInventoryLocation(
    warehouseId: number,
    inventoryId: number,
    data: WarehouseInventoryLocationInput
  ) {
    if (data.location_id !== undefined && data.location_id !== null) {
      const location = await query(
        `SELECT 1
         FROM warehouse_locations
         WHERE id = $1
           AND warehouse_id = $2
           AND status = 'active'
         LIMIT 1`,
        [data.location_id, warehouseId]
      );

      if (!location.rowCount) {
        throw new Error("Warehouse location not found");
      }
    }

    const result = await query(
      `UPDATE warehouse_inventory
       SET location_id = $3,
           updated_at = CURRENT_TIMESTAMP
       WHERE warehouse_id = $1
         AND id = $2
       RETURNING *`,
      [warehouseId, inventoryId, data.location_id ?? null]
    );

    return result.rows[0] ?? null;
  }

  async setBusinessFulfillment(
    businessId: number,
    data: BusinessFulfillmentInput
  ) {
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");

      const options = await client.query(
        `INSERT INTO business_fulfillment_options (
           business_id,
           pickup_in_store,
           warehouse_delivery,
           notes,
           created_at,
           updated_at
         )
         VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         ON CONFLICT (business_id)
         DO UPDATE SET
           pickup_in_store = EXCLUDED.pickup_in_store,
           warehouse_delivery = EXCLUDED.warehouse_delivery,
           notes = EXCLUDED.notes,
           updated_at = CURRENT_TIMESTAMP
         RETURNING *`,
        [
          businessId,
          data.pickup_in_store ?? false,
          data.warehouse_delivery ?? false,
          data.notes ?? null,
        ]
      );

      if (data.warehouse_ids) {
        await client.query(
          "DELETE FROM business_warehouses WHERE business_id = $1",
          [businessId]
        );

        for (const warehouseId of data.warehouse_ids) {
          await client.query(
            `INSERT INTO business_warehouses (
               business_id,
               warehouse_id,
               status,
               created_at,
               updated_at
             )
             SELECT $1, $2, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
             WHERE EXISTS (
               SELECT 1 FROM warehouse_stock_requests
               WHERE business_id = $1 AND warehouse_id = $2 AND status IN ('approved', 'sent', 'received')
             )`,
            [businessId, warehouseId]
          );
        }
      }

      await client.query("COMMIT");

      return {
        ...(await this.getBusinessFulfillment(businessId)),
        options: options.rows[0],
      };
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }
}

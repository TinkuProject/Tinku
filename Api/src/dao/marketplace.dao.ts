import { randomBytes, createHash } from "crypto";
import { PoolClient } from "pg";
import { dbPool, query } from "../config/database.config";
import {
  MarketplaceAdminListQuery,
  MarketplaceListQuery,
  MarketplaceOrderCreateInput,
} from "../validation/marketplace.validation";

function publicationSelect() {
  return `
    pp.*,
    ROUND((pp.unit_price * (1 + COALESCE(msf.value::numeric, 0)))::numeric, 2) AS display_unit_price,
    CEIL(pp.unit_tinku_price * (1 + COALESCE(msf.value::numeric, 0)))::int AS display_unit_tinku_price,
    COALESCE(msf.value::numeric, 0) AS marketplace_service_fee_rate,
    p.name AS product_name,
    p.description AS product_description,
    COALESCE(p.volume_tier, 'small') AS product_volume_tier,
    CASE COALESCE(p.volume_tier, 'small')
      WHEN 'large' THEN COALESCE((SELECT value::int FROM system_config WHERE key = 'warehouse_delivery_reward_large'), 3)
      WHEN 'medium' THEN COALESCE((SELECT value::int FROM system_config WHERE key = 'warehouse_delivery_reward_medium'), 2)
      ELSE COALESCE((SELECT value::int FROM system_config WHERE key = 'warehouse_delivery_reward_small'), 1)
    END AS warehouse_delivery_reward_tinkus,
    (
      SELECT m.url
      FROM media m
      WHERE m.entity_type = 'product'
        AND m.entity_id = pp.product_id::text
      ORDER BY m.is_primary DESC, m.display_order ASC, m.created_at ASC
      LIMIT 1
    ) AS product_image_url,
    p.category_id,
    p.stock AS product_stock,
    b.name AS business_name,
    b.address AS business_address,
    b.owner_id AS business_owner_id
  `;
}

const serviceFeeJoin = `
  LEFT JOIN system_config msf
    ON msf.key = 'marketplace_service_fee_rate'
`;

const fulfillmentEnabledSql = `
  EXISTS (
    SELECT 1
    FROM business_fulfillment_options bfo
    WHERE bfo.business_id = b.id
      AND (
        bfo.pickup_in_store = true
        OR (
          bfo.warehouse_delivery = true
          AND EXISTS (
            SELECT 1
            FROM business_warehouses bw
            JOIN warehouses w ON w.id = bw.warehouse_id
            WHERE bw.business_id = b.id
              AND bw.status = 'active'
              AND w.status = 'active'
              AND w.validated = true
          )
        )
      )
  )
`;

function generatePickupCode() {
  return `TK-${randomBytes(8).toString("hex").toUpperCase()}`;
}

function buildPublicationWhere(filters: MarketplaceListQuery, admin = false) {
  const where: string[] = [];
  const params: unknown[] = [];

  if (!admin) {
    where.push("pp.status IN ('active', 'sold_out')");
    where.push("pp.payment_mode = 'tinkus'");
    where.push("pp.unit_tinku_price IS NOT NULL");
    where.push("pp.unit_tinku_price > 0");
    where.push("p.status = 'active'");
    where.push("b.status = 'active'");
    where.push(fulfillmentEnabledSql);
  }

  if (filters.business_id) {
    params.push(filters.business_id);
    where.push(`pp.business_id = $${params.length}`);
  }

  if (filters.q?.trim()) {
    params.push(`%${filters.q.trim()}%`);
    where.push(`(
      p.name ILIKE $${params.length}
      OR p.description ILIKE $${params.length}
      OR b.name ILIKE $${params.length}
    )`);
  }

  if (!admin) {
    if (filters.availability === 'available') {
      where.push("pp.status = 'active' AND pp.published_stock > 0");
    } else if (filters.availability === 'sold_out') {
      where.push("(pp.status = 'sold_out' OR pp.published_stock <= 0)");
    }
    if (filters.volume) {
      params.push(filters.volume);
      where.push(`COALESCE(p.volume_tier, 'small') = $${params.length}`);
    }
    const displayedPrice = 'CEIL(pp.unit_tinku_price * (1 + COALESCE(msf.value::numeric, 0)))';
    if (filters.min_tinkus != null) {
      params.push(filters.min_tinkus);
      where.push(`${displayedPrice} >= $${params.length}`);
    }
    if (filters.max_tinkus != null) {
      params.push(filters.max_tinkus);
      where.push(`${displayedPrice} <= $${params.length}`);
    }
  }

  return { where, params };
}

export class MarketplaceDAO {
  async listPublic(filters: MarketplaceListQuery) {
    const { where, params } = buildPublicationWhere(filters);
    const orderBy = {
      newest: 'pp.created_at DESC, pp.id DESC',
      price_asc: 'display_unit_tinku_price ASC, pp.id DESC',
      price_desc: 'display_unit_tinku_price DESC, pp.id DESC',
      name: 'p.name ASC, pp.id DESC',
    }[filters.sort ?? 'newest'];
    params.push(filters.limit, filters.offset);

    const result = await query(
      `SELECT ${publicationSelect()}
       FROM product_publications pp
       JOIN products p ON p.id = pp.product_id
       JOIN businesses b ON b.id = pp.business_id
       ${serviceFeeJoin}
       WHERE ${where.join(" AND ")}
       ORDER BY ${orderBy}
       LIMIT $${params.length - 1}
       OFFSET $${params.length}`,
      params
    );

    return result.rows;
  }

  async listAdmin(filters: MarketplaceAdminListQuery) {
    const { where, params } = buildPublicationWhere(filters, true);

    if (filters.status) {
      params.push(filters.status);
      where.push(`pp.status = $${params.length}`);
    }

    params.push(filters.limit, filters.offset);
    const whereSql = where.length ? `WHERE ${where.join(" AND ")}` : "";

    const result = await query(
      `SELECT ${publicationSelect()}
       FROM product_publications pp
       JOIN products p ON p.id = pp.product_id
       JOIN businesses b ON b.id = pp.business_id
       ${serviceFeeJoin}
       ${whereSql}
       ORDER BY pp.created_at DESC
       LIMIT $${params.length - 1}
       OFFSET $${params.length}`,
      params
    );

    return result.rows;
  }

  async listMine(userId: string, filters: MarketplaceListQuery) {
    const { where, params } = buildPublicationWhere(filters, true);
    params.push(userId);
    where.push(`b.owner_id = $${params.length}`);
    params.push(filters.limit, filters.offset);

    const result = await query(
      `SELECT ${publicationSelect()}
       FROM product_publications pp
       JOIN products p ON p.id = pp.product_id
       JOIN businesses b ON b.id = pp.business_id
       ${serviceFeeJoin}
       WHERE ${where.join(" AND ")}
       ORDER BY pp.created_at DESC
       LIMIT $${params.length - 1}
       OFFSET $${params.length}`,
      params
    );

    return result.rows;
  }

  async findPublicationById(id: number, onlyActive = true) {
    const result = await query(
      `SELECT ${publicationSelect()}
       FROM product_publications pp
       JOIN products p ON p.id = pp.product_id
       JOIN businesses b ON b.id = pp.business_id
       ${serviceFeeJoin}
       WHERE pp.id = $1
         ${onlyActive ? "AND pp.status = 'active' AND p.status = 'active' AND b.status = 'active'" : ""}
       LIMIT 1`,
      [id]
    );

    return result.rows[0] ?? null;
  }

  async estimatePublication(
    stock: number,
    unitPrice?: number | null,
    unitTinkuPrice?: number | null,
    paymentMode = "tinkus"
  ) {
    const result = await query(
      `SELECT
         CEIL(
           COALESCE((SELECT value::numeric FROM system_config WHERE key = 'product_publication_base_cost'), 0)
           + ($1::int * COALESCE((SELECT value::numeric FROM system_config WHERE key = 'product_publication_stock_unit_cost'), 0))
           + (
             GREATEST(COALESCE($2::numeric, 0), COALESCE($3::numeric, 0), 0)
             * $1::int
             * COALESCE((SELECT value::numeric FROM system_config WHERE key = 'product_publication_price_rate'), 0)
           )
         )::int AS cost_tinkus,
         COALESCE((SELECT value::numeric FROM system_config WHERE key = 'marketplace_service_fee_rate'), 0) AS service_fee_rate,
         NULL::numeric AS display_unit_price,
         CASE
           WHEN $3::numeric IS NOT NULL
             THEN CEIL($3::numeric * (1 + COALESCE((SELECT value::numeric FROM system_config WHERE key = 'marketplace_service_fee_rate'), 0)))::int
           ELSE NULL
         END AS display_unit_tinku_price`,
      [stock, unitPrice ?? null, unitTinkuPrice ?? null]
    );

    return result.rows[0];
  }

  async createPublication(
    userId: string,
    productId: number,
    stock: number,
    unitPrice?: number | null,
    unitTinkuPrice?: number | null,
    paymentMode = "tinkus"
  ) {
    await this.assertProductBusinessCanFulfill(userId, productId);

    const result = await query(
      `SELECT *
       FROM create_product_publication_with_charge($1, $2, $3, $4, $5, $6)`,
      [userId, productId, stock, null, unitTinkuPrice ?? null, "tinkus"]
    );

    return result.rows[0];
  }

  async createPublicationWithoutCharge(
    actorId: string,
    productId: number,
    stock: number,
    unitTinkuPrice?: number | null
  ) {
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");

      const productResult = await client.query(
        `SELECT p.*, b.id AS business_id
         FROM products p
         JOIN businesses b ON b.id = p.business_id
         WHERE p.id = $1
           AND p.status = 'active'
           AND b.status = 'active'
           AND b.validated = true
           AND ${fulfillmentEnabledSql}
         FOR UPDATE OF p`,
        [productId]
      );
      const product = productResult.rows[0];

      if (!product) {
        throw new Error("Business fulfillment must be configured before publishing products");
      }
      if (Number(product.stock ?? 0) < stock) {
        throw new Error("Published stock exceeds available stock");
      }

      const existing = await client.query(
        `SELECT id
         FROM product_publications
         WHERE product_id = $1
           AND status <> 'archived'
         LIMIT 1`,
        [productId]
      );
      if (existing.rowCount) {
        throw new Error("Product already has an open publication");
      }

      const tinkuPrice = unitTinkuPrice ?? Number(product.tinku_price ?? 0);
      if (!Number.isFinite(tinkuPrice) || tinkuPrice <= 0) {
        throw new Error("Tinku price is required");
      }

      const costResult = await client.query(
        "SELECT calculate_product_publication_cost($1, 0, $2) AS cost",
        [stock, tinkuPrice]
      );
      const calculatedCost = Number(costResult.rows[0]?.cost ?? 0);

      await client.query(
        `UPDATE products
         SET tinku_price = $2,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [productId, tinkuPrice]
      );

      const publicationResult = await client.query(
        `INSERT INTO product_publications (
           product_id,
           business_id,
           created_by,
           published_stock,
           unit_price,
           unit_tinku_price,
           payment_mode,
           calculated_cost_tinkus,
           charged_tinkus,
           status
         )
         VALUES ($1, $2, $3, $4, NULL, $5, 'tinkus', $6, 0, $7)
         RETURNING *`,
        [
          productId,
          product.business_id,
          actorId,
          stock,
          tinkuPrice,
          calculatedCost,
          stock === 0 ? "draft" : "active",
        ]
      );
      const publication = publicationResult.rows[0];

      await client.query(
        `INSERT INTO product_publication_history (
           publication_id,
           changed_by,
           previous_stock,
           new_stock,
           previous_cost_tinkus,
           new_cost_tinkus,
           additional_charged_tinkus,
           reason
         )
         VALUES ($1, $2, NULL, $3, NULL, $4, 0, 'initial_publication_admin')`,
        [publication.id, actorId, stock, calculatedCost]
      );

      await client.query("COMMIT");
      return publication;
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  async updatePublicationStock(
    userId: string,
    publicationId: number,
    stock: number,
    unitPrice?: number | null,
    unitTinkuPrice?: number | null,
    paymentMode?: string
  ) {
    await this.assertPublicationBusinessCanFulfill(userId, publicationId);

    const result = await query(
      `SELECT *
       FROM update_product_publication_with_charge($1, $2, $3, $4, $5, $6)`,
      [userId, publicationId, stock, null, unitTinkuPrice ?? null, "tinkus"]
    );

    return result.rows[0];
  }

  async updatePublicationWithoutCharge(
    actorId: string,
    publicationId: number,
    stock: number,
    unitTinkuPrice?: number | null
  ) {
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");

      const currentResult = await client.query(
        `SELECT pp.*, p.stock AS product_stock, p.tinku_price AS product_tinku_price
         FROM product_publications pp
         JOIN products p ON p.id = pp.product_id
         JOIN businesses b ON b.id = pp.business_id
         WHERE pp.id = $1
           AND p.status = 'active'
           AND b.status = 'active'
           AND b.validated = true
           AND ${fulfillmentEnabledSql}
         FOR UPDATE OF pp, p`,
        [publicationId]
      );
      const current = currentResult.rows[0];

      if (!current) {
        throw new Error("Product publication not found");
      }
      if (Number(current.product_stock ?? 0) < stock) {
        throw new Error("Published stock exceeds available stock");
      }

      const tinkuPrice =
        unitTinkuPrice ??
        Number(current.unit_tinku_price ?? current.product_tinku_price ?? 0);
      if (!Number.isFinite(tinkuPrice) || tinkuPrice <= 0) {
        throw new Error("Tinku price is required");
      }

      const costResult = await client.query(
        "SELECT calculate_product_publication_cost($1, 0, $2) AS cost",
        [stock, tinkuPrice]
      );
      const calculatedCost = Number(costResult.rows[0]?.cost ?? 0);

      await client.query(
        `UPDATE products
         SET tinku_price = $2,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [current.product_id, tinkuPrice]
      );

      await client.query(
        `INSERT INTO product_publication_history (
           publication_id,
           changed_by,
           previous_stock,
           new_stock,
           previous_cost_tinkus,
           new_cost_tinkus,
           additional_charged_tinkus,
           reason
         )
         VALUES ($1, $2, $3, $4, $5, $6, 0, 'publication_update_admin')`,
        [
          publicationId,
          actorId,
          current.published_stock,
          stock,
          current.calculated_cost_tinkus,
          calculatedCost,
        ]
      );

      const updated = await client.query(
        `UPDATE product_publications
         SET published_stock = $2,
             unit_price = NULL,
             unit_tinku_price = $3,
             payment_mode = 'tinkus',
             calculated_cost_tinkus = $4,
             status = CASE
               WHEN $2 = 0 THEN 'sold_out'::marketplace_publication_status
               WHEN status = 'sold_out' THEN 'active'::marketplace_publication_status
               ELSE status
             END,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1
         RETURNING *`,
        [publicationId, stock, tinkuPrice, calculatedCost]
      );

      await client.query("COMMIT");
      return updated.rows[0];
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  async updatePublicationStatus(publicationId: number, status: string) {
    const result = await query(
      `UPDATE product_publications
       SET status = $2,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [publicationId, status]
    );

    return result.rows[0] ?? null;
  }

  async publicationHistory(publicationId: number) {
    const result = await query(
      `SELECT h.*, u.username AS changed_by_username
       FROM product_publication_history h
       LEFT JOIN users u ON u.id = h.changed_by
       WHERE h.publication_id = $1
       ORDER BY h.created_at DESC`,
      [publicationId]
    );

    return result.rows;
  }

  async createOrder(userId: string, data: MarketplaceOrderCreateInput) {
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");

      const fingerprint = createHash("sha256").update(JSON.stringify({
        items: [...data.items].sort((a, b) => a.publication_id - b.publication_id),
        payment_method: data.payment_method,
        fulfillment: data.fulfillment,
        pickup_business_id: data.pickup_business_id ?? null,
        warehouse_id: data.warehouse_id ?? null,
        delivery_address: data.delivery_address ?? null,
        delivery_location: data.delivery_location ?? null,
      })).digest("hex");
      await client.query("SELECT pg_advisory_xact_lock(hashtext($1))", [
        `marketplace:${userId}:${data.client_request_id}`,
      ]);
      const previous = await client.query(
        "SELECT id, request_hash FROM marketplace_orders WHERE buyer_id = $1 AND client_request_id = $2",
        [userId, data.client_request_id]
      );
      if (previous.rows[0]) {
        if (previous.rows[0].request_hash !== fingerprint) throw new Error("Idempotency key reused with different data");
        await client.query("COMMIT");
        return this.findOrderById(previous.rows[0].id);
      }

      if (data.payment_method !== "tinkus") {
        throw new Error("Marketplace orders can only be paid with Tinkus");
      }

      const publicationIds = data.items.map((item) => item.publication_id);
      const publications = await client.query(
        `SELECT
           pp.*,
           ROUND((pp.unit_price * (1 + COALESCE(msf.value::numeric, 0)))::numeric, 2) AS display_unit_price,
           CEIL(pp.unit_tinku_price * (1 + COALESCE(msf.value::numeric, 0)))::int AS display_unit_tinku_price,
           p.name AS product_name,
           COALESCE(p.volume_tier, 'small') AS product_volume_tier,
           CASE COALESCE(p.volume_tier, 'small')
             WHEN 'large' THEN COALESCE((SELECT value::int FROM system_config WHERE key = 'warehouse_delivery_reward_large'), 3)
             WHEN 'medium' THEN COALESCE((SELECT value::int FROM system_config WHERE key = 'warehouse_delivery_reward_medium'), 2)
             ELSE COALESCE((SELECT value::int FROM system_config WHERE key = 'warehouse_delivery_reward_small'), 1)
           END AS warehouse_delivery_reward_tinkus,
           b.id AS source_business_id,
           b.owner_id AS business_owner_id
         FROM product_publications pp
         JOIN products p ON p.id = pp.product_id
         JOIN businesses b ON b.id = pp.business_id
         ${serviceFeeJoin}
         WHERE pp.id = ANY($1::bigint[])
           AND pp.status = 'active'
           AND pp.payment_mode = 'tinkus'
           AND pp.unit_tinku_price IS NOT NULL
           AND pp.unit_tinku_price > 0
           AND p.status = 'active'
           AND b.status = 'active'
         FOR UPDATE OF pp`,
        [publicationIds]
      );

      if (publications.rowCount !== new Set(publicationIds).size) {
        throw new Error("Invalid marketplace publication");
      }

      const byId = new Map<number, any>();
      publications.rows.forEach((row) => byId.set(Number(row.id), row));

      if (publications.rows.some((row) => row.business_owner_id === userId)) {
        throw new Error("Cannot buy your own product");
      }

      const sourceBusinessIds = [
        ...new Set(publications.rows.map((row) => Number(row.business_id))),
      ];
      const productIds = [
        ...new Set(publications.rows.map((row) => Number(row.product_id))),
      ];
      const warehouseInventoryByProduct = new Map<number, any>();

      if (data.fulfillment === "pickup") {
        if (
          sourceBusinessIds.length !== 1 ||
          sourceBusinessIds[0] !== data.pickup_business_id
        ) {
          throw new Error("Invalid pickup business");
        }

        const pickup = await client.query(
          `SELECT 1
           FROM business_fulfillment_options
           WHERE business_id = $1
             AND pickup_in_store = true
           LIMIT 1`,
          [data.pickup_business_id]
        );

        if (!pickup.rowCount) {
          throw new Error("Pickup is not available for this business");
        }
      }

      if (data.fulfillment === "warehouse_delivery") {
        const warehouse = await client.query(
          `SELECT 1
           FROM warehouses
           WHERE id = $1
             AND status = 'active'
             AND validated = true
           LIMIT 1`,
          [data.warehouse_id]
        );

        if (!warehouse.rowCount) {
          throw new Error("Warehouse not found");
        }

        const enabled = await client.query(
          `SELECT COUNT(DISTINCT bw.business_id)::int AS total
           FROM business_warehouses bw
           JOIN business_fulfillment_options bfo
             ON bfo.business_id = bw.business_id
           WHERE bw.warehouse_id = $1
             AND bw.business_id = ANY($2::bigint[])
             AND bw.status = 'active'
             AND bfo.warehouse_delivery = true`,
          [data.warehouse_id, sourceBusinessIds]
        );

        if (enabled.rows[0]?.total !== sourceBusinessIds.length) {
          throw new Error("Warehouse delivery is not available for this order");
        }

        const inventory = await client.query(
          `SELECT product_id, quantity, reserved_quantity
           FROM warehouse_inventory
           WHERE warehouse_id = $1
             AND product_id = ANY($2::bigint[])
             AND status = 'available'
           FOR UPDATE`,
          [data.warehouse_id, productIds]
        );

        inventory.rows.forEach((row) => {
          warehouseInventoryByProduct.set(Number(row.product_id), row);
        });
      }

      let totalAmount = 0;
      let totalTinkus = 0;
      let warehouseDeliveryFeeTinkus = 0;
      const requestedByPublication = new Map<number, number>();
      const requestedByWarehouseProduct = new Map<number, number>();
      const sellerPayouts = new Map<string, number>();

      for (const item of data.items) {
        const publication = byId.get(item.publication_id);
        const publicationRequested =
          (requestedByPublication.get(item.publication_id) ?? 0) +
          item.quantity;
        requestedByPublication.set(item.publication_id, publicationRequested);

        if (!publication || publication.published_stock < publicationRequested) {
          throw new Error("Insufficient published stock");
        }

        if (data.fulfillment === "warehouse_delivery") {
          const productId = Number(publication.product_id);
          const inventory = warehouseInventoryByProduct.get(productId);
          const available =
            Number(inventory?.quantity ?? 0) -
            Number(inventory?.reserved_quantity ?? 0);
          const warehouseRequested =
            (requestedByWarehouseProduct.get(productId) ?? 0) + item.quantity;
          requestedByWarehouseProduct.set(productId, warehouseRequested);

          if (warehouseRequested > available) {
            throw new Error("Insufficient warehouse stock");
          }
        }

        totalAmount += Number(publication.display_unit_price ?? 0) * item.quantity;
        totalTinkus += Number(publication.display_unit_tinku_price ?? 0) * item.quantity;

        const sellerId = publication.business_owner_id as string | null;
        if (!sellerId) {
          throw new Error("Marketplace seller not found");
        }

        const sellerSubtotal =
          Number(publication.unit_tinku_price ?? 0) * item.quantity;
        sellerPayouts.set(
          sellerId,
          (sellerPayouts.get(sellerId) ?? 0) + sellerSubtotal
        );

        if (data.fulfillment === "warehouse_delivery") {
          warehouseDeliveryFeeTinkus +=
            Number(publication.warehouse_delivery_reward_tinkus ?? 0) *
            item.quantity;
        }
      }

      if (sellerPayouts.size !== 1) {
        throw new Error("Marketplace orders must belong to one business");
      }
      const [sellerId, sellerAmountTinkus] = sellerPayouts.entries().next().value!;

      if (sellerAmountTinkus <= 0) {
        throw new Error("Invalid marketplace seller payout");
      }

      totalTinkus += warehouseDeliveryFeeTinkus;

      if (data.payment_method === "tinkus" && totalTinkus <= 0) {
        throw new Error("This publication cannot be paid with Tinkus");
      }

      const order = await client.query(
        `INSERT INTO marketplace_orders (
           buyer_id,
           status,
           payment_method,
           pickup_code,
           total_amount,
           total_tinkus,
           warehouse_delivery_fee_tinkus,
           fulfillment,
           pickup_business_id,
           warehouse_id,
           delivery_address,
           delivery_location,
           seller_id,
           seller_amount_tinkus,
           created_at,
           updated_at
         )
         VALUES (
           $1,
           $2,
           $3,
           $4,
           $5,
           $6,
           $7,
           $8,
           $9,
           $10,
           $11,
           CASE
             WHEN $12::numeric IS NULL OR $13::numeric IS NULL THEN NULL
             ELSE ST_SetSRID(ST_MakePoint($13, $12), 4326)::geography
           END,
           $14,
           $15,
           CURRENT_TIMESTAMP,
           CURRENT_TIMESTAMP
         )
         RETURNING *`,
        [
          userId,
          "paid",
          "tinkus",
          generatePickupCode(),
          totalAmount,
          totalTinkus,
          warehouseDeliveryFeeTinkus,
          data.fulfillment,
          data.pickup_business_id ?? null,
          data.warehouse_id ?? null,
          data.delivery_address ?? null,
          data.delivery_location?.latitude ?? null,
          data.delivery_location?.longitude ?? null,
          sellerId,
          sellerAmountTinkus,
        ]
      );

      const spend = await client.query(
        `SELECT perform_tinku_spend($1, $2, $3, $4, $5) AS transaction_id`,
        [
          userId,
          totalTinkus,
          "marketplace_order",
          order.rows[0].id,
          `Compra marketplace #${order.rows[0].id}`,
        ]
      );

      await client.query(
        "UPDATE marketplace_orders SET client_request_id = $2, request_hash = $3 WHERE id = $1",
        [order.rows[0].id, data.client_request_id, fingerprint]
      );

      await client.query(
        `UPDATE marketplace_orders
         SET payment_transaction_id = $2,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [order.rows[0].id, spend.rows[0]?.transaction_id ?? null]
      );

      for (const item of data.items) {
        const publication = byId.get(item.publication_id);
        const subtotalAmount =
          Number(publication.display_unit_price ?? 0) * item.quantity;
        const subtotalTinkus =
          Number(publication.display_unit_tinku_price ?? 0) * item.quantity;
        const warehouseRewardTinkus =
          data.fulfillment === "warehouse_delivery"
            ? Number(publication.warehouse_delivery_reward_tinkus ?? 0) *
              item.quantity
            : 0;

        await client.query(
          `INSERT INTO marketplace_order_items (
             order_id,
             publication_id,
             product_id,
             business_id,
             quantity,
             unit_price,
             unit_tinku_price,
             subtotal_amount,
             subtotal_tinkus,
             warehouse_reward_tinkus,
             created_at
           )
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP)`,
          [
            order.rows[0].id,
            publication.id,
            publication.product_id,
            publication.business_id,
            item.quantity,
            publication.display_unit_price,
            publication.display_unit_tinku_price,
            subtotalAmount,
            subtotalTinkus,
            warehouseRewardTinkus,
          ]
        );

        await client.query(
          `UPDATE product_publications
           SET published_stock = published_stock - $2,
               status = CASE
                 WHEN published_stock - $2 <= 0 THEN 'sold_out'
                 ELSE status
               END,
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $1`,
          [publication.id, item.quantity]
        );

        if (data.fulfillment === "warehouse_delivery" && data.warehouse_id) {
          await client.query(
            `UPDATE warehouse_inventory
             SET reserved_quantity = reserved_quantity + $3,
                 updated_at = CURRENT_TIMESTAMP
             WHERE warehouse_id = $1
               AND product_id = $2`,
            [data.warehouse_id, publication.product_id, item.quantity]
          );
        }
      }

      if (data.fulfillment === "warehouse_delivery" && data.warehouse_id) {
        await client.query(
          `INSERT INTO deliveries (
             order_id,
             warehouse_id,
             status,
             reward_tinkus,
             created_at,
             updated_at
           )
           VALUES ($1, $2, 'pending', $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
          [order.rows[0].id, data.warehouse_id, warehouseDeliveryFeeTinkus]
        );
      }

      await client.query(
        `INSERT INTO notifications (user_id, title, message, type, entity_type, entity_id, route)
         VALUES ($1, 'Compra confirmada', 'Tu pedido marketplace #' || $3::text || ' fue confirmado.',
                 'marketplace_order', 'marketplace_order', $3::bigint, '/myMarketplaceOrders'),
                ($2, 'Nueva venta', 'Recibiste el pedido marketplace #' || $3::text || '.',
                 'marketplace_order', 'marketplace_order', $3::bigint, '/marketplaceSalesOrders')`,
        [userId, sellerId, order.rows[0].id]
      );
      await client.query("COMMIT");
      return this.findOrderById(order.rows[0].id);
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  async findOrderById(id: number) {
    const order = await query(
      `SELECT *
       FROM marketplace_orders
       WHERE id = $1
       LIMIT 1`,
      [id]
    );

    if (!order.rows[0]) return null;

    const items = await query(
      `SELECT oi.*, p.name AS product_name, b.name AS business_name
       FROM marketplace_order_items oi
       JOIN products p ON p.id = oi.product_id
       JOIN businesses b ON b.id = oi.business_id
       WHERE oi.order_id = $1
       ORDER BY oi.id ASC`,
      [id]
    );

    const deliveries = await query(
      `SELECT *
       FROM deliveries
       WHERE order_id = $1
       ORDER BY created_at DESC`,
      [id]
    );

    return {
      ...order.rows[0],
      items: items.rows,
      deliveries: deliveries.rows,
    };
  }

  async listMyOrders(userId: string, limit: number, offset: number) {
    const result = await query(
      `SELECT
         mo.*,
         pb.name AS pickup_business_name,
         pb.address AS pickup_business_address,
         w.name AS warehouse_name,
         w.address AS warehouse_address,
         COALESCE(items.items, '[]'::json) AS items,
         COALESCE(deliveries.deliveries, '[]'::json) AS deliveries
       FROM marketplace_orders mo
       LEFT JOIN businesses pb ON pb.id = mo.pickup_business_id
       LEFT JOIN warehouses w ON w.id = mo.warehouse_id
       LEFT JOIN LATERAL (
         SELECT json_agg(
           json_build_object(
             'id', oi.id,
             'publication_id', oi.publication_id,
             'product_id', oi.product_id,
             'business_id', oi.business_id,
             'product_name', p.name,
             'business_name', b.name,
             'quantity', oi.quantity,
             'unit_price', oi.unit_price,
             'unit_tinku_price', oi.unit_tinku_price,
             'subtotal_amount', oi.subtotal_amount,
             'subtotal_tinkus', oi.subtotal_tinkus,
             'warehouse_reward_tinkus', oi.warehouse_reward_tinkus
           )
           ORDER BY oi.id ASC
         ) AS items
         FROM marketplace_order_items oi
         JOIN products p ON p.id = oi.product_id
         JOIN businesses b ON b.id = oi.business_id
         WHERE oi.order_id = mo.id
       ) items ON true
       LEFT JOIN LATERAL (
         SELECT json_agg(
           json_build_object(
             'id', d.id,
             'warehouse_id', d.warehouse_id,
             'status', d.status,
             'reward_tinkus', d.reward_tinkus,
             'picked_up_at', d.picked_up_at,
             'delivered_at', d.delivered_at,
             'created_at', d.created_at,
             'updated_at', d.updated_at
           )
           ORDER BY d.created_at DESC
         ) AS deliveries
         FROM deliveries d
         WHERE d.order_id = mo.id
       ) deliveries ON true
       WHERE mo.buyer_id = $1
       ORDER BY mo.created_at DESC
       LIMIT $2
       OFFSET $3`,
      [userId, limit, offset]
    );

    return result.rows;
  }

  async listSalesOrders(
    userId: string,
    status: string | undefined,
    limit: number,
    offset: number
  ) {
    const params: unknown[] = [userId];
    const statusFilter = status ? `AND mo.status = $${params.push(status)}` : "";
    params.push(limit, offset);

    const result = await query(
      `SELECT
         mo.*,
         u.username AS buyer_username,
         NULLIF(TRIM(CONCAT_WS(' ', u.first_name, u.last_name)), '') AS buyer_name,
         pb.name AS pickup_business_name,
         pb.address AS pickup_business_address,
         w.name AS warehouse_name,
         w.address AS warehouse_address,
         COALESCE(items.items, '[]'::json) AS items,
         COALESCE(deliveries.deliveries, '[]'::json) AS deliveries
       FROM marketplace_orders mo
       JOIN users u ON u.id = mo.buyer_id
       LEFT JOIN businesses pb ON pb.id = mo.pickup_business_id
       LEFT JOIN warehouses w ON w.id = mo.warehouse_id
       JOIN LATERAL (
         SELECT json_agg(
           json_build_object(
             'id', oi.id,
             'publication_id', oi.publication_id,
             'product_id', oi.product_id,
             'business_id', oi.business_id,
             'product_name', p.name,
             'business_name', b.name,
             'quantity', oi.quantity,
             'unit_price', oi.unit_price,
             'unit_tinku_price', oi.unit_tinku_price,
             'subtotal_amount', oi.subtotal_amount,
             'subtotal_tinkus', oi.subtotal_tinkus,
             'warehouse_reward_tinkus', oi.warehouse_reward_tinkus
           ) ORDER BY oi.id ASC
         ) AS items
         FROM marketplace_order_items oi
         JOIN products p ON p.id = oi.product_id
         JOIN businesses b ON b.id = oi.business_id
         WHERE oi.order_id = mo.id
           AND b.owner_id = $1
       ) items ON items.items IS NOT NULL
       LEFT JOIN LATERAL (
         SELECT json_agg(
           json_build_object(
             'id', d.id,
             'warehouse_id', d.warehouse_id,
             'status', d.status,
             'reward_tinkus', d.reward_tinkus,
             'picked_up_at', d.picked_up_at,
             'delivered_at', d.delivered_at,
             'created_at', d.created_at,
             'updated_at', d.updated_at
           ) ORDER BY d.created_at DESC
         ) AS deliveries
         FROM deliveries d
         WHERE d.order_id = mo.id
       ) deliveries ON true
       WHERE EXISTS (
         SELECT 1
         FROM marketplace_order_items owned_item
         JOIN businesses owned_business ON owned_business.id = owned_item.business_id
         WHERE owned_item.order_id = mo.id
           AND owned_business.owner_id = $1
       )
       ${statusFilter}
       ORDER BY mo.created_at DESC
       LIMIT $${params.length - 1}
       OFFSET $${params.length}`,
      params
    );

    return result.rows;
  }

  async updateSalesOrderStatus(id: number, userId: string, status: string) {
    const result = await query(
      `UPDATE marketplace_orders mo
       SET status = $3::marketplace_order_status,
           pickup_expires_at = CASE
             WHEN $3 = 'ready_for_pickup' THEN CURRENT_TIMESTAMP +
               COALESCE(
                 (SELECT value::int FROM system_config WHERE key = 'marketplace_pickup_expiration_days'),
                 7
               ) * INTERVAL '1 day'
             ELSE mo.pickup_expires_at
           END,
           updated_at = CURRENT_TIMESTAMP
       WHERE mo.id = $1
         AND (
           (mo.status = 'paid' AND $3 = 'preparing')
           OR (
             mo.status = 'preparing'
             AND $3 = 'ready_for_pickup'
             AND mo.fulfillment = 'pickup'
           )
         )
         AND NOT EXISTS (
           SELECT 1
           FROM marketplace_order_items oi
           JOIN businesses b ON b.id = oi.business_id
           WHERE oi.order_id = mo.id
             AND b.owner_id IS DISTINCT FROM $2::uuid
         )
       RETURNING mo.*`,
      [id, userId, status]
    );

    return result.rows[0] ?? null;
  }

  async listWarehouseOrders(userId: string, limit: number, offset: number) {
    const result = await query(
      `SELECT mo.*, w.name AS warehouse_name, w.address AS warehouse_address,
              u.username AS buyer_username,
              COALESCE((SELECT json_agg(to_jsonb(oi) || jsonb_build_object('product_name', p.name, 'business_name', b.name))
                        FROM marketplace_order_items oi JOIN products p ON p.id = oi.product_id
                        JOIN businesses b ON b.id = oi.business_id
                        WHERE oi.order_id = mo.id), '[]'::json) AS items
       FROM marketplace_orders mo JOIN warehouses w ON w.id = mo.warehouse_id
       JOIN users u ON u.id = mo.buyer_id
       WHERE w.owner_id = $1 AND mo.fulfillment = 'warehouse_delivery'
       ORDER BY mo.created_at DESC, mo.id DESC LIMIT $2 OFFSET $3`, [userId, limit, offset]
    );
    return result.rows;
  }

  async markWarehouseOrderReady(id: number, userId: string) {
    const result = await query(
      `UPDATE marketplace_orders mo SET status = 'ready_for_pickup',
         pickup_expires_at = CURRENT_TIMESTAMP +
           GREATEST(COALESCE((SELECT value::int FROM system_config WHERE key = 'marketplace_pickup_expiration_days'), 7), 1) * INTERVAL '1 day'
       WHERE mo.id = $1 AND mo.status IN ('paid', 'preparing', 'in_delivery')
         AND mo.fulfillment = 'warehouse_delivery'
         AND EXISTS (SELECT 1 FROM warehouses w WHERE w.id = mo.warehouse_id AND w.owner_id = $2)
       RETURNING mo.*`, [id, userId]
    );
    return result.rows[0] ?? null;
  }

  async expirePickups() {
    const due = await query<{ id: number; buyer_id: string }>(
      `SELECT id, buyer_id FROM marketplace_orders
       WHERE status = 'ready_for_pickup' AND pickup_expires_at <= CURRENT_TIMESTAMP
       ORDER BY pickup_expires_at LIMIT 50`
    );
    for (const order of due.rows) {
      try {
        await this.cancelOrder(order.id, order.buyer_id, "Plazo de retiro vencido", "not_collected", "buyer");
      } catch (error) {
        console.warn("Pickup expiration deferred", { orderId: order.id, error });
      }
    }
  }

  async listAdminOrders(status: string | undefined, limit: number, offset: number) {
    const params: unknown[] = [];
    const where = status ? "WHERE status = $1" : "";

    if (status) params.push(status);
    params.push(limit, offset);

    const result = await query(
      `SELECT *
       FROM marketplace_orders
       ${where}
       ORDER BY created_at DESC
       LIMIT $${params.length - 1}
       OFFSET $${params.length}`,
      params
    );

    return result.rows;
  }

  async updateOrderStatus(id: number, status: string) {
    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");
      const result = await client.query(
        `UPDATE marketplace_orders
         SET status = $2::marketplace_order_status,
             pickup_expires_at = CASE
               WHEN $2 = 'ready_for_pickup' THEN CURRENT_TIMESTAMP +
                 COALESCE(
                   (SELECT value::int FROM system_config WHERE key = 'marketplace_pickup_expiration_days'),
                   7
                 ) * INTERVAL '1 day'
               ELSE pickup_expires_at
             END,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1
           AND (
             (status = 'paid' AND $2 IN ('preparing', 'ready_for_pickup', 'in_delivery'))
             OR (status = 'preparing' AND $2 IN ('ready_for_pickup', 'in_delivery'))
             OR (status = 'in_delivery' AND $2 = 'ready_for_pickup')
           )
         RETURNING *`,
        [id, status]
      );

      if (!result.rows[0]) {
        await client.query("ROLLBACK");
        return null;
      }

      const updated = result.rows[0];

      await client.query("COMMIT");
      return updated;
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  cancelOrderByBuyer(id: number, userId: string) {
    return this.cancelOrder(
      id,
      userId,
      "Cancelado por el comprador",
      "buyer_cancelled",
      "buyer"
    );
  }

  rejectOrderBySeller(
    id: number,
    userId: string,
    reason: string,
    allowAny = false
  ) {
    return this.cancelOrder(
      id,
      userId,
      reason,
      allowAny ? "admin_cancelled" : "seller_rejected",
      "seller",
      allowAny
    );
  }

  private async cancelOrder(
    id: number,
    userId: string,
    reason: string,
    incidentType: "buyer_cancelled" | "seller_rejected" | "admin_cancelled" | "not_collected",
    actorType: "buyer" | "seller",
    allowAny = false
  ) {
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");

      const order = await client.query(
        `SELECT *
         FROM marketplace_orders
         WHERE id = $1
           AND payment_method = 'tinkus'
           AND (
             ($3 = 'buyer' AND buyer_id = $2 AND (
               status = 'paid' OR (status = 'ready_for_pickup' AND pickup_expires_at <= CURRENT_TIMESTAMP)
             ))
             OR (
               $3 = 'seller'
               AND status IN ('paid', 'preparing')
               AND (
                 $4::boolean
                 OR EXISTS (
                 SELECT 1
                 FROM marketplace_order_items oi
                 JOIN businesses b ON b.id = oi.business_id
                 WHERE oi.order_id = marketplace_orders.id
                   AND b.owner_id = $2
                 )
               )
             )
           )
         FOR UPDATE`,
        [id, userId, actorType, allowAny]
      );

      if (!order.rows[0]) {
        throw new Error("Marketplace order not found");
      }

      const sellerTransactions = await client.query(
        `SELECT *
         FROM financial_transactions
         WHERE reference_id = $1
           AND purpose = 'marketplace_sale'
           AND type = 'reward'
           AND status = 'approved'
         FOR UPDATE`,
        [id]
      );

      for (const tx of sellerTransactions.rows) {
        const debited = await client.query(
          `UPDATE wallets
           SET balance = balance - $2,
               updated_at = CURRENT_TIMESTAMP
           WHERE user_id = $1
             AND balance >= $2
           RETURNING user_id`,
          [tx.user_id, tx.amount]
        );
        if (!debited.rows[0]) {
          throw new Error("Seller balance is insufficient to cancel this order");
        }
        await client.query(
          `UPDATE financial_transactions
           SET status = 'reversed',
               description = $2,
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $1`,
          [tx.id, `Venta marketplace #${id} cancelada`]
        );
      }

      if (!order.rows[0].payment_transaction_id) {
        throw new Error("Marketplace payment transaction not found");
      }
      await client.query("SELECT reverse_tinku_charge($1, $2)", [
        order.rows[0].payment_transaction_id,
        `Compra marketplace #${id} cancelada`,
      ]);

      await client.query(
        `UPDATE product_publications pp
         SET published_stock = pp.published_stock + oi.quantity,
             status = CASE
               WHEN pp.status = 'sold_out' THEN 'active'::marketplace_publication_status
               ELSE pp.status
             END,
             updated_at = CURRENT_TIMESTAMP
         FROM marketplace_order_items oi
         WHERE oi.order_id = $1
           AND oi.publication_id = pp.id`,
        [id]
      );

      await client.query(
        `UPDATE warehouse_inventory wi
         SET reserved_quantity = GREATEST(
               wi.reserved_quantity - order_items.total_quantity,
               0
             ),
             updated_at = CURRENT_TIMESTAMP
         FROM (
           SELECT mo.warehouse_id, oi.product_id, SUM(oi.quantity)::int AS total_quantity
           FROM marketplace_orders mo
           JOIN marketplace_order_items oi ON oi.order_id = mo.id
           WHERE mo.id = $1
             AND mo.warehouse_id IS NOT NULL
           GROUP BY mo.warehouse_id, oi.product_id
         ) order_items
         WHERE wi.warehouse_id = order_items.warehouse_id
           AND wi.product_id = order_items.product_id`,
        [id]
      );

      await client.query(
        `UPDATE deliveries
         SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
         WHERE order_id = $1 AND status <> 'delivered'`,
        [id]
      );

      const cancelled = await client.query(
        `UPDATE marketplace_orders
         SET status = 'cancelled',
             cancellation_reason = $2,
             cancelled_by = $3,
             cancelled_at = CURRENT_TIMESTAMP,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1
         RETURNING *`,
        [id, reason, userId]
      );

      await client.query(
        `INSERT INTO marketplace_order_incidents (
           order_id,
           created_by,
           type,
           reason,
           status,
           resolved_at,
           created_at,
           updated_at
         )
         VALUES ($1, $2, $3, $4, 'resolved', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
        [id, userId, incidentType, reason]
      );

      await client.query(
        `SELECT write_audit_log(
           $1,
           $2,
           'marketplace_order',
           $3,
           jsonb_build_object('reason', $4::text, 'refund_transaction_id', $5::bigint)
         )`,
        [
          userId,
          incidentType === "buyer_cancelled"
            ? "marketplace_order_cancelled"
            : incidentType === "not_collected"
              ? "marketplace_pickup_expired"
            : incidentType === "seller_rejected"
              ? "marketplace_order_rejected"
              : "marketplace_order_admin_cancelled",
          id,
          reason,
          order.rows[0].payment_transaction_id,
        ]
      );

      await client.query(
        `INSERT INTO notifications (user_id, title, message, type, entity_type, entity_id, route)
         SELECT buyer_id, 'Pedido cancelado', 'Pedido #' || id::text || ': ' || $2::text || '. Tus Tinkus fueron devueltos.',
                'marketplace_order', 'marketplace_order', id, '/myMarketplaceOrders'
         FROM marketplace_orders WHERE id = $1`, [id, reason]
      );

      await client.query("COMMIT");
      return cancelled.rows[0];
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  async updateDeliveryStatus(id: number, status: string) {
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");
      const current = await client.query(
        `SELECT *
         FROM deliveries
         WHERE id = $1
         FOR UPDATE`,
        [id]
      );

      if (!current.rows[0]) {
        throw new Error("Delivery not found");
      }

      const wasDelivered = current.rows[0].status === "delivered";
      if (status === "delivered" || status === "cancelled" || wasDelivered || current.rows[0].status === "cancelled") {
        throw new Error("Invalid marketplace order transition");
      }
      const transitions: Record<string, string[]> = {
        pending: ["assigned", "picked_up"], assigned: ["picked_up"], picked_up: [],
      };
      if (!transitions[current.rows[0].status]?.includes(status)) throw new Error("Invalid marketplace order transition");

      const delivery = await client.query(
        `UPDATE deliveries
         SET status = $2,
             picked_up_at = CASE WHEN $2 = 'picked_up' THEN CURRENT_TIMESTAMP ELSE picked_up_at END,
             delivered_at = CASE WHEN $2 = 'delivered' THEN CURRENT_TIMESTAMP ELSE delivered_at END,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1
         RETURNING *`,
        [id, status]
      );

      await client.query("COMMIT");
      return delivery.rows[0];
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  async validatePickupCode(code: string, actor: { id: string; role?: string }) {
    const normalizedCode = code.trim().toUpperCase();
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");

      const orderResult = await client.query(
        `SELECT
           mo.*,
           (mo.pickup_expires_at <= CURRENT_TIMESTAMP) AS pickup_expired,
           pb.owner_id AS pickup_owner_id,
           w.owner_id AS warehouse_owner_id
         FROM marketplace_orders mo
         LEFT JOIN businesses pb ON pb.id = mo.pickup_business_id
         LEFT JOIN warehouses w ON w.id = mo.warehouse_id
         WHERE mo.pickup_code = $1
         FOR UPDATE OF mo`,
        [normalizedCode]
      );
      const order = orderResult.rows[0];

      if (!order) throw new Error("Marketplace order not found");
      if (order.status === "delivered") {
        throw new Error("Marketplace order already delivered");
      }
      if (order.status === "pending") {
        throw new Error("Marketplace order is not paid");
      }
      if (order.status === "cancelled") {
        throw new Error("Marketplace order cancelled");
      }
      if (order.status !== "ready_for_pickup") throw new Error("Marketplace order is not ready for pickup");
      if (!order.pickup_expires_at || order.pickup_expired) {
        throw new Error("Marketplace pickup expired");
      }

      const privileged = actor.role === "admin" || actor.role === "master";
      const ownsPickup =
        order.fulfillment === "pickup" && order.pickup_owner_id === actor.id;
      const ownsWarehouse =
        order.fulfillment === "warehouse_delivery" &&
        order.warehouse_owner_id === actor.id;

      if (!privileged && !ownsPickup && !ownsWarehouse) {
        throw new Error("Unauthorized");
      }

      const updatedOrder = await client.query(
        `UPDATE marketplace_orders
         SET status = 'delivered',
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1
         RETURNING *`,
        [order.id]
      );

      if (order.fulfillment === "warehouse_delivery") {
        await this.consumeWarehouseOrderInventory(
          client,
          Number(order.id),
          Number(order.warehouse_id)
        );

        await client.query(
          `UPDATE deliveries
           SET status = 'delivered',
               delivered_at = COALESCE(delivered_at, CURRENT_TIMESTAMP),
               updated_at = CURRENT_TIMESTAMP
           WHERE order_id = $1
             AND status <> 'delivered'`,
          [order.id]
        );
      }

      await this.settleMarketplaceOrder(client, Number(order.id));

      if (order.fulfillment === "warehouse_delivery") {
        const delivery = await client.query(
          `SELECT id
           FROM deliveries
           WHERE order_id = $1
           ORDER BY created_at DESC
           LIMIT 1`,
          [order.id]
        );
        if (delivery.rows[0]?.id) {
          await client.query("SELECT * FROM reward_warehouse_delivery($1)", [
            delivery.rows[0].id,
          ]);
        }
      }

      await client.query(
        `INSERT INTO notifications(user_id, title, message, type, entity_type, entity_id, route)
         SELECT buyer_id, 'Pedido entregado', 'La entrega del pedido #' || id::text || ' fue confirmada.',
                'marketplace_order', 'marketplace_order', id, '/myMarketplaceOrders'
         FROM marketplace_orders WHERE id = $1
         UNION ALL
         SELECT seller_id, 'Venta acreditada', 'Se acreditaron ' || seller_amount_tinkus::text || ' Tinkus por el pedido #' || id::text || '.',
                'marketplace_order', 'marketplace_order', id, '/marketplaceSalesOrders'
         FROM marketplace_orders WHERE id = $1`, [order.id]
      );
      await client.query("COMMIT");

      return this.findOrderById(updatedOrder.rows[0].id);
    } catch (error) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw error;
    } finally {
      client.release();
    }
  }

  async registerBusinessView(businessId: number) {
    await query("SELECT register_business_view($1)", [businessId]);
  }

  async getBusinessViewStats(businessId: number, days: number) {
    const totals = await query(
      `SELECT *
       FROM business_view_totals
       WHERE business_id = $1`,
      [businessId]
    );

    const daily = await query(
      `SELECT day, views_count
       FROM business_view_daily
       WHERE business_id = $1
       ORDER BY day DESC
       LIMIT $2`,
      [businessId, days]
    );

    return {
      total: totals.rows[0]?.total_views ?? 0,
      last_viewed_at: totals.rows[0]?.last_viewed_at ?? null,
      daily: daily.rows,
    };
  }

  async getBusinessViewStatsBatch(businessIds: number[], ownerId?: string) {
    if (businessIds.length === 0) return {};

    const params: unknown[] = [businessIds];
    const ownerFilter = ownerId ? "AND b.owner_id = $2" : "";
    if (ownerId) params.push(ownerId);

    const result = await query<{ business_id: number; total_views: number }>(
      `SELECT b.id AS business_id, COALESCE(bvt.total_views, 0) AS total_views
       FROM businesses b
       LEFT JOIN business_view_totals bvt ON bvt.business_id = b.id
       WHERE b.id = ANY($1::bigint[])
       ${ownerFilter}`,
      params
    );

    return Object.fromEntries(
      result.rows.map((row) => [Number(row.business_id), Number(row.total_views)])
    );
  }

  private async assertProductBusinessCanFulfill(userId: string, productId: number) {
    const result = await query(
      `SELECT b.id
       FROM products p
       JOIN businesses b ON b.id = p.business_id
       WHERE p.id = $1
         AND b.owner_id = $2
         AND b.status = 'active'
         AND ${fulfillmentEnabledSql}
       LIMIT 1`,
      [productId, userId]
    );

    if (!result.rowCount) {
      throw new Error("Business fulfillment must be configured before publishing products");
    }
  }

  private async assertPublicationBusinessCanFulfill(
    userId: string,
    publicationId: number
  ) {
    const result = await query(
      `SELECT b.id
       FROM product_publications pp
       JOIN products p ON p.id = pp.product_id
       JOIN businesses b ON b.id = pp.business_id
       WHERE pp.id = $1
         AND b.owner_id = $2
         AND b.status = 'active'
         AND ${fulfillmentEnabledSql}
       LIMIT 1`,
      [publicationId, userId]
    );

    if (!result.rowCount) {
      throw new Error("Business fulfillment must be configured before publishing products");
    }
  }

  private async settleMarketplaceOrder(client: PoolClient, orderId: number) {
    const result = await client.query(
      "SELECT * FROM settle_marketplace_order($1)",
      [orderId]
    );
    return result.rows[0];
  }

  private async consumeWarehouseOrderInventory(
    client: PoolClient,
    orderId: number,
    warehouseId: number
  ) {
    await client.query(
      `UPDATE warehouse_inventory wi
       SET quantity = GREATEST(wi.quantity - order_items.total_quantity, 0),
           reserved_quantity = GREATEST(
             wi.reserved_quantity - order_items.total_quantity,
             0
           ),
           status = CASE
             WHEN GREATEST(wi.quantity - order_items.total_quantity, 0) <= 0
               THEN 'reserved'::warehouse_inventory_status
             ELSE wi.status
           END,
           updated_at = CURRENT_TIMESTAMP
       FROM (
         SELECT product_id, SUM(quantity)::int AS total_quantity
         FROM marketplace_order_items
         WHERE order_id = $1
         GROUP BY product_id
       ) order_items
       WHERE wi.warehouse_id = $2
         AND wi.product_id = order_items.product_id`,
      [orderId, warehouseId]
    );
  }
}

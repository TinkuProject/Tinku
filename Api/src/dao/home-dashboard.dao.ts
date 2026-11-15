import { query } from "../config/database.config";
import { UserRole } from "../constants/enums.constants";

export type PartnerHomeSummary = {
  total_sales: number;
  active_sales: number;
  delivered_sales: number;
  active_publications: number;
  sold_out_publications: number;
  pending_tasks: number;
};

export type WarehouseHomeSummary = {
  owned: number;
  pending_receptions: number;
  incoming_shipments: number;
  pending_deliveries: number;
};

export type AdminHomeSummary = {
  businesses: number;
  events: number;
  warehouses: number;
  claims: number;
  total: number;
};

export class HomeDashboardDAO {
  async getPartnerSummary(
    userId: string,
    role: UserRole
  ): Promise<{
    partner: PartnerHomeSummary;
    warehouse: WarehouseHomeSummary;
  }> {
    const result = await query<PartnerHomeSummary & WarehouseHomeSummary>(
      `SELECT
         (
           SELECT COUNT(DISTINCT mo.id)
           FROM marketplace_orders mo
           JOIN marketplace_order_items moi ON moi.order_id = mo.id
           JOIN businesses b ON b.id = moi.business_id
           WHERE b.owner_id = $1
             AND mo.status <> 'cancelled'
         )::int AS total_sales,
         (
           SELECT COUNT(DISTINCT mo.id)
           FROM marketplace_orders mo
           JOIN marketplace_order_items moi ON moi.order_id = mo.id
           JOIN businesses b ON b.id = moi.business_id
           WHERE b.owner_id = $1
             AND mo.status IN ('paid', 'preparing', 'ready_for_pickup', 'in_delivery')
         )::int AS active_sales,
         (
           SELECT COUNT(DISTINCT mo.id)
           FROM marketplace_orders mo
           JOIN marketplace_order_items moi ON moi.order_id = mo.id
           JOIN businesses b ON b.id = moi.business_id
           WHERE b.owner_id = $1
             AND mo.status = 'delivered'
         )::int AS delivered_sales,
         (
           SELECT COUNT(*)
           FROM product_publications pp
           JOIN businesses b ON b.id = pp.business_id
           WHERE b.owner_id = $1
             AND pp.status = 'active'
         )::int AS active_publications,
         (
           SELECT COUNT(*)
           FROM product_publications pp
           JOIN businesses b ON b.id = pp.business_id
           WHERE b.owner_id = $1
             AND pp.status = 'sold_out'
         )::int AS sold_out_publications,
         (
           (SELECT COUNT(*) FROM businesses WHERE owner_id = $1 AND (status = 'pending' OR validated = false))
           + (SELECT COUNT(*) FROM events WHERE creator_id = $1 AND status = 'pending')
           + (SELECT COUNT(*) FROM warehouses WHERE owner_id = $1 AND status = 'pending')
           + (SELECT COUNT(*) FROM entity_updates WHERE creator_id = $1 AND status = 'pending')
           + (
               SELECT COUNT(*)
               FROM warehouse_stock_requests wsr
               JOIN businesses b ON b.id = wsr.business_id
               WHERE b.owner_id = $1 AND wsr.status = 'approved'
             )
         )::int AS pending_tasks,
         (
           SELECT COUNT(*) FROM warehouses WHERE owner_id = $1 AND status <> 'archived'
         )::int AS owned,
         (
           SELECT COUNT(*)
           FROM warehouse_stock_requests wsr
           JOIN warehouses w ON w.id = wsr.warehouse_id
           WHERE w.owner_id = $1 AND wsr.status = 'pending'
         )::int AS pending_receptions,
         (
           SELECT COUNT(*)
           FROM warehouse_stock_requests wsr
           JOIN warehouses w ON w.id = wsr.warehouse_id
           WHERE w.owner_id = $1 AND wsr.status = 'sent'
         )::int AS incoming_shipments,
         (
           SELECT COUNT(*)
           FROM deliveries d
           JOIN warehouses w ON w.id = d.warehouse_id
           WHERE w.owner_id = $1
             AND d.status IN ('pending', 'assigned', 'picked_up')
         )::int AS pending_deliveries`,
      [userId],
      { userId, role }
    );

    const row = result.rows[0];
    return {
      partner: {
        total_sales: row?.total_sales ?? 0,
        active_sales: row?.active_sales ?? 0,
        delivered_sales: row?.delivered_sales ?? 0,
        active_publications: row?.active_publications ?? 0,
        sold_out_publications: row?.sold_out_publications ?? 0,
        pending_tasks: row?.pending_tasks ?? 0,
      },
      warehouse: {
        owned: row?.owned ?? 0,
        pending_receptions: row?.pending_receptions ?? 0,
        incoming_shipments: row?.incoming_shipments ?? 0,
        pending_deliveries: row?.pending_deliveries ?? 0,
      },
    };
  }

  async getAdminSummary(
    userId: string,
    role: UserRole
  ): Promise<AdminHomeSummary> {
    const result = await query<Omit<AdminHomeSummary, "total">>(
      `SELECT
         (SELECT COUNT(*) FROM businesses WHERE status = 'pending' OR validated = false)::int AS businesses,
         (SELECT COUNT(*) FROM events WHERE status = 'pending')::int AS events,
         (SELECT COUNT(*) FROM warehouses WHERE status = 'pending' OR validated = false)::int AS warehouses,
         (SELECT COUNT(*) FROM business_claim_requests WHERE status = 'pending')::int AS claims`,
      [],
      { userId, role }
    );
    const row = result.rows[0];
    const summary = {
      businesses: row?.businesses ?? 0,
      events: row?.events ?? 0,
      warehouses: row?.warehouses ?? 0,
      claims: row?.claims ?? 0,
    };

    return {
      ...summary,
      total: Object.values(summary).reduce((sum, count) => sum + count, 0),
    };
  }
}

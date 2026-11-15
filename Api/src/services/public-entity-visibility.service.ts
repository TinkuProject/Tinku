import { MediaEntityType } from "../constants/enums.constants";
import { query } from "../config/database.config";

export class PublicEntityVisibilityService {
  static async filterVisibleIds(
    entityType: MediaEntityType,
    entityIds: Array<string | number>,
    viewerId?: string
  ): Promise<string[]> {
    const uniqueIds = [...new Set(entityIds.map(String))];
    if (uniqueIds.length === 0 || entityType === "payment") return [];

    const numericIds = uniqueIds.map(Number);
    let sql: string;
    let values: unknown[];

    switch (entityType) {
      case "user":
        sql = `SELECT id::text AS id FROM users
               WHERE id = ANY($1::uuid[]) AND status = 'active'`;
        values = [uniqueIds];
        break;
      case "business":
        sql = `SELECT id::text AS id FROM businesses
               WHERE id = ANY($1::bigint[])
                 AND status = 'active' AND validated = true`;
        values = [numericIds];
        break;
      case "event":
        sql = `SELECT id::text AS id FROM events
               WHERE id = ANY($1::bigint[]) AND status = 'active'`;
        values = [numericIds];
        break;
      case "product":
        sql = `SELECT p.id::text AS id
               FROM products p
               JOIN businesses b ON b.id = p.business_id
               WHERE p.id = ANY($1::bigint[])
                 AND p.status = 'active'
                 AND b.status = 'active' AND b.validated = true`;
        values = [numericIds];
        break;
      case "certification":
        sql = `SELECT c.id::text AS id
               FROM certifications c
               JOIN businesses b ON b.id = c.business_id
               WHERE c.id = ANY($1::bigint[])
                 AND c.status = 'active'
                 AND b.status = 'active' AND b.validated = true`;
        values = [numericIds];
        break;
      case "discount":
        sql = `SELECT d.id::text AS id
               FROM discounts d
               JOIN businesses b ON b.id = d.business_id
               WHERE d.id = ANY($1::bigint[])
                 AND (
                   b.owner_id = $2::uuid
                   OR (
                     d.status = 'active'
                     AND d.start_date <= CURRENT_TIMESTAMP
                     AND d.end_date >= CURRENT_TIMESTAMP
                     AND b.status = 'active' AND b.validated = true
                   )
                 )`;
        values = [numericIds, viewerId ?? null];
        break;
      case "warehouse":
        sql = `SELECT id::text AS id FROM warehouses
               WHERE id = ANY($1::bigint[])
                 AND status = 'active' AND validated = true`;
        values = [numericIds];
        break;
      case "product_publication":
        sql = `SELECT pp.id::text AS id
               FROM product_publications pp
               JOIN products p ON p.id = pp.product_id
               JOIN businesses b ON b.id = pp.business_id
               WHERE pp.id = ANY($1::bigint[])
                 AND pp.status = 'active' AND pp.published_stock > 0
                 AND p.status = 'active'
                 AND b.status = 'active' AND b.validated = true`;
        values = [numericIds];
        break;
      case "review":
        sql = `SELECT id::text AS id FROM reviews
               WHERE id = ANY($1::bigint[]) AND status = 'visible'`;
        values = [numericIds];
        break;
      case "tourist_place":
        sql = `SELECT id::text AS id FROM tourist_places
               WHERE id = ANY($1::bigint[]) AND status = 'active'`;
        values = [numericIds];
        break;
      case "category":
        sql = `SELECT id::text AS id FROM categories
               WHERE id = ANY($1::bigint[]) AND status = 'active'`;
        values = [numericIds];
        break;
      case "coin_package":
        sql = `SELECT id::text AS id FROM coin_packages
               WHERE id = ANY($1::bigint[]) AND status = 'active'`;
        values = [numericIds];
        break;
      case "subscription":
        sql = `SELECT id::text AS id FROM subscription_plans
               WHERE id = ANY($1::bigint[]) AND status = 'active'`;
        values = [numericIds];
        break;
      case "transport_line":
        sql = `SELECT id::text AS id FROM transport_lines
               WHERE id = ANY($1::bigint[]) AND status = 'active'`;
        values = [numericIds];
        break;
      case "charging_point":
        sql = `SELECT id::text AS id FROM charging_points
               WHERE id = ANY($1::bigint[]) AND status = 'active'`;
        values = [numericIds];
        break;
      default:
        return [];
    }

    if (entityType !== "user" && numericIds.some((id) => !Number.isInteger(id))) {
      return [];
    }

    const result = await query<{ id: string }>(sql, values);
    return result.rows.map((row) => String(row.id));
  }

  static async isVisible(
    entityType: MediaEntityType,
    entityId: string | number,
    viewerId?: string
  ): Promise<boolean> {
    const ids = await this.filterVisibleIds(entityType, [entityId], viewerId);
    return ids.includes(String(entityId));
  }
}

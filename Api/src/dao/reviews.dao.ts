import { DbClient } from "../types/db-client";
import { Review } from "../dto/review.dto";
import { query } from "../config/database.config";
import { ReviewCreateInput, ReviewStatusUpdateInput, ReviewUpdateInput,
} from "../validation/reviews.validation";
import { ReviewEntityType } from "../constants/enums.constants";

export type ReviewNotificationTarget = {
    owner_id: string | null;
    entity_name: string | null;
    entity_kind: string | null;
    entity_id: number;
    reviewer_user_id?: string | null;
};

export class ReviewsDAO {
    private table = "reviews";
    constructor(private db: DbClient) { }

    private mapToDomain(row: any): Review {
        if (!row) return row;

        return {
            ...row,
            created_at: new Date(row.created_at),
            updated_at: row.updated_at ? new Date(row.updated_at) : null,
            owner_reply_at: row.owner_reply_at
                ? new Date(row.owner_reply_at)
                : null,
        };
    }

    async create(
        userId: string,
        data: ReviewCreateInput
    ): Promise<Review> {
        const { data: result, error } = await this.db
            .from(this.table)
            .insert({
                ...data,
                user_id: userId,
                status: "visible",
            })
            .select()
            .single();

        if (error) throw error;
        return this.mapToDomain(result);
    }

    async getAll(): Promise<Review[]> {
        const { data, error } = await this.db
            .from(this.table)
            .select("*")
            .order("created_at", { ascending: false });

        if (error) throw error;
        return (data || []).map((r) => this.mapToDomain(r));
    }

    async getById(id: number): Promise<Review | null> {
        const { data, error } = await this.db
            .from(this.table)
            .select("*")
            .eq("id", id)
            .maybeSingle();

        if (error) throw error;
        return data ? this.mapToDomain(data) : null;
    }

    async getByEntity(
        entityType: ReviewEntityType,
        entityId: number
    ): Promise<Review[]> {
        const { data, error } = await this.db
            .from(this.table)
            .select("*")
            .eq("entity_type", entityType)
            .eq("entity_id", entityId)
            .eq("status", "visible")
            .order("created_at", { ascending: false });

        if (error) throw error;
        return (data || []).map((r) => this.mapToDomain(r));
    }

    async getByEntities(
    entityType: ReviewEntityType,
    entityIds: number[]
    ): Promise<Record<number, Review[]>> {
    const { data, error } = await this.db
        .from(this.table)
        .select("*")
        .eq("entity_type", entityType)
        .in("entity_id", entityIds)
        .eq("status", "visible")
        .order("created_at", { ascending: false });

    if (error) throw error;

    const result: Record<number, Review[]> = {};

    for (const row of data || []) {
        const mapped = this.mapToDomain(row);
        const key = mapped.entity_id;

        if (!result[key]) {
        result[key] = [];
        }

        result[key].push(mapped);
    }

    return result;
    }

    async getByUser(userId: string): Promise<Review[]> {
        const { data, error } = await this.db
            .from(this.table)
            .select("*")
            .eq("user_id", userId)
            .order("created_at", { ascending: false });

        if (error) throw error;
        return (data || []).map((r) => this.mapToDomain(r));
    }

    async getManagedByOwner(
        userId: string,
        role?: string
    ): Promise<Review[]> {
        const isAdmin = role === "admin" || role === "master";
        const result = await query(
            `WITH managed_entities AS (
                SELECT
                    'business'::text AS review_entity_type,
                    id AS entity_id,
                    name AS entity_name,
                    business_type::text AS entity_kind,
                    id AS entity_business_id
                FROM businesses
                WHERE ($2::boolean = true OR owner_id = $1)

                UNION ALL

                SELECT
                    'event'::text AS review_entity_type,
                    id AS entity_id,
                    name AS entity_name,
                    'event'::text AS entity_kind,
                    business_id AS entity_business_id
                FROM events
                WHERE ($2::boolean = true OR creator_id = $1)
            )
            SELECT
                r.*,
                me.entity_name,
                me.entity_kind,
                me.entity_business_id,
                u.username AS reviewer_username,
                u.first_name AS reviewer_first_name,
                u.last_name AS reviewer_last_name
            FROM reviews r
            JOIN managed_entities me
              ON me.review_entity_type = r.entity_type::text
             AND me.entity_id = r.entity_id
            LEFT JOIN users u ON u.id = r.user_id
            WHERE r.status = 'visible'
            ORDER BY r.created_at DESC`,
            [userId, isAdmin]
        );

        return result.rows.map((r) => this.mapToDomain(r));
    }

    async getOwnerIdForReview(id: number): Promise<string | null> {
        const result = await query(
            `SELECT
                CASE
                    WHEN r.entity_type = 'business' THEN b.owner_id
                    WHEN r.entity_type = 'event' THEN e.creator_id
                    ELSE NULL
                END AS owner_id
            FROM reviews r
            LEFT JOIN businesses b
              ON r.entity_type = 'business'
             AND b.id = r.entity_id
            LEFT JOIN events e
              ON r.entity_type = 'event'
             AND e.id = r.entity_id
            WHERE r.id = $1
            LIMIT 1`,
            [id]
        );

        return result.rows[0]?.owner_id ?? null;
    }

    async getNotificationTargetForEntity(
        entityType: ReviewEntityType,
        entityId: number
    ): Promise<ReviewNotificationTarget | null> {
        const result = await query(
            `SELECT *
             FROM (
                SELECT
                    b.owner_id,
                    b.name AS entity_name,
                    b.business_type::text AS entity_kind
                FROM businesses b
                WHERE $1 = 'business'
                  AND b.id = $2

                UNION ALL

                SELECT
                    e.creator_id AS owner_id,
                    e.name AS entity_name,
                    'event'::text AS entity_kind
                FROM events e
                WHERE $1 = 'event'
                  AND e.id = $2

                UNION ALL

                SELECT
                    COALESCE(p.owner_id, b.owner_id) AS owner_id,
                    p.name AS entity_name,
                    'product'::text AS entity_kind
                FROM products p
                LEFT JOIN businesses b ON b.id = p.business_id
                WHERE $1 = 'product'
                  AND p.id = $2

                UNION ALL

                SELECT
                    tp.created_by AS owner_id,
                    tp.name AS entity_name,
                    'tourist_place'::text AS entity_kind
                FROM tourist_places tp
                WHERE $1 = 'tourist_place'
                  AND tp.id = $2
             ) target
             LIMIT 1`,
            [entityType, entityId]
        );

        return result.rows[0] ?? null;
    }

    async getNotificationTargetForReview(
        id: number
    ): Promise<ReviewNotificationTarget | null> {
        const result = await query(
            `SELECT *
             FROM (
                SELECT
                    b.owner_id,
                    b.name AS entity_name,
                    b.business_type::text AS entity_kind,
                    r.entity_id,
                    r.user_id AS reviewer_user_id
                FROM reviews r
                JOIN businesses b
                  ON r.entity_type = 'business'
                 AND b.id = r.entity_id
                WHERE r.id = $1

                UNION ALL

                SELECT
                    e.creator_id AS owner_id,
                    e.name AS entity_name,
                    'event'::text AS entity_kind,
                    r.entity_id,
                    r.user_id AS reviewer_user_id
                FROM reviews r
                JOIN events e
                  ON r.entity_type = 'event'
                 AND e.id = r.entity_id
                WHERE r.id = $1

                UNION ALL

                SELECT
                    COALESCE(p.owner_id, b.owner_id) AS owner_id,
                    p.name AS entity_name,
                    'product'::text AS entity_kind,
                    r.entity_id,
                    r.user_id AS reviewer_user_id
                FROM reviews r
                JOIN products p
                  ON r.entity_type = 'product'
                 AND p.id = r.entity_id
                LEFT JOIN businesses b ON b.id = p.business_id
                WHERE r.id = $1

                UNION ALL

                SELECT
                    tp.created_by AS owner_id,
                    tp.name AS entity_name,
                    'tourist_place'::text AS entity_kind,
                    r.entity_id,
                    r.user_id AS reviewer_user_id
                FROM reviews r
                JOIN tourist_places tp
                  ON r.entity_type = 'tourist_place'
                 AND tp.id = r.entity_id
                WHERE r.id = $1
             ) target
             LIMIT 1`,
            [id]
        );

        return result.rows[0] ?? null;
    }

    async reply(
        id: number,
        userId: string,
        reply: string
    ): Promise<Review> {
        const result = await query(
            `UPDATE reviews
             SET owner_reply = $2,
                 owner_reply_user_id = $3,
                 owner_reply_at = CURRENT_TIMESTAMP,
                 updated_at = CURRENT_TIMESTAMP
             WHERE id = $1
             RETURNING *`,
            [id, reply, userId]
        );

        if (!result.rows[0]) {
            throw new Error("Review not found");
        }

        return this.mapToDomain(result.rows[0]);
    }

    async findExisting(
        userId: string,
        entityType: string,
        entityId: number
    ): Promise<Review | null> {
        const { data, error } = await this.db
            .from(this.table)
            .select("*")
            .eq("user_id", userId)
            .eq("entity_type", entityType)
            .eq("entity_id", entityId)
            .maybeSingle();

        if (error) throw error;
        return data ? this.mapToDomain(data) : null;
    }

    async hasConfirmedEventReservation(
        userId: string,
        eventId: number
    ): Promise<boolean> {
        const { data, error } = await this.db
            .from("reservations")
            .select("id")
            .eq("user_id", userId)
            .eq("event_id", eventId)
            .eq("status", "confirmed")
            .limit(1);

        if (error) throw error;
        return (data ?? []).length > 0;
    }

    async update(
        id: number,
        updates: ReviewUpdateInput
    ): Promise<Review> {
        const { data, error } = await this.db
            .from(this.table)
            .update({
                ...updates,
                updated_at: new Date().toISOString(),
            })
            .eq("id", id)
            .select()
            .single();

        if (error) throw error;
        return this.mapToDomain(data);
    }

    async updateStatus(
        id: number,
        updates: ReviewStatusUpdateInput
    ): Promise<Review> {
        const { data, error } = await this.db
            .from(this.table)
            .update({
                ...updates,
                updated_at: new Date().toISOString(),
            })
            .eq("id", id)
            .select()
            .single();

        if (error) throw error;
        return this.mapToDomain(data);
    }

    async softDelete(id: number): Promise<Review> {
        return this.updateStatus(id, {
            status: "hidden",
        });
    }
}

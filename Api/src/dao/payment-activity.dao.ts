import { query } from "../config/database.config";

export type PaymentActivityRawRow = {
  id: number;
  kind: "payment_request" | "financial_transaction";
  raw_type: string;
  status: string;
  amount: number;
  currency: string;
  created_at: string;
  updated_at: string | null;
  payment_id: number | null;
  target_id: number | null;
  target_label: string | null;
  comment: string | null;
  reviewed_by: string | null;
  reviewed_at: string | null;
  description: string | null;
  reference_id: number | null;
  purpose: string | null;
  total_count: number;
};

export class PaymentActivityDAO {
  async findMineActivityPage(
    userId: string,
    limit: number,
    offset: number
  ): Promise<{ rows: PaymentActivityRawRow[]; total: number }> {
    const result = await query<PaymentActivityRawRow>(
      `SELECT activity.*, COUNT(*) OVER()::int AS total_count
       FROM (
         SELECT
           pr.id,
           'payment_request'::text AS kind,
           pr.type::text AS raw_type,
           pr.status::text AS status,
           COALESCE(
             p.amount,
             CASE
               WHEN pr.type = 'coin_purchase' THEN cp.price
               WHEN pr.type = 'subscription' THEN sp.price
               ELSE 0
             END,
             0
           )::numeric AS amount,
           COALESCE(p.currency, 'BOB')::text AS currency,
           pr.created_at,
           pr.updated_at,
           pr.payment_id,
           pr.target_id,
           CASE
             WHEN pr.type = 'coin_purchase' THEN cp.name
             WHEN pr.type = 'subscription' THEN sp.name
             WHEN pr.type = 'marketplace_order' THEN '#' || pr.target_id::text
             ELSE NULL
           END AS target_label,
           pr.comment,
           pr.reviewed_by,
           pr.reviewed_at,
           NULL::text AS description,
           NULL::bigint AS reference_id,
           NULL::text AS purpose
         FROM payment_requests pr
         LEFT JOIN payments p ON p.id = pr.payment_id
         LEFT JOIN coin_packages cp
           ON pr.type = 'coin_purchase' AND cp.id = pr.target_id
         LEFT JOIN subscription_plans sp
           ON pr.type = 'subscription' AND sp.id = pr.target_id
         WHERE pr.user_id = $1

         UNION ALL

         SELECT
           ft.id,
           'financial_transaction'::text AS kind,
           ft.type::text AS raw_type,
           ft.status::text AS status,
           ft.amount,
           ft.currency,
           ft.created_at,
           ft.updated_at,
           ft.payment_id,
           NULL::bigint AS target_id,
           NULL::text AS target_label,
           NULL::text AS comment,
           NULL::uuid AS reviewed_by,
           NULL::timestamp AS reviewed_at,
           ft.description,
           ft.reference_id,
           ft.purpose
         FROM financial_transactions ft
         WHERE ft.user_id = $1
       ) activity
       ORDER BY activity.created_at DESC, activity.id DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    const rows = result.rows;
    if (rows.length > 0) {
      return { rows, total: Number(rows[0]!.total_count) };
    }

    const count = await query<{ total: number }>(
      `SELECT (
         (SELECT COUNT(*) FROM payment_requests WHERE user_id = $1) +
         (SELECT COUNT(*) FROM financial_transactions WHERE user_id = $1)
       )::int AS total`,
      [userId]
    );
    return { rows: [], total: Number(count.rows[0]?.total ?? 0) };
  }

}

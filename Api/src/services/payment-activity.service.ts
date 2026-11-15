import { PaymentType, TransactionType } from "../constants/enums.constants";
import { PaymentActivityDAO } from "../dao/payment-activity.dao";
import { PaymentActivityItem } from "../dto/payment-activity.dto";

type PaymentRequestStatus = "pending" | "approved" | "rejected";
type TransactionStatus =
  | "pending"
  | "approved"
  | "rejected"
  | "failed"
  | "cancelled"
  | "reversed";

export class PaymentActivityService {
  constructor(private readonly dao: PaymentActivityDAO) {}

  async getMine(
    userId: string,
    limit = 20,
    offset = 0
  ): Promise<PaymentActivityItem[]> {
    const safeLimit = Math.min(Math.max(limit, 1), 100);
    const safeOffset = Math.max(offset, 0);
    const page = await this.dao.findMineActivityPage(
      userId,
      safeLimit,
      safeOffset
    );
    return page.rows.map((row) => this.mapRawActivity(row));
  }

  private async getMineWithTotal(
    userId: string,
    limit: number,
    offset: number
  ) {
    const page = await this.dao.findMineActivityPage(userId, limit, offset);
    return {
      items: page.rows.map((row) => this.mapRawActivity(row)),
      total: page.total,
    };
  }

  private mapRawActivity(row: any): PaymentActivityItem {
    if (row.kind === "payment_request") {
      const amount = Number(row.amount ?? 0);
      const currency = row.currency || "BOB";
      const type = row.raw_type as PaymentType;
      return {
        id: Number(row.id),
        kind: "payment_request",
        flow: "expense",
        type,
        title: this.resolveTitle(type, row.target_label ?? null),
        status: row.status,
        statusLabel: this.statusLabel(row.status),
        amount,
        amountLabel: `-${amount.toFixed(2)} ${currency}`,
        currency,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        paymentId: row.payment_id,
        targetId: row.target_id,
        comment: row.comment,
        reviewedBy: row.reviewed_by,
        reviewedAt: row.reviewed_at,
        description: null,
        referenceId: null,
        purpose: null,
      };
    }

    const flow = this.resolveTransactionFlow(row.raw_type);
    const amount = Number(row.amount ?? 0);
    const currency = row.currency || "BOB";
    return {
      id: Number(row.id),
      kind: "financial_transaction",
      flow,
      type: this.normalizeTransactionType(row.raw_type),
      title: this.resolveTransactionTitle(row),
      status: row.status,
      statusLabel: this.statusLabel(row.status),
      amount,
      amountLabel: `${flow === "income" ? "+" : "-"}${amount.toFixed(2)} ${currency}`,
      currency,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      paymentId: row.payment_id,
      targetId: null,
      comment: null,
      reviewedBy: null,
      reviewedAt: null,
      description: row.description,
      referenceId: row.reference_id,
      purpose: row.purpose,
    };
  }

  async getMinePage(userId: string, limit = 20, offset = 0) {
    const safeLimit = Math.min(Math.max(limit, 1), 100);
    const safeOffset = Math.max(offset, 0);
    const { items, total } = await this.getMineWithTotal(
      userId,
      safeLimit,
      safeOffset
    );

    return {
      items,
      total,
      limit: safeLimit,
      offset: safeOffset,
      has_more: safeOffset + items.length < total,
    };
  }

  private resolveTitle(type: PaymentType, targetLabel: string | null): string {
    switch (type) {
      case "coin_purchase":
        return `Compra de ${targetLabel ?? "monedas"}`;
      case "subscription":
        return `Suscripción ${targetLabel ?? ""}`.trim();
      case "partner_upgrade":
        return "Cambio a rol socio";
      case "marketplace_order":
        return `Pedido marketplace ${targetLabel ?? ""}`.trim();
      default:
        return targetLabel ?? "Pago";
    }
  }

  private statusLabel(status: PaymentRequestStatus | TransactionStatus): string {
    switch (status) {
      case "pending":
        return "Pendiente de aprobación";
      case "approved":
        return "Aprobado";
      case "rejected":
        return "Rechazado";
      case "failed":
        return "Fallido";
      case "cancelled":
        return "Cancelado";
      case "reversed":
        return "Revertido";
      default:
        return "Pendiente de aprobación";
    }
  }

  private resolveTransactionFlow(type: string): "income" | "expense" {
    switch (type) {
      case "reward":
      case "credit":
      case "deposit":
        return "income";
      case "debit":
      case "withdraw":
      case "expense":
      default:
        return "expense";
    }
  }

  private resolveTransactionTitle(tx: {
    description?: string | null;
    purpose?: string | null;
  }): string {
    switch (tx.purpose) {
      case "product_publication":
        return "Publicación de producto";
      case "product_publication_update":
        return "Actualización de publicación";
      case "event_reservation":
        return "Reserva de evento";
      case "warehouse_delivery_reward":
        return "Recompensa por entrega";
      case "marketplace_order":
        return "Compra en marketplace";
      case "marketplace_sale":
        return "Venta en marketplace";
      default:
        return tx.description ?? tx.purpose ?? "Movimiento";
    }
  }

  private normalizeTransactionType(type: string): TransactionType {
    switch (type) {
      case "purchase":
      case "spend":
      case "reward":
      case "refund":
      case "cashout":
      case "admin_adjustment":
        return type;
      default:
        return "spend";
    }
  }
}

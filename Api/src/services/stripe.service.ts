import Stripe from "stripe";
import { PoolClient } from "pg";
import { dbPool, query } from "../config/database.config";
import { DbClient } from "../types/db-client";
import { PaymentsDAO } from "../dao/payments.dao";
import { Payment } from "../dto/payment.dto";
import { PaymentRequestDAO } from "../dao/payment-requests.dao";
import { CoinPackagesDAO } from "../dao/coin-packages.dao";
import { SubscriptionPlansDAO } from "../dao/subscription-plans.dao";
import { NotificationsDAO } from "../dao/notifications.dao";
import { NotificationsService } from "./notifications.service";
import { CreateStripePaymentIntentInput } from "../validation/stripe.validation";
import { PaymentType } from "../constants/enums.constants";
import {
  getStripeClient,
  stripeDefaultCurrency,
  stripeSystemReviewerId,
} from "../config/stripe.config";
import { assertDirectOwner } from "../helper/role.helper";
import { AppError } from "../utils/AppError";

type StripeTarget = {
  targetId?: number;
  amount: number;
  currency: "BOB";
  label: string;
};

const STALE_PAYMENT_INTENT_MINUTES = 30;

export class StripeService {
  private readonly stripe: Stripe;

  constructor(
    private readonly db: DbClient,
    private readonly paymentsDao: PaymentsDAO,
    private readonly paymentRequestsDao: PaymentRequestDAO,
    private readonly coinPackagesDao: CoinPackagesDAO,
    private readonly subscriptionPlansDao: SubscriptionPlansDAO,
    private readonly notificationsService: NotificationsService
  ) {
    this.stripe = getStripeClient();
  }

  async createPaymentIntent(
    userId: string,
    input: CreateStripePaymentIntentInput
  ) {
    const target = await this.resolveTarget(input);
    await this.cancelStalePendingGatewayPayments(userId, input.type);
    const existingPayment = input.clientRequestId
      ? await this.paymentsDao.findByStripeClientRequestId(
          userId,
          input.clientRequestId
        )
      : null;

    if (existingPayment && existingPayment.status !== "pending") {
      throw new Error("Payment already processed");
    }

    if (existingPayment && !existingPayment.external_reference) {
      throw new Error("Payment is still initializing");
    }

    if (existingPayment?.external_reference) {
      if (existingPayment.type !== input.type ||
          (existingPayment.gateway_target_id ?? null) !== (target.targetId ?? null)) {
        throw new AppError("Idempotency key reused with different data", 409);
      }
      const existingIntent = await this.stripe.paymentIntents.retrieve(
        existingPayment.external_reference
      );

      return this.paymentIntentResponse(
        existingPayment,
        existingIntent,
        target
      );
    }

    const payment = await this.paymentsDao.create({
      user_id: userId,
      method: "gateway",
      amount: target.amount,
      amount_minor: this.toStripeAmount(target.amount),
      currency_minor_unit: 2,
      currency: target.currency,
      type: input.type,
      external_reference: null,
      stripe_client_request_id: input.clientRequestId ?? null,
      gateway_target_id: target.targetId ?? null,
    });

    let intent: Stripe.PaymentIntent | null = null;

    try {
      intent = await this.stripe.paymentIntents.create(
        {
          amount: payment.amount_minor ?? this.toStripeAmount(target.amount),
          currency: target.currency.toLowerCase(),
          automatic_payment_methods: {
            enabled: true,
          },
          description: target.label,
          metadata: {
            payment_id: String(payment.id),
            user_id: userId,
            type: input.type,
            ...(target.targetId ? { target_id: String(target.targetId) } : {}),
            ...(input.clientRequestId
              ? { client_request_id: input.clientRequestId }
              : {}),
          },
        },
        { idempotencyKey: `tinku-payment-${payment.id}` }
      );

      const updatedPayment = await this.paymentsDao.update({
        id: payment.id,
        external_reference: intent.id,
      });

      if (input.type === "marketplace_order" && target.targetId) {
        await this.paymentRequestsDao.create(userId, {
          paymentId: updatedPayment.id,
          type: input.type,
          targetId: target.targetId,
        });
      }

      await this.notificationsService.createSafely({
        user_id: userId,
        title: "Pago iniciado",
        message: `Tu pago "${target.label}" fue creado con Stripe.`,
        read: false,
      });

      return this.paymentIntentResponse(updatedPayment, intent, target);
    } catch (err) {
      if (intent) {
        await this.stripe.paymentIntents.cancel(intent.id).catch(() => null);
      }

      await this.paymentsDao
        .update({
          id: payment.id,
          status: "cancelled",
          external_reference: intent?.id ?? null,
        })
        .catch(() => null);

      throw err;
    }
  }

  private paymentIntentResponse(
    payment: Payment,
    intent: Stripe.PaymentIntent,
    target: StripeTarget
  ) {
    return {
      payment,
      paymentRequest: null,
      paymentIntentId: intent.id,
      clientSecret: intent.client_secret,
      amount: target.amount,
      currency: target.currency,
    };
  }

  async handleWebhookEvent(event: Stripe.Event) {
    // A session lock is released by PostgreSQL if this worker crashes.
    const lock = await dbPool.connect();
    try {
      const acquired = await lock.query<{ acquired: boolean }>(
        "SELECT pg_try_advisory_lock(hashtext($1), hashtext($2)) AS acquired",
        ["stripe_webhook", event.id]
      );
      if (!acquired.rows[0]?.acquired) throw new AppError("Webhook is being processed", 409);
      const existing = await lock.query(
        "SELECT processed_at FROM stripe_webhook_events WHERE id = $1", [event.id]
      );
      if (existing.rows[0]?.processed_at) return { received: true, duplicate: true };
      await lock.query(
        "INSERT INTO stripe_webhook_events (id, type) VALUES ($1, $2) ON CONFLICT (id) DO NOTHING",
        [event.id, event.type]
      );
      switch (event.type) {
        case "payment_intent.succeeded":
          await this.approvePaymentIntent(
            event.data.object as Stripe.PaymentIntent
          );
          break;

        case "payment_intent.canceled":
          {
            const current = await this.stripe.paymentIntents.retrieve(event.data.object.id);
            if (current.status === "succeeded") await this.approvePaymentIntent(current);
            else if (current.status === "canceled") await this.failPaymentIntent(current, "cancelled");
          }
          break;
        case "payment_intent.payment_failed":
          // A failed card attempt does not close its reusable PaymentIntent.
          break;

        default:
          break;
      }

      await this.markWebhookEventProcessed(event.id);
      return { received: true };
    } finally {
      await lock.query("SELECT pg_advisory_unlock(hashtext($1), hashtext($2))", [
        "stripe_webhook", event.id,
      ]).catch(() => undefined);
      lock.release();
    }
  }

  async cancelPaymentIntent(userId: string, paymentIntentId: string) {
    const payment = await this.paymentsDao.findByExternalReference(
      paymentIntentId
    );

    if (!payment) throw new Error("Payment not found");
    assertDirectOwner(payment.user_id, userId, "Payment not found");
    if (payment.method !== "gateway") throw new Error("Invalid payment method");

    if (payment.status !== "pending") {
      return { payment, cancelled: false };
    }

    if (!await this.cancelStripePaymentIntent(paymentIntentId)) {
      await this.approvePaymentIntent(await this.stripe.paymentIntents.retrieve(paymentIntentId));
      return { payment: await this.paymentsDao.findById({ id: payment.id }), cancelled: false };
    }

    const updatedPayment = await this.paymentsDao.update({
      id: payment.id,
      status: "cancelled",
    });

    const request = await this.paymentRequestsDao.findByPaymentId(payment.id);
    if (payment.type === "marketplace_order") {
      await this.cancelMarketplacePaymentRequest(
        payment,
        request?.targetId ?? null,
        "Pago cancelado por el usuario"
      );
      return { payment: updatedPayment, cancelled: true };
    }

    if (request && request.status === "pending") {
      this.ensureSystemReviewer();
      await this.paymentRequestsDao.updateStatusManual(
        request.id,
        "rejected",
        stripeSystemReviewerId,
        "Pago cancelado por el usuario"
      );
    }

    return { payment: updatedPayment, cancelled: true };
  }

  private async approvePaymentIntent(intent: Stripe.PaymentIntent) {
    const payment = await this.paymentsDao.findByExternalReference(intent.id);
    if (!payment) throw new Error("Payment not found");
    this.assertIntentBinding(payment, intent);

    if (payment.type === "marketplace_order") {
      await this.approveMarketplaceOrderPayment(payment, intent);
      return;
    }

    let request = await this.paymentRequestsDao.findByPaymentId(payment.id);
    if (request && (request.userId !== payment.user_id || request.type !== payment.type ||
        (request.targetId ?? null) !== (this.targetIdFromIntent(intent) ?? null))) {
      throw new Error("Stripe payment target mismatch");
    }
    if (!request) {
      const targetId = this.targetIdFromIntent(intent);
      request = await this.paymentRequestsDao.create(payment.user_id, {
        paymentId: payment.id,
        type: payment.type,
        ...(targetId ? { targetId } : {}),
      });
    }

    this.ensureSystemReviewer();

    const { error } = await this.db.rpc("approve_stripe_payment_request", {
      p_request_id: request.id,
      p_payment_intent_id: intent.id,
      p_system_user_id: stripeSystemReviewerId,
      p_comment: "Pago aprobado automáticamente por Stripe",
    });

    if (error) throw error;

    await this.notificationsService.createSafely({
      user_id: request.userId,
      sender_id: stripeSystemReviewerId,
      title: "Pago aprobado",
      message: `Tu pago #${payment.id} fue confirmado por Stripe.`,
      read: false,
    });
  }

  private async failPaymentIntent(
    intent: Stripe.PaymentIntent,
    status: "failed" | "cancelled"
  ) {
    const payment = await this.paymentsDao.findByExternalReference(intent.id);
    if (!payment) return;
    if (payment.status === "approved") return;

    if (payment.type === "marketplace_order") {
      await this.failMarketplaceOrderPayment(payment, intent, status);
      return;
    }

    const request = await this.paymentRequestsDao.findByPaymentId(payment.id);

    this.ensureSystemReviewer();

    await this.paymentsDao.update({
      id: payment.id,
      status,
    });

    if (request && request.status === "pending") {
      await this.paymentRequestsDao.updateStatusManual(
        request.id,
        "rejected",
        stripeSystemReviewerId,
        status === "cancelled"
          ? "Pago cancelado en Stripe"
          : "Pago fallido en Stripe"
      );

      await this.notificationsService.createSafely({
        user_id: request.userId,
        sender_id: stripeSystemReviewerId,
        title: "Pago no completado",
        message:
          status === "cancelled"
            ? `Tu pago #${payment.id} fue cancelado.`
            : `Tu pago #${payment.id} no pudo completarse.`,
        read: false,
      });
    }
  }

  private async resolveTarget(input: CreateStripePaymentIntentInput): Promise<StripeTarget> {
    switch (input.type) {
      case "coin_purchase":
        return this.resolveCoinPackage(input.targetId);
      case "partner_upgrade":
        return this.resolvePartnerUpgrade();
      case "subscription":
        return this.resolveSubscription(input.targetId);
      case "marketplace_order":
        throw new Error("Marketplace orders can only be paid with Tinkus");
      default:
        throw new Error("Unsupported payment type");
    }
  }

  private async resolveCoinPackage(targetId?: number): Promise<StripeTarget> {
    if (!targetId) throw new Error("targetId is required");

    const coinPackage = await this.coinPackagesDao.findActiveById(targetId);
    if (!coinPackage) throw new Error("Coin package not found");

    return {
      targetId: coinPackage.id,
      amount: Number(coinPackage.cash_amount),
      currency: this.resolveCurrency(stripeDefaultCurrency),
      label: `Compra de ${coinPackage.tinkus_amount} Tinkus`,
    };
  }

  private async resolvePartnerUpgrade(): Promise<StripeTarget> {
    const coinPackage = await this.coinPackagesDao.findPartnerUpgradePackage();
    if (!coinPackage) throw new Error("Partner upgrade package not found");

    return {
      amount: Number(coinPackage.cash_amount),
      currency: this.resolveCurrency(stripeDefaultCurrency),
      label: "Upgrade a socio",
    };
  }

  private async resolveSubscription(targetId?: number): Promise<StripeTarget> {
    if (!targetId) throw new Error("targetId is required");

    const plan = await this.subscriptionPlansDao.findById({ id: targetId });
    if (!plan || plan.status !== "active") {
      throw new Error("Subscription plan not found");
    }

    return {
      targetId: plan.id,
      amount: Number(plan.price),
      currency: this.resolveCurrency(plan.currency || stripeDefaultCurrency),
      label: `Suscripción ${plan.name}`,
    };
  }

  private async resolveMarketplaceOrder(
    targetId: number | undefined,
    userId: string
  ): Promise<StripeTarget> {
    if (!targetId) throw new Error("targetId is required");

    const result = await query(
      `SELECT id, buyer_id, status, payment_method, total_amount
       FROM marketplace_orders
       WHERE id = $1
       LIMIT 1`,
      [targetId]
    );
    const order = result.rows[0];

    if (!order) throw new Error("Marketplace order not found");
    assertDirectOwner(order.buyer_id, userId, "Marketplace order not found");
    if (order.payment_method !== "stripe") {
      throw new Error("This order is not configured for card payment");
    }
    if (order.status !== "pending") {
      throw new Error("Marketplace order already processed");
    }

    return {
      targetId: order.id,
      amount: Number(order.total_amount),
      currency: this.resolveCurrency(stripeDefaultCurrency),
      label: `Pedido marketplace #${order.id}`,
    };
  }

  private async approveMarketplaceOrderPayment(
    payment: Payment,
    intent: Stripe.PaymentIntent
  ) {
    const targetId = this.targetIdFromIntent(intent);
    if (!targetId) throw new Error("Marketplace order target is required");

    this.ensureSystemReviewer();

    let request = await this.paymentRequestsDao.findByPaymentId(payment.id);
    if (!request) {
      request = await this.paymentRequestsDao.create(payment.user_id, {
        paymentId: payment.id,
        type: "marketplace_order",
        targetId,
      });
    }

    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");

      await client.query(
        `UPDATE payments
         SET status = 'approved',
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [payment.id]
      );

      await client.query(
        `UPDATE payment_requests
         SET status = 'approved',
             reviewed_by = $2,
             reviewed_at = CURRENT_TIMESTAMP,
             comment = 'Pago aprobado automáticamente por Stripe',
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [request.id, stripeSystemReviewerId]
      );

      const orderUpdate = await client.query(
        `UPDATE marketplace_orders
         SET status = 'paid',
             payment_id = $2,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1
           AND buyer_id = $3
           AND payment_method = 'stripe'
           AND status = 'pending'`,
        [targetId, payment.id, payment.user_id]
      );

      if (orderUpdate.rowCount !== 1) {
        throw new Error("Marketplace order could not be approved");
      }

      await client.query("COMMIT");
    } catch (err) {
      await client.query("ROLLBACK").catch(() => null);
      throw err;
    } finally {
      client.release();
    }

    await this.notificationsService.createSafely({
      user_id: payment.user_id,
      sender_id: stripeSystemReviewerId,
      title: "Pedido pagado",
      message: `Tu pedido marketplace #${targetId} fue confirmado por Stripe.`,
      read: false,
    });
  }

  private async failMarketplaceOrderPayment(
    payment: Payment,
    intent: Stripe.PaymentIntent,
    status: "failed" | "cancelled"
  ) {
    const targetId = this.targetIdFromIntent(intent);
    if (!targetId) return;

    this.ensureSystemReviewer();

    const request = await this.paymentRequestsDao.findByPaymentId(payment.id);

    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");

      await client.query(
        `UPDATE payments
         SET status = $2,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [payment.id, status]
      );

      if (request && request.status === "pending") {
        await client.query(
          `UPDATE payment_requests
           SET status = 'rejected',
               reviewed_by = $2,
               reviewed_at = CURRENT_TIMESTAMP,
               comment = $3,
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $1`,
          [
            request.id,
            stripeSystemReviewerId,
            status === "cancelled"
              ? "Pago cancelado en Stripe"
              : "Pago fallido en Stripe",
          ]
        );
      }

      await this.cancelMarketplaceOrderAndRestoreStock(
        client,
        targetId,
        payment.user_id
      );

      await client.query("COMMIT");
    } catch (err) {
      await client.query("ROLLBACK").catch(() => null);
      throw err;
    } finally {
      client.release();
    }

    await this.notificationsService.createSafely({
      user_id: payment.user_id,
      sender_id: stripeSystemReviewerId,
      title: "Pedido no completado",
      message:
        status === "cancelled"
          ? `Tu pedido marketplace #${targetId} fue cancelado.`
          : `Tu pedido marketplace #${targetId} no pudo completarse.`,
      read: false,
    });
  }

  private async cancelMarketplacePaymentRequest(
    payment: Payment,
    orderId: number | null,
    comment: string
  ) {
    if (!orderId) return;

    this.ensureSystemReviewer();
    const request = await this.paymentRequestsDao.findByPaymentId(payment.id);
    const client = await dbPool.connect();

    try {
      await client.query("BEGIN");

      if (request && request.status === "pending") {
        await client.query(
          `UPDATE payment_requests
           SET status = 'rejected',
               reviewed_by = $2,
               reviewed_at = CURRENT_TIMESTAMP,
               comment = $3,
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $1`,
          [request.id, stripeSystemReviewerId, comment]
        );
      }

      await this.cancelMarketplaceOrderAndRestoreStock(
        client,
        orderId,
        payment.user_id
      );

      await client.query("COMMIT");
    } catch (err) {
      await client.query("ROLLBACK").catch(() => null);
      throw err;
    } finally {
      client.release();
    }
  }

  private async cancelMarketplaceOrderAndRestoreStock(
    client: PoolClient,
    orderId: number,
    buyerId: string
  ) {
    const order = await client.query(
      `UPDATE marketplace_orders
       SET status = 'cancelled',
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
         AND buyer_id = $2
         AND status = 'pending'
         AND payment_method = 'stripe'
       RETURNING id`,
      [orderId, buyerId]
    );

    if (!order.rows[0]) return;

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
      [orderId]
    );
  }

  private toStripeAmount(amount: number): number {
    return Math.round(amount * 100);
  }

  private targetIdFromIntent(intent: Stripe.PaymentIntent): number | undefined {
    const rawTargetId = intent.metadata?.target_id;
    if (!rawTargetId) return undefined;

    const targetId = Number(rawTargetId);
    return Number.isInteger(targetId) && targetId > 0 ? targetId : undefined;
  }

  private ensureSystemReviewer() {
    if (!stripeSystemReviewerId) {
      throw new Error("Missing STRIPE_SYSTEM_REVIEWER_ID in .env");
    }
  }

  private resolveCurrency(currency: string): "BOB" {
    if (currency.toUpperCase() !== "BOB") {
      throw new Error("Only BOB currency is currently supported");
    }

    return "BOB";
  }

  private async cancelStalePendingGatewayPayments(
    userId: string,
    type: CreateStripePaymentIntentInput["type"]
  ) {
    const before = new Date(
      Date.now() - STALE_PAYMENT_INTENT_MINUTES * 60 * 1000
    );
    const stalePayments =
      await this.paymentsDao.findStalePendingGatewayByUser(userId, type, before);

    await Promise.all(
      stalePayments.map(async (payment) => {
        if (payment.external_reference) {
          if (!await this.cancelStripePaymentIntent(payment.external_reference)) {
            await this.approvePaymentIntent(await this.stripe.paymentIntents.retrieve(payment.external_reference));
            return;
          }
        }

        await this.paymentsDao.update({
          id: payment.id,
          status: "expired",
        });

        if (payment.type === "marketplace_order") {
          const request = await this.paymentRequestsDao.findByPaymentId(payment.id);
          await this.cancelMarketplacePaymentRequest(
            payment,
            request?.targetId ?? null,
            "Pago expirado"
          );
        }
      })
    );
  }

  private async cancelStripePaymentIntent(paymentIntentId: string) {
    try {
      const cancelled = await this.stripe.paymentIntents.cancel(paymentIntentId);
      return cancelled.status === "canceled";
    } catch (err) {
      const stripeError = err as Stripe.StripeRawError;
      if (stripeError.code !== "payment_intent_unexpected_state") throw err;
      const current = await this.stripe.paymentIntents.retrieve(paymentIntentId);
      if (current.status === "succeeded") return false;
      if (current.status === "canceled") return true;
      throw err;
    }
  }

  private assertIntentBinding(payment: Payment, intent: Stripe.PaymentIntent): void {
    const expected = payment.amount_minor ?? this.toStripeAmount(payment.amount);
    if (payment.method !== "gateway" || intent.status !== "succeeded" ||
        intent.amount !== expected || intent.amount_received !== expected ||
        intent.currency.toUpperCase() !== payment.currency.toUpperCase() ||
        intent.metadata.payment_id !== String(payment.id) ||
        intent.metadata.user_id !== payment.user_id || intent.metadata.type !== payment.type ||
        (payment.gateway_target_id != null && payment.gateway_target_id !== this.targetIdFromIntent(intent))) {
      throw new Error("Stripe payment target mismatch");
    }
  }

  private async markWebhookEventProcessed(eventId: string) {
    const { error } = await this.db
      .from("stripe_webhook_events")
      .update({
        processed_at: new Date().toISOString(),
      })
      .eq("id", eventId);

    if (error) throw error;
  }

}

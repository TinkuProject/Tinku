import { Request, Response } from "express";
import Stripe from "stripe";
import { PaymentsDAO } from "../dao/payments.dao";
import { PaymentRequestDAO } from "../dao/payment-requests.dao";
import { CoinPackagesDAO } from "../dao/coin-packages.dao";
import { SubscriptionPlansDAO } from "../dao/subscription-plans.dao";
import { NotificationsDAO } from "../dao/notifications.dao";
import { NotificationsService } from "../services/notifications.service";
import { StripeService } from "../services/stripe.service";
import {
  createStripePaymentIntentSchema,
  stripePaymentIntentIdSchema,
} from "../validation/stripe.validation";
import { handleError } from "../utils/handleError";
import { assertUser } from "../helper/role.helper";
import { supabaseAdmin } from "../config/supabase-client.config";
import {
  getStripeClient,
  stripeWebhookSecret,
} from "../config/stripe.config";

export class StripeController {
  private getService(): StripeService {
    const paymentsDao = new PaymentsDAO(supabaseAdmin);
    const paymentRequestsDao = new PaymentRequestDAO(supabaseAdmin);
    const coinPackagesDao = new CoinPackagesDAO(supabaseAdmin);
    const subscriptionPlansDao = new SubscriptionPlansDAO(supabaseAdmin);
    const notificationsDao = new NotificationsDAO(supabaseAdmin);
    const notificationsService = new NotificationsService(notificationsDao);

    return new StripeService(
      supabaseAdmin,
      paymentsDao,
      paymentRequestsDao,
      coinPackagesDao,
      subscriptionPlansDao,
      notificationsService
    );
  }

  createPaymentIntent = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = createStripePaymentIntentSchema.parse(req.body);
      const service = this.getService();
      const result = await service.createPaymentIntent(user.id, input);

      res.status(201).json(result);
    } catch (err) {
      if (this.handleStripeApiError(err, res)) return;
      return handleError(res, err);
    }
  };

  cancelPaymentIntent = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const { paymentIntentId } = stripePaymentIntentIdSchema.parse(req.params);
      const service = this.getService();
      const result = await service.cancelPaymentIntent(
        user.id,
        paymentIntentId
      );

      res.json(result);
    } catch (err) {
      if (this.handleStripeApiError(err, res)) return;
      return handleError(res, err);
    }
  };

  webhook = async (req: Request, res: Response): Promise<void> => {
    try {
      if (!stripeWebhookSecret) {
        throw new Error("Missing STRIPE_WEBHOOK_SECRET in .env");
      }

      const signature = req.headers["stripe-signature"];
      if (!signature || Array.isArray(signature)) {
        res.status(400).json({ error: "Missing Stripe signature" });
        return;
      }

      const stripe = getStripeClient();
      const event = stripe.webhooks.constructEvent(
        req.body,
        signature,
        stripeWebhookSecret
      ) as Stripe.Event;

      const service = this.getService();
      const result = await service.handleWebhookEvent(event);

      res.json(result);
    } catch (err) {
      res.status(400).json({
        error: err instanceof Error ? err.message : "Invalid Stripe webhook",
      });
    }
  };

  private handleStripeApiError(err: unknown, res: Response): boolean {
    const stripeError = err as Stripe.StripeRawError;

    if (!stripeError?.type && !stripeError?.code) return false;

    const code = stripeError.code ?? stripeError.type ?? "stripe_error";
    const statusCode = stripeError.statusCode ?? 400;

    const messages: Record<string, string> = {
      card_declined:
        "La tarjeta fue rechazada. Verifica los datos o intenta con otra tarjeta.",
      insufficient_funds: "La tarjeta no tiene fondos suficientes.",
      expired_card: "La tarjeta está vencida.",
      incorrect_cvc: "El código de seguridad de la tarjeta no es válido.",
      invalid_cvc: "El código de seguridad de la tarjeta no es válido.",
      authentication_required:
        "El banco necesita autenticar el pago. Intenta nuevamente.",
      payment_intent_unexpected_state:
        "Este pago ya no puede completarse. Inicia uno nuevo.",
    };

    res.status(statusCode).json({
      error: messages[code] ?? "No se pudo completar el pago con tarjeta.",
      code,
    });

    return true;
  }
}

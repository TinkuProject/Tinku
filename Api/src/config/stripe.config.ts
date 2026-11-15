import dotenv from "dotenv";
import Stripe from "stripe";

dotenv.config();

export const stripeWebhookSecret =
  process.env.STRIPE_WEBHOOK_SECRET ?? "";

export const stripeSystemReviewerId =
  process.env.STRIPE_SYSTEM_REVIEWER_ID ?? "";

export const stripeDefaultCurrency =
  process.env.STRIPE_DEFAULT_CURRENCY ?? "BOB";

export function getStripeClient(): Stripe {
  const secretKey = process.env.STRIPE_SECRET_KEY;

  if (!secretKey) {
    throw new Error("Missing STRIPE_SECRET_KEY in .env");
  }

  return new Stripe(secretKey);
}

import { Router } from "express";
import { StripeController } from "../controllers/stripe.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new StripeController();

router.post(
  "/payment-intents",
  authMiddleware,
  roleMiddleware(["user", "partner", "admin", "master"]),
  controller.createPaymentIntent
);

router.post(
  "/payment-intents/:paymentIntentId/cancel",
  authMiddleware,
  roleMiddleware(["user", "partner", "admin", "master"]),
  controller.cancelPaymentIntent
);

export default router;

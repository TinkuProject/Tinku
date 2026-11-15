import { Router } from "express";
import { StripeController } from "../controllers/stripe.controller";

const router = Router();
const controller = new StripeController();

router.post("/", controller.webhook);

export default router;

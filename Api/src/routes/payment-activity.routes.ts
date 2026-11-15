import { Router } from "express";
import { PaymentActivityController } from "../controllers/payment-activity.controller";
import { authMiddleware } from "../middlewares/auth.middleware";

const router = Router();
const controller = new PaymentActivityController();

router.use(authMiddleware);

router.get("/me/activity/paginated", controller.getMinePage);
router.get("/me/activity", controller.getMine);

export default router;

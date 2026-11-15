import { Router } from "express";
import { SubscriptionPlansController } from "../controllers/subscription-plans.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";
import { publicCache } from "../middlewares/cache-control.middleware";

const router = Router();
const controller = new SubscriptionPlansController();

router.get("/", publicCache(300), controller.getAll);
router.get("/:id", publicCache(300), controller.getById);

router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

router.post("/", controller.create);
router.patch("/:id", controller.update);
router.patch("/:id/archive", controller.softDelete);

export default router;

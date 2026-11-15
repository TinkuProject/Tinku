import { Router } from "express";
import { UserSubscriptionsController } from "../controllers/user-subscriptions.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new UserSubscriptionsController();

// todo requiere autenticación
router.use(authMiddleware);

router.get("/me/current", controller.getCurrent);

// administración
router.use(roleMiddleware(["admin", "master"]));

router.get("/user/:userId", controller.getByUser);
router.get("/", controller.getAll);
router.get("/:id", controller.getById);
router.post("/", controller.create);
router.patch("/:id", controller.update);
router.patch("/:id/cancel", controller.cancel);
router.delete("/:id", controller.delete);

export default router;

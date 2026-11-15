import { Router } from "express";
import { ChargingPointsController } from "../controllers/charging-points.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new ChargingPointsController();

// PUBLIC
router.get("/", controller.getAll);
router.get("/active", controller.getActive);
router.get("/:id", controller.getById);

// AUTH REQUIRED
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

// ADMIN ONLY
router.post("/", controller.create);
router.patch("/:id", controller.update);
router.patch("/:id/softDelete", controller.softDelete);

export default router;
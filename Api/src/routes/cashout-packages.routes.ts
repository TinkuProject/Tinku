import { Router } from "express";
import { CashoutPackagesController } from "../controllers/cashout-packages.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new CashoutPackagesController();

// PUBLIC
router.get("/", controller.getAll);
router.get("/:id/active", controller.getActiveById);
router.get("/admin", authMiddleware, roleMiddleware(["admin", "master"]), controller.getAllAdmin);
router.get("/:id", controller.getById);

// AUTH REQUIRED
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

router.post("/", controller.create);
router.patch("/:id", controller.update);
router.patch("/:id/softDelete", controller.softDelete);
router.patch("/:id/deactivate", controller.deactivate);
router.patch("/:id/activate", controller.activate);

export default router;
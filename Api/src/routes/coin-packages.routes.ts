import { Router } from "express";
import { CoinPackagesController } from "../controllers/coin-packages.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";
import { publicCache } from "../middlewares/cache-control.middleware";

const router = Router();
const controller = new CoinPackagesController();

router.get("/", publicCache(300), controller.getAll);
router.get("/basic", publicCache(300), controller.getPartnerUpgradePackage); //Esta ruta toma el valor del pago inicial por solicitud de payment_request
router.get("/:id/active", publicCache(300), controller.getActiveById);
router.get("/admin", authMiddleware, roleMiddleware(["admin", "master"]), controller.getAllAdmin);
router.get("/filters", authMiddleware, roleMiddleware(["admin", "master"]), controller.getByFilters);
router.get("/:id", publicCache(300), controller.getById);

router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

// ADMIN ONLY

router.post("/", controller.create);
router.patch("/:id", controller.update);
router.patch("/:id/softDelete", controller.softDelete);
router.patch("/:id/activate", controller.activate);
router.patch("/:id/deactivate", controller.deactivate);

export default router;

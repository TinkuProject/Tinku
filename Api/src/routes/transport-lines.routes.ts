import { Router } from "express";
import { TransportLinesController } from "../controllers/transport-lines.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";
import { publicCache } from "../middlewares/cache-control.middleware";

const router = Router();
const controller = new TransportLinesController();

// público
router.get("/", controller.getAll);
router.get("/public/active-with-routes", publicCache(300), controller.getActiveWithRoutes);
router.get("/batch", controller.getByIds);
router.get("/vehicle/:vehicleTypeId", controller.getByVehicleType);
router.get("/:id", controller.getById);

// protegido
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

router.post("/", controller.create);
router.put("/:id", controller.update);
router.patch("/:id/archive", controller.softDelete);

export default router;

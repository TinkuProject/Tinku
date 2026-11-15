import { Router } from "express";
import { VehicleTypesController } from "../controllers/vehicle-types.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";
import { publicCache } from "../middlewares/cache-control.middleware";

const router = Router();
const controller = new VehicleTypesController();

// lectura pública
router.get("/", publicCache(600), controller.getAll);
router.get("/:id", publicCache(600), controller.getById);

// escritura protegida
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

router.post("/", controller.create);
router.put("/:id", controller.update);
router.delete("/:id", controller.delete);

export default router;

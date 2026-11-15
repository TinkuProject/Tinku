import { Router } from "express";
import { SystemConfigController } from "../controllers/system-config.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";
import { publicCache } from "../middlewares/cache-control.middleware";

const router = Router();
const controller = new SystemConfigController();

router.get("/public/:key", publicCache(300), controller.getNumberByKey);

router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

router.get("/:key", controller.get);
router.get("/", controller.getAll);
// actualizar / crear config
router.put("/:key", controller.update);

export default router;

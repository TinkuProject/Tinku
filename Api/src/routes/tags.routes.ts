import { Router } from "express";
import { TagsController } from "../controllers/tags.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";
import { publicCache } from "../middlewares/cache-control.middleware";

const router = Router();
const controller = new TagsController();

// lectura pública
router.get("/", publicCache(600), controller.getAll);
router.get("/:id", publicCache(600), controller.getById);

// modificaciones protegidas
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

router.post("/", controller.create);
router.put("/:id", controller.update);
router.put("/:id/soft-delete", controller.softDelete);

export default router;

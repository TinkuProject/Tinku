import { Router } from "express";
import { MediaController } from "../controllers/media.controller";
import { authMiddleware, optionalAuthMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const controller = new MediaController();
const router = Router();

// PUBLIC

// Listado completo exclusivo para administración.
router.get("/", authMiddleware, roleMiddleware(["admin", "master"]), controller.getAll);
router.get("/entity", optionalAuthMiddleware, controller.getByEntity);
router.get("/entity/primary", optionalAuthMiddleware, controller.getPrimaryByEntity);
router.get("/entities", optionalAuthMiddleware, controller.getByEntities);
router.get("/:id", optionalAuthMiddleware, controller.getById);

// =========================
// PROTECTED
router.use(authMiddleware);

router.post("/", controller.create);
router.put("/:id", controller.update);
router.delete("/entity", controller.deleteAllByEntity);
router.delete("/url", controller.deleteByUrl);
router.delete("/:id", controller.delete);

export default router;

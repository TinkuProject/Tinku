import { Router } from "express";
import { EntityUpdatesController } from "../controllers/entity-updates.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new EntityUpdatesController();

// =========================
// AUTH REQUIRED
// =========================
router.use(authMiddleware);

// =========================
// USER
// =========================
router.post("/", roleMiddleware(["partner"]), controller.create);

router.get("/me", roleMiddleware(["partner"]), controller.getMine);

// 🔥 reemplaza business/:id y event/:id
router.get("/entity", roleMiddleware(["partner", "admin", "master"]), controller.getByEntity);

// =========================
// ADMIN / MASTER
// =========================
router.get("/", roleMiddleware(["admin", "master"]), controller.getAll);

router.get("/:id", roleMiddleware(["admin", "master"]), controller.getById);
router.patch("/:id/approve", roleMiddleware(["admin", "master"]), controller.approve);
router.patch("/:id/reject", roleMiddleware(["admin", "master"]), controller.reject);

export default router;
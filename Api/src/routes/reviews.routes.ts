import { Router } from "express";
import { ReviewsController } from "../controllers/reviews.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new ReviewsController();

// PUBLIC
router.get("/entity/:entityType/:entityId", controller.getByEntity);
router.get("/entities", controller.getByEntities);

// PROTECTED
router.use(authMiddleware);

router.get("/my", controller.getByUser);
router.get("/managed", roleMiddleware(["partner", "admin", "master"]), controller.getManaged);
router.post("/", controller.create);
router.patch("/:id/reply", roleMiddleware(["partner", "admin", "master"]), controller.reply);
router.put("/:id", controller.update);
router.delete("/:id", controller.softDelete);

// =========================
// ADMIN
// =========================
router.get("/", roleMiddleware(["admin", "master"]), controller.getAll);
router.get("/:id", roleMiddleware(["admin", "master"]), controller.getById);

export default router;

import { Router } from "express";
import { EventsController } from "../controllers/events.controller";
import { authMiddleware, optionalAuthMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new EventsController();

// PUBLIC
router.get("/", optionalAuthMiddleware, controller.getAll);
router.get("/paginated", optionalAuthMiddleware, controller.getPage);
router.get("/category/:categoryId", optionalAuthMiddleware, controller.getByCategory);
router.get("/business/:businessId", optionalAuthMiddleware, controller.getByBusiness);
router.get("/:id/availability", optionalAuthMiddleware, controller.getAvailability);
router.get("/batch", optionalAuthMiddleware, controller.getByIds);
router.get("/me", authMiddleware, roleMiddleware(["user", "partner", "admin", "master"]), controller.getMine);
router.get("/admin", authMiddleware, roleMiddleware(["admin", "master"]), controller.getByStatus);
router.get("/:id/detail", optionalAuthMiddleware, controller.getDetail);
router.get("/:id", optionalAuthMiddleware, controller.getById);

// AUTH REQUIRED
router.use(authMiddleware);

router.post("/", roleMiddleware(["partner", "admin", "master"]), controller.create);
//router.delete("/:id", roleMiddleware(["partner", "admin", "master"]), controller.delete);
router.delete("/:id", roleMiddleware(["partner", "admin", "master"]), controller.softDelete);

// ADMIN / MASTER
router.patch("/:id/approve", roleMiddleware(["admin", "master"]), controller.approve);
router.patch("/:id/reject", roleMiddleware(["admin", "master"]), controller.reject);

export default router;

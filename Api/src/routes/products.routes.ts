import { Router } from "express";
import { ProductsController } from "../controllers/products.controller";
import { authMiddleware, optionalAuthMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new ProductsController();

// PUBLIC
router.get("/", optionalAuthMiddleware, controller.getAll);
router.get("/business/:businessId", optionalAuthMiddleware, controller.getByBusiness);
router.get("/businesses", optionalAuthMiddleware, controller.getByBusinesses);
router.get("/my", authMiddleware, roleMiddleware(["admin", "master", "partner"]), controller.getMine);

// =========================
// ADMIN
// =========================
router.get("/admin/all", authMiddleware, roleMiddleware(["admin", "master"]), controller.getAllAdmin);
router.get("/admin/business/:businessId", authMiddleware, roleMiddleware(["admin", "master"]), controller.getByBusinessAdmin);

router.get("/:id", optionalAuthMiddleware, controller.getById);

// PROTECTED
router.use(authMiddleware);
router.post("/", roleMiddleware(["admin", "master", "partner"]), controller.create);
router.put("/:id", roleMiddleware(["admin", "master", "partner"]), controller.update);
router.delete("/:id", roleMiddleware(["admin", "master", "partner"]), controller.softDelete);

export default router;

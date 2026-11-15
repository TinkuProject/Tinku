import { Router } from "express";
import { CategoriesController } from "../controllers/categories.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";
import { publicCache } from "../middlewares/cache-control.middleware";

const router = Router();
const controller = new CategoriesController();

// PUBLIC
router.get("/", publicCache(300), controller.getAll);
router.get("/active/:id", publicCache(300), controller.getActiveById);
// {{base_url}}/categories/active?entity_type=event
// {{base_url}}/categories/active?entity_type=business&business_type=service
router.get("/active", publicCache(300), controller.getActiveByType);
// {{base_url}}/categories/filters?entity_type=business&business_type=service&status=active
// como el anterior pero con más filtros (status, etc)
router.get("/filters", authMiddleware, roleMiddleware(["admin", "master"]), controller.getByFilters);
router.get("/admin", authMiddleware, roleMiddleware(["admin", "master"]), controller.getAllAdmin);
router.get("/batch", publicCache(300), controller.getByIds);
router.get("/:id", publicCache(300), controller.getById);

// PROTECTED
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

router.post("/", controller.create);
router.patch("/:id", controller.update);

router.patch("/:id/softDelete", controller.softDelete);
router.patch("/:id/deactivate", controller.deactivate);
router.patch("/:id/activate", controller.activate);

export default router;

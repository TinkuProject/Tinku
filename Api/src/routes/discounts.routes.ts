import { Router } from "express";
import { DiscountsController } from "../controllers/discounts.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new DiscountsController();

router.get("/", controller.getAll);
router.get("/active", controller.getActive);
router.get("/businesses", controller.getByBusinesses);
router.get("/business/:businessId", controller.getByBusinessId);
router.get("/business/:businessId/active", controller.getActiveByBusinessId);
router.get("/my", authMiddleware, roleMiddleware(["partner", "admin", "master"]), controller.getMine);
router.get("/:id", controller.getById);

// PROTECTED
router.use(authMiddleware);
router.use(roleMiddleware(["partner", "admin", "master"]));

router.post("/", controller.create);
router.put("/:id", controller.update);
router.delete("/:id", controller.softDelete);

export default router;

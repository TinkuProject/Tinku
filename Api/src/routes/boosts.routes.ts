import { Router } from "express";
import { BoostsController } from "../controllers/boosts.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new BoostsController();

// PUBLIC
router.get("/active", controller.getActive);
router.get("/entity/:entityType/:entityId", controller.getByEntity);
router.get("/", controller.getAll);
router.get("/mine", authMiddleware, roleMiddleware(["admin", "master", "partner"]), controller.getMine);
router.get("/promotable-businesses", authMiddleware, roleMiddleware(["admin", "master", "partner"]), controller.getPromotableBusinesses);
router.get("/:id", controller.getById);

// PROTECTED
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master", "partner"]));

router.post("/", controller.create);
router.put("/:id", controller.update);
router.patch("/:id/softDelete", controller.softDelete);

export default router;

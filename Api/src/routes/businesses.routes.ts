import { Router } from "express";
import { BusinessesController } from "../controllers/businesses.controller";
import {
  authMiddleware,
  optionalAuthMiddleware,
} from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const controller = new BusinessesController();
const router = Router();

router.get("/", optionalAuthMiddleware, controller.getAll);
router.get("/category/:categoryId", optionalAuthMiddleware, controller.getByCategory);
router.get("/batch", optionalAuthMiddleware, controller.getByIds);
router.get("/mine", authMiddleware, controller.getMine);
router.get("/claimable", authMiddleware, roleMiddleware(["partner"]), controller.getClaimable);
router.get("/status", authMiddleware, roleMiddleware(["admin", "master"]), controller.getByStatus);
router.get("/:id/detail", optionalAuthMiddleware, controller.getDetail);
router.get("/:id", optionalAuthMiddleware, controller.getById);

router.use(authMiddleware);

router.post("/system", roleMiddleware(["admin", "master"]), controller.createSystem);
router.post("/", roleMiddleware(["partner", "admin", "master"]), controller.createOwned);
router.put("/:id", roleMiddleware(["admin", "master"]), controller.update);
router.patch("/:id/validate", roleMiddleware(["admin", "master"]), controller.validate);
router.patch("/:id/reject", roleMiddleware(["admin", "master"]), controller.reject);
router.delete("/:id", roleMiddleware(["partner", "admin", "master"]), controller.softDelete);

export default router;

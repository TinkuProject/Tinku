import { Router } from "express";
import { UserVisitsController } from "../controllers/user-visits.controller";
import { authMiddleware } from "../middlewares/auth.middleware";

const router = Router();
const controller = new UserVisitsController();

// todo requiere usuario autenticado
router.use(authMiddleware);

router.post("/", controller.create);
router.get("/my", controller.getByUser);
router.get("/entity-counts", controller.countByEntities);
router.get("/entity/:entityType/:entityId", controller.getByEntity);
router.delete("/:entityType/:entityId", controller.delete);

export default router;

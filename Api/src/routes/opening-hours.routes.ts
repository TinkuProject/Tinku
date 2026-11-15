import { Router } from "express";
import { OpeningHoursController } from "../controllers/opening-hours.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new OpeningHoursController();

router.get("/id/:id", controller.getById);
router.get("/entities", controller.getByEntities);
router.get("/:entityType/:entityId", controller.getByEntity);

router.use(authMiddleware);
router.use(roleMiddleware(["partner", "admin", "master"]));

router.post("/", controller.create);

router.patch("/:id", controller.update);
router.delete("/:id", controller.delete);

router.delete("/:entityType/:entityId", controller.deleteByEntity);
router.put("/:entityType/:entityId", controller.replaceAll);

export default router;

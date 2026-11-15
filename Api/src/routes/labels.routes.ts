import { Router } from "express";
import { LabelsController } from "../controllers/labels.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new LabelsController();

router.use(authMiddleware);
router.use(roleMiddleware(["master"]));

router.get("/", controller.getAll);
router.get("/:id", controller.getById);
router.post("/", controller.create);
router.put("/:id", controller.update);
router.delete("/:id", controller.delete);

export default router;
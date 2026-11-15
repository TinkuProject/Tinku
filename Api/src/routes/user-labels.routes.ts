import { Router } from "express";
import { UserLabelsController } from "../controllers/user-labels.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new UserLabelsController();

// todo requiere autenticación
router.use(authMiddleware);

router.get("/me", controller.getMyLabels);

router.use(roleMiddleware(["master"]));

router.get("/:user_id", controller.getByUser);
router.post("/assign", controller.assign);
router.delete("/remove", controller.remove);

export default router;
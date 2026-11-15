import { Router } from "express";
import { LabelPermissionsController } from "../controllers/label-permissions.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new LabelPermissionsController();

// PROTECTED
router.use(authMiddleware);
router.use(roleMiddleware(["master"]));

// obtener permisos de un label
router.get("/:label_id", controller.getByLabel);

// asignar permiso
router.post("/", controller.assign);

// eliminar relación específica
router.delete("/:label_id/:permission_id", controller.remove);

// eliminar todos los permisos de un label
router.delete("/:label_id", controller.removeAllByLabel);

export default router;
import { Router } from "express";
import { RolePermissionsController } from "../controllers/role-permissions.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { permissionMiddleware } from "../middlewares/role.middleware";
import { PERMISSIONS } from "../constants/permissions.constants";

const router = Router();
const controller = new RolePermissionsController();

router.use(authMiddleware);
router.use(permissionMiddleware(PERMISSIONS.authorizationManage));

router.post("/assign", controller.assign);
router.delete("/:role/:permission_id", controller.remove);
router.get("/:role", controller.getByRole);

export default router;

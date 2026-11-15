import { Router } from "express";
import { PermissionsController } from "../controllers/permissions.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { permissionMiddleware, roleMiddleware } from "../middlewares/role.middleware";
import { PERMISSIONS } from "../constants/permissions.constants";

const router = Router();
const controller = new PermissionsController();

// todo requiere usuario
router.use(authMiddleware);

// =========================
// ADMIN ONLY
// =========================

// ADMIN / MASTER
router.get("/", roleMiddleware(["admin", "master"]), controller.getAll);
router.get("/code/:code", roleMiddleware(["admin", "master"]), controller.getByCode);

// USER (solo lo suyo)
router.get("/me", controller.getMyPermissions);

router.get("/:id", roleMiddleware(["admin", "master"]), controller.getById);

// CRUD restringido
router.post("/", permissionMiddleware(PERMISSIONS.authorizationManage), controller.create);
router.put("/:id", permissionMiddleware(PERMISSIONS.authorizationManage), controller.update);
router.delete("/:id", permissionMiddleware(PERMISSIONS.authorizationManage), controller.delete);

export default router;

import { Router } from "express";
import { AuditLogsController } from "../controllers/audit-logs.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new AuditLogsController();

router.use(authMiddleware);

// ADMIN / MASTER ONLY
router.get("/filters", roleMiddleware(["admin", "master"]), controller.getByFilters);
router.get("/user/:userId", roleMiddleware(["admin", "master"]), controller.getByUser);
router.get("/entity/:entityType/:entityId", roleMiddleware(["admin", "master"]), controller.getByEntity);
router.get("/", roleMiddleware(["admin", "master"]), controller.getAll);
router.get("/:id", roleMiddleware(["admin", "master"]), controller.getById);

export default router;
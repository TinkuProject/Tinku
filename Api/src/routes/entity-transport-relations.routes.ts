import { Router } from "express";
import { EntityTransportRelationsController } from "../controllers/entity-transport-relations.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new EntityTransportRelationsController();

// PUBLIC
router.get("/entities", controller.getByEntities);
// obtener relaciones por entidad
router.get("/:entityType/:entityId", controller.getByEntity);

// PROTECTED
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master", "partner"]));

router.put("/:entityType/:entityId", controller.replaceLines);
router.post("/", controller.create);

// eliminar relación específica
router.delete("/:entityType/:entityId/:lineId", controller.delete);

// eliminar todas las relaciones de una entidad
router.delete("/:entityType/:entityId", controller.deleteByEntity);

export default router;

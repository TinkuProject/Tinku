import { Router } from "express";
import { TransportRoutesController } from "../controllers/transport-routes.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new TransportRoutesController();

// público
router.get("/lines", controller.getByLines);
router.get("/line/:lineId", controller.getByLine);
router.get("/line/:lineId/:direction", controller.getByLineAndDirection);

// protegido
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

router.post("/", controller.create);
router.post("/bulk",controller.createBulk); //Inserción masiva de rutas
router.delete("/:id", controller.delete);

export default router;

import { Router } from "express";
import { ReservationsController } from "../controllers/reservations.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new ReservationsController();

// AUTH REQUIRED 
router.use(authMiddleware);

router.post("/", controller.create);
router.get("/me", controller.getMine);
router.get("/event/:eventId/me", controller.getMineByEvent);
router.get("/event/:eventId", controller.getByEvent);
router.get("/:id", controller.getById);
router.put("/:id", controller.update);
router.delete("/:id", controller.delete);


router.use(roleMiddleware(["admin", "master"]));

router.get("/", controller.getAll);

export default router;
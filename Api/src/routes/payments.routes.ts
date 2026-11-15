import { Router } from "express";
import { PaymentsController } from "../controllers/payments.controller";
import { authMiddleware } from "../middlewares/auth.middleware";

const router = Router();
const controller = new PaymentsController();

// AUTH REQUIRED
router.use(authMiddleware);

router.post("/", controller.create);
router.get("/me", controller.getMine);
router.get("/:id", controller.getById);
router.patch("/:id", controller.softDelete); 

export default router;
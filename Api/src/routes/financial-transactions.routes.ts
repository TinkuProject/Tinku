import { Router } from "express";
import { FinancialTransactionsController } from "../controllers/financial-transactions.controller";
import { authMiddleware } from "../middlewares/auth.middleware";

const router = Router();
const controller = new FinancialTransactionsController();

// AUTH REQUIRED
router.use(authMiddleware);

router.get("/me", controller.getMine);
router.get("/me/latest", controller.getLatest);
router.get("/:id", controller.getById);

export default router;
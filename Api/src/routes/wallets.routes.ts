import { Router } from "express";
import { WalletsController } from "../controllers/wallets.controller";
import { authMiddleware } from "../middlewares/auth.middleware";

const router = Router();
const controller = new WalletsController();

router.use(authMiddleware);
// Usuario autenticado (su propia wallet)
router.get("/me", controller.getMyWallet);

export default router;
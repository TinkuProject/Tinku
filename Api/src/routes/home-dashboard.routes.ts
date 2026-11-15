import { Router } from "express";
import { HomeDashboardController } from "../controllers/home-dashboard.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new HomeDashboardController();

router.get(
  "/",
  authMiddleware,
  roleMiddleware(["partner", "admin", "master"]),
  controller.get
);

export default router;

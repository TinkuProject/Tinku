import { Router } from "express";
import { PaymentRequestsController } from "../controllers/payment-requests.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new PaymentRequestsController();

// =========================
// AUTH REQUIRED
// =========================
router.use(authMiddleware);

// =========================
// USER
// =========================
router.post("/", roleMiddleware(["user", "partner"]), controller.create);
router.get("/me", roleMiddleware(["user", "partner"]), controller.getMine);
router.get("/mine/partner-upgrade/pending", authMiddleware, controller.hasPendingPartnerUpgrade);

// =========================
// ADMIN / MASTER
// =========================
router.get("/", roleMiddleware(["admin", "master"]), controller.getAll);
router.get("/:id", roleMiddleware(["admin", "master"]), controller.getById);
router.patch("/:id/approve", roleMiddleware(["admin", "master"]), controller.approve);
router.patch("/:id/reject", roleMiddleware(["admin", "master"]), controller.reject);

export default router;
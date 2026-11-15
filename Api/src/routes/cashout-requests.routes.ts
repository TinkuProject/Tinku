import { Router } from "express";
import { CashoutRequestsController } from "../controllers/cashout-requests.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new CashoutRequestsController();

router.use(authMiddleware);

router.post("/", controller.create);
router.get("/me", controller.getMine);

router.use(roleMiddleware(["admin", "master"]));

router.get("/pending", controller.getPending);
router.get("/", controller.getAll);
router.get("/:id", controller.getById);
router.patch("/:id/approve", controller.approve);
router.patch("/:id/reject", controller.reject);

export default router;

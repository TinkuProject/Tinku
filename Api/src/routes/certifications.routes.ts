import { Router } from "express";
import { CertificationsController } from "../controllers/certifications.controller";
import { authMiddleware, optionalAuthMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new CertificationsController();

router.get("/business/:businessId", optionalAuthMiddleware, controller.getByBusiness);
router.get("/businesses", optionalAuthMiddleware, controller.getByBusinesses);
router.get(
  "/filters",
  authMiddleware,
  roleMiddleware(["admin", "master"]),
  controller.getByFilters
);
router.get("/", optionalAuthMiddleware, controller.getAll);
router.get("/:id", optionalAuthMiddleware, controller.getById);

// AUTH REQUIRED
router.use(authMiddleware);

router.post(
  "/",
  roleMiddleware(["admin", "master", "partner"]),
  controller.create
);
router.patch(
  "/:id",
  roleMiddleware(["admin", "master", "partner"]),
  controller.update
);

router.patch("/:id/softDelete", roleMiddleware(["admin", "master"]), controller.softDelete);
router.patch("/:id/activate", roleMiddleware(["admin", "master"]), controller.activate);
router.patch("/:id/deactivate", roleMiddleware(["admin", "master"]), controller.deactivate);

export default router;

import { Router } from "express";
import multer from "multer";
import { BusinessClaimRequestsController } from "../controllers/business-claim-requests.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new BusinessClaimRequestsController();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 20 * 1024 * 1024,
    files: 5,
  },
});

router.use(authMiddleware);

// PARTNER
router.post(
  "/documents",
  roleMiddleware(["partner"]),
  upload.array("files", 5),
  controller.uploadDocuments
);
router.post("/", roleMiddleware(["partner"]), controller.create);
router.get("/me",roleMiddleware(["partner"]), controller.getMyRequests);

// ADMIN
router.get("/pending", roleMiddleware(["admin", "master"]), controller.getPending);
router.patch("/:id/review", roleMiddleware(["admin", "master"]), controller.review);
router.get("/", roleMiddleware(["admin", "master"]), controller.getAll);

// BUSINESS
router.get("/business/:businessId", roleMiddleware(["admin", "master", "partner"]), controller.getByBusiness);

// GENERAL
router.get("/:id", roleMiddleware(["admin", "master", "partner"]), controller.getById);

export default router;

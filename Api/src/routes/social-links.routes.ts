import { Router } from "express";
import { SocialLinksController } from "../controllers/social-links.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new SocialLinksController();

router.get("/businesses", controller.getByBusinesses);
router.get("/business/:businessId", controller.getByBusiness);

router.use(authMiddleware);

router.post("/",roleMiddleware(["partner", "admin", "master"]), controller.create);
router.patch("/:id", roleMiddleware(["partner", "admin", "master"]), controller.update);
router.delete("/:id", roleMiddleware(["partner", "admin", "master"]), controller.delete);

export default router;

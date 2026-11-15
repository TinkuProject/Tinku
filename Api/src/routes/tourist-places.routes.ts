import { Router } from "express";
import { TouristPlacesController } from "../controllers/tourist-places.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new TouristPlacesController();

// lectura pública
router.get("/list", controller.getPreviewList);
router.get("/", controller.getAll);
router.get("/category/:categoryId", controller.getByCategory);
router.get("/batch", controller.getByIds);
router.get(
  "/mine",
  authMiddleware,
  roleMiddleware(["admin", "master"]),
  controller.getMine
);
router.get("/:id", controller.getById);

// modificaciones protegidas
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

router.post("/", controller.create);
router.put("/:id", controller.update);
router.patch("/:id/archive", controller.softDelete);

export default router;

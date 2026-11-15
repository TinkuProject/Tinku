import { Router } from "express";
import { TouristPlaceTagsController } from "../controllers/tourist-place-tags.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new TouristPlaceTagsController();

// lectura pública
router.get("/place/:placeId", controller.getByPlace);
router.get("/tag/:tagId", controller.getByTag);

// modificaciones protegidas
router.use(authMiddleware);
router.use(roleMiddleware(["admin", "master"]));

router.post("/", controller.create);
router.put("/place/:placeId", controller.replaceTags);
router.delete("/:placeId/:tagId", controller.delete);

export default router;
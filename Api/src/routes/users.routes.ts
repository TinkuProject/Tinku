import { Router } from "express";
import multer from "multer";
import { UsersController } from "../controllers/users.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const controller = new UsersController();
const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
});

router.get("/batch", controller.getByIds);

router.use(authMiddleware);

router.get("/me/profile-picture", controller.getProfilePicture);
router.post(
  "/me/profile-picture",
  upload.single("file"),
  controller.updateProfilePicture
);
router.put("/me", controller.updateMe);

// acciones administrativas
router.use(roleMiddleware(["admin", "master"]));

router.get("/", controller.getAll);
router.post("/", controller.create);
router.get("/:id", controller.getById);
router.put("/:id", controller.update);
router.delete("/:id", controller.delete);

export default router;

import { Router } from "express";
import { NotificationsController } from "../controllers/notifications.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new NotificationsController();

// =========================
// PROTECTED (TODO requiere usuario)
// =========================
router.use(authMiddleware);

// crear notificación manual solo desde administración.
// Los flujos internos usan NotificationsService directamente.
router.post("/", roleMiddleware(["admin", "master"]), controller.create);

// mis notificaciones
router.get("/me/paginated", controller.getMyNotificationsPage);
router.get("/me", controller.getMyNotifications);

// contador no leídas
router.get("/unread-count", controller.getUnreadCount);

// tokens de dispositivo para push notifications
router.post("/device-tokens", controller.registerDeviceToken);
router.post("/device-tokens/remove", controller.unregisterDeviceToken);

// marcar todas como leídas
router.patch("/read-all", controller.markAllAsRead);
router.delete("/all", controller.deleteAll);

router.post(
  "/broadcast/admins",
  roleMiddleware(["admin", "master"]),
  controller.broadcastToAdmins
);

router.get("/:id", controller.getById);
router.patch("/:id/read", controller.markAsRead);
// actualizar (limitado a read básicamente)
router.put("/:id", controller.update);
router.delete("/:id", controller.delete);

export default router;

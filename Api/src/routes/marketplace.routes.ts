import { Router } from "express";
import { MarketplaceController } from "../controllers/marketplace.controller";
import {
  authMiddleware,
  optionalAuthMiddleware,
} from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";
import { pickupRateLimiter } from "../middlewares/security.middleware";

const router = Router();
const controller = new MarketplaceController();

router.get("/publications", controller.listPublic);
router.get("/publications/:id", controller.getPublicationById);
router.post(
  "/businesses/:businessId/views",
  optionalAuthMiddleware,
  controller.registerBusinessView
);

router.use(authMiddleware);

router.get(
  "/businesses/view-stats/batch",
  roleMiddleware(["partner", "admin", "master"]),
  controller.getBusinessViewStatsBatch
);

router.get(
  "/admin/publications",
  roleMiddleware(["admin", "master"]),
  controller.listAdmin
);
router.get(
  "/admin/orders",
  roleMiddleware(["admin", "master"]),
  controller.listAdminOrders
);
router.patch(
  "/admin/orders/:id/status",
  roleMiddleware(["admin", "master"]),
  controller.updateOrderStatus
);
router.patch(
  "/admin/deliveries/:id/status",
  roleMiddleware(["admin", "master"]),
  controller.updateDeliveryStatus
);

router.get(
  "/publications/mine/list",
  roleMiddleware(["partner", "admin", "master"]),
  controller.listMine
);
router.post(
  "/publications/estimate",
  roleMiddleware(["partner", "admin", "master"]),
  controller.estimatePublication
);
router.post(
  "/publications",
  roleMiddleware(["partner", "admin", "master"]),
  controller.createPublication
);
router.patch(
  "/publications/:id/stock",
  roleMiddleware(["partner", "admin", "master"]),
  controller.updatePublicationStock
);
router.patch(
  "/publications/:id/status",
  roleMiddleware(["partner", "admin", "master"]),
  controller.updatePublicationStatus
);
router.get(
  "/publications/:id/history",
  roleMiddleware(["partner", "admin", "master"]),
  controller.publicationHistory
);

router.post("/orders", controller.createOrder);
router.get("/orders/mine/list", controller.listMyOrders);
router.get("/orders/warehouse/list", roleMiddleware(["partner", "admin", "master"]), controller.listWarehouseOrders);
router.patch("/orders/warehouse/:id/ready", roleMiddleware(["partner", "admin", "master"]), controller.markWarehouseOrderReady);
router.get(
  "/orders/sales/list",
  roleMiddleware(["partner", "admin", "master"]),
  controller.listSalesOrders
);
router.patch(
  "/orders/sales/:id/status",
  roleMiddleware(["partner", "admin", "master"]),
  controller.updateSalesOrderStatus
);
router.post(
  "/orders/sales/:id/reject",
  roleMiddleware(["partner", "admin", "master"]),
  controller.rejectSalesOrder
);
router.post(
  "/orders/validate-pickup",
  roleMiddleware(["partner", "admin", "master"]),
  pickupRateLimiter,
  controller.validatePickupCode
);
router.post("/orders/:id/cancel", controller.cancelOrder);
router.get("/orders/:id", controller.getOrderById);

router.get(
  "/businesses/:businessId/view-stats",
  roleMiddleware(["partner", "admin", "master"]),
  controller.getBusinessViewStats
);

export default router;

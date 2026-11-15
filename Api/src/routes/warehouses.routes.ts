import { Router } from "express";
import { WarehousesController } from "../controllers/warehouses.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { roleMiddleware } from "../middlewares/role.middleware";

const router = Router();
const controller = new WarehousesController();

router.get("/business/:businessId/fulfillment", controller.getBusinessFulfillment);
router.get("/", controller.getActive);
router.get("/:id", controller.getById);

router.use(authMiddleware);

router.get(
  "/stock-requests/received",
  roleMiddleware(["partner", "admin", "master"]),
  controller.getReceivedStockRequests
);
router.get(
  "/stock-requests/sent",
  roleMiddleware(["partner", "admin", "master"]),
  controller.getSentStockRequests
);
router.post(
  "/stock-requests",
  roleMiddleware(["partner", "admin", "master"]),
  controller.createStockRequest
);
router.patch(
  "/stock-requests/:requestId/approve",
  roleMiddleware(["partner", "admin", "master"]),
  controller.approveStockRequest
);
router.patch(
  "/stock-requests/:requestId/mark-sent",
  roleMiddleware(["partner", "admin", "master"]),
  controller.markStockRequestSent
);
router.patch(
  "/stock-requests/:requestId/receive",
  roleMiddleware(["partner", "admin", "master"]),
  controller.receiveStockRequest
);
router.patch(
  "/stock-requests/:requestId/reject",
  roleMiddleware(["partner", "admin", "master"]),
  controller.rejectStockRequest
);
router.get("/mine/list", roleMiddleware(["partner", "admin", "master"]), controller.getMine);
router.get(
  "/admin/all",
  roleMiddleware(["admin", "master"]),
  controller.getAll
);
router.post(
  "/",
  roleMiddleware(["partner", "admin", "master"]),
  controller.create
);
router.put(
  "/:id",
  roleMiddleware(["partner", "admin", "master"]),
  controller.update
);
router.patch(
  "/:id/status",
  roleMiddleware(["admin", "master"]),
  controller.updateStatus
);
router.patch(
  "/:id/approve",
  roleMiddleware(["admin", "master"]),
  controller.approve
);
router.patch(
  "/:id/reject",
  roleMiddleware(["admin", "master"]),
  controller.reject
);
router.get(
  "/:id/locations",
  roleMiddleware(["partner", "admin", "master"]),
  controller.getLocations
);
router.post(
  "/:id/locations",
  roleMiddleware(["partner", "admin", "master"]),
  controller.createLocation
);
router.patch(
  "/:id/locations/:locationId",
  roleMiddleware(["partner", "admin", "master"]),
  controller.updateLocation
);
router.delete(
  "/:id/locations/:locationId",
  roleMiddleware(["partner", "admin", "master"]),
  controller.deleteLocation
);
router.get(
  "/:id/inventory",
  roleMiddleware(["partner", "admin", "master"]),
  controller.getInventory
);
router.patch(
  "/:id/inventory/:inventoryId/location",
  roleMiddleware(["partner", "admin", "master"]),
  controller.setInventoryLocation
);
router.put(
  "/:id/inventory",
  roleMiddleware(["partner", "admin", "master"]),
  controller.upsertInventory
);
router.get(
  "/:id/product-history",
  roleMiddleware(["partner", "admin", "master"]),
  controller.getProductHistory
);
router.put(
  "/business/:businessId/fulfillment",
  roleMiddleware(["partner", "admin", "master"]),
  controller.setBusinessFulfillment
);

export default router;

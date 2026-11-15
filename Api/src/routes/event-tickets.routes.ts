import { Router } from "express";
import { EventTicketsController } from "../controllers/event-tickets.controller";
import { authMiddleware } from "../middlewares/auth.middleware";

const router = Router();
const controller = new EventTicketsController();

router.use(authMiddleware);

router.get("/me", controller.getMine);
router.get("/reservation/:reservationId", controller.getByReservation);
router.get("/event/:eventId", controller.getByEvent);
router.post("/days/:ticketDayId/qr", controller.issueQr);
router.post("/check-in", controller.checkIn);
router.get("/:id", controller.getById);

export default router;

import { Router } from "express";
import { NearbyController } from "../controllers/nearby.controller";

const router = Router();
const controller = new NearbyController();

router.get("/", controller.getNearby);

export default router;
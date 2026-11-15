import { Router } from "express";
import { ExploreController } from "../controllers/explore.controller";

const router = Router();
const controller = new ExploreController();

router.get("/feed", controller.getFeed);

export default router;

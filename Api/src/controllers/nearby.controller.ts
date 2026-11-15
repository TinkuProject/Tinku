import { Request, Response } from "express";
import { NearbyService } from "../services/nearby.service";
import { NearbyDAO } from "../dao/nearby.dao";
import { nearbyQuerySchema } from "../validation/nearby.validation";
import { handleError } from "../utils/handleError";
import { supabasePublic } from "../config/supabase-client.config";

export class NearbyController {
    private getPublicService(): NearbyService {
        const dao = new NearbyDAO(supabasePublic);
        return new NearbyService(dao);
    }

    getNearby = async (req: Request, res: Response) => {
        try {
            const service = this.getPublicService();
            const { lat, lng, radius } = nearbyQuerySchema.parse(req.query);

            const data = await service.getNearby({
                lat,
                lng,
                ...(radius !== undefined && { radius }),
            });

            res.json(data);
        } catch (err) {
            handleError(res, err);
        }
    };
}
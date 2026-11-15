import { Request, Response } from "express";
import { ReviewsService } from "../services/reviews.service";
import { ReviewsDAO } from "../dao/reviews.dao";
import { NotificationsDAO } from "../dao/notifications.dao";
import { NotificationsService } from "../services/notifications.service";
import { reviewCreateSchema, reviewReplySchema, reviewUpdateSchema, reviewIdParamSchema,
    reviewEntityParamSchema, ReviewEntitiesQuery,
    reviewEntitiesQuerySchema} from "../validation/reviews.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";

export class ReviewsController {
    private getService(req: Request): ReviewsService {
        const db = getUserClientFromRequest(req);
        const dao = new ReviewsDAO(db);
        const notificationsDao = new NotificationsDAO(supabaseAdmin);
        const notificationsService = new NotificationsService(notificationsDao);
        return new ReviewsService(dao, notificationsService);
    }

    private getPublicService(): ReviewsService {
        const dao = new ReviewsDAO(supabasePublic);
        return new ReviewsService(dao);
    }

    private parseEntitiesQuery(req: Request): ReviewEntitiesQuery {
        return reviewEntitiesQuerySchema.parse({
            entity_type: req.query.entity_type,
            entity_ids: req.query.entity_ids,
        });
        }

    create = async (req: Request, res: Response): Promise<void> => {
        try {
            const service = this.getService(req);

            const userId = req.user!.id;
            const data = reviewCreateSchema.parse(req.body);

            const result = await service.create(userId, data);
            res.status(201).json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    getAll = async (req: Request, res: Response): Promise<void> => {
        try {
            const service = this.getService(req);
            const result = await service.getAll();

            res.json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    getById = async (req: Request, res: Response): Promise<void> => {
        try {
            const service = this.getService(req);
            const { id } = reviewIdParamSchema.parse(req.params);

            const result = await service.getById(id);
            res.json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    getByEntity = async (req: Request, res: Response): Promise<void> => {
        try {
            const service = this.getPublicService();
            const { entityType, entityId } =
                reviewEntityParamSchema.parse(req.params);

            const result = await service.getByEntity(
                entityType,
                entityId
            );

            res.json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    getByEntities = async (req: Request, res: Response): Promise<void> => {
        try {
            const service = this.getPublicService();
            const validated = this.parseEntitiesQuery(req);

            const result = await service.getByEntities(
            validated.entity_type, validated.entity_ids);

            res.json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    getByUser = async (req: Request, res: Response): Promise<void> => {
        try {
            const service = this.getService(req);
            const userId = req.user!.id;

            const result = await service.getByUser(userId);
            res.json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    getManaged = async (req: Request, res: Response): Promise<void> => {
        try {
            const service = this.getService(req);

            if (!req.user?.id) {
                throw new Error("Unauthorized");
            }

            const result = await service.getManagedByOwner(req.user);
            res.json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    reply = async (req: Request, res: Response): Promise<void> => {
        try {
            const service = this.getService(req);

            if (!req.user?.id) {
                throw new Error("Unauthorized");
            }

            const { id } = reviewIdParamSchema.parse(req.params);
            const data = reviewReplySchema.parse(req.body);
            const result = await service.reply(id, req.user, data.reply);

            res.json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    update = async (req: Request, res: Response): Promise<void> => {
        try {
            const service = this.getService(req);
            const userId = req.user!.id;
            const { id } = reviewIdParamSchema.parse(req.params);

            const rawData = reviewUpdateSchema.parse(req.body);

            const data = Object.fromEntries(
                Object.entries(rawData).filter(([_, v]) => v !== undefined)
            );

            const result = await service.update(id, userId, data);
            res.json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    softDelete = async (req: Request, res: Response): Promise<void> => {
        try {
            const service = this.getService(req);
            const { id } = reviewIdParamSchema.parse(req.params);

            await service.softDelete(id, req.user!);
            res.status(204).send();
        } catch (err) {
            return handleError(res, err);
        }
    };
}

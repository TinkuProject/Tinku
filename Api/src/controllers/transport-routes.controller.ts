import { Request, Response } from "express";
import { TransportRoutesService } from "../services/transport-routes.service";
import { TransportRoutesDAO } from "../dao/transport-routes.dao";
import { transportRouteCreateSchema, transportRouteIdSchema,
    transportRouteByLineSchema, transportRouteByLineAndDirectionSchema,
    transportRouteCreateBulkSchema, transportRoutesByLinesSchema } from "../validation/transport-routes.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";
import { EntityTransportRelationsDAO } from "../dao/entity-transport-relations.dao";
import { EntityTransportRelationsService } from "../services/entity-transport-relations.service";

export class TransportRoutesController {
    private getService(req: Request): TransportRoutesService {
        const db = getUserClientFromRequest(req);
        const dao = new TransportRoutesDAO(db);
        const relationsDao = new EntityTransportRelationsDAO(supabaseAdmin);
        const relationsService = new EntityTransportRelationsService(relationsDao);
        return new TransportRoutesService(dao, relationsService);
    }

    private getPublicService(): TransportRoutesService {
        const dao = new TransportRoutesDAO(supabasePublic);
        const relationsDao = new EntityTransportRelationsDAO(supabasePublic);
        const relationsService = new EntityTransportRelationsService(relationsDao);
        return new TransportRoutesService(dao, relationsService);
    }

    create = async (req: Request, res: Response): Promise<void> => {
        try {
            const input = transportRouteCreateSchema.parse(req.body);

            const service = this.getService(req);
            const result = await service.create(input);

            res.status(201).json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    createBulk = async (req: Request, res: Response): Promise<void> => {
        try {
            const inputs = transportRouteCreateBulkSchema.parse(req.body);

            const service = this.getService(req);
            const result = await service.createBulk(inputs);

            res.status(201).json(result);
        } catch (err) {
            return handleError(res, err);
        }
    };

    getByLine = async (req: Request, res: Response): Promise<void> => {
        try {
            const input = transportRouteByLineSchema.parse({
                transport_line_id: Number(req.params.lineId),
            });

            const service = this.getPublicService();
            const data = await service.getByLine(input);

            res.json(data);
        } catch (err) {
            return handleError(res, err);
        }
    };

    getByLines = async (req: Request, res: Response): Promise<void> => {
        try {
            const input = transportRoutesByLinesSchema.parse({
                line_ids: req.query.line_ids,
                direction: req.query.direction,
            });

            const service = this.getPublicService();
            const data = await service.getByLines(
                input.line_ids,
                input.direction
            );

            res.json(data);
        } catch (err) {
            return handleError(res, err);
        }
    };

    getByLineAndDirection = async (
        req: Request,
        res: Response
    ): Promise<void> => {
        try {
            const input = transportRouteByLineAndDirectionSchema.parse({
                transport_line_id: Number(req.params.lineId),
                direction: req.params.direction,
            });

            const service = this.getPublicService();
            const data = await service.getByLineAndDirection(
                input.transport_line_id,
                input.direction
            );

            res.json(data);
        } catch (err) {
            return handleError(res, err);
        }
    };

    delete = async (req: Request, res: Response): Promise<void> => {
        try {
            const input = transportRouteIdSchema.parse({
                id: Number(req.params.id),
            });

            const service = this.getService(req);
            await service.delete(input);

            res.status(204).send();
        } catch (err) {
            return handleError(res, err);
        }
    };
}

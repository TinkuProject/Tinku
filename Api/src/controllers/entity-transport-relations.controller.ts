import { Request, Response } from "express";
import { EntityTransportRelationsService } from "../services/entity-transport-relations.service";
import { EntityTransportRelationsDAO } from "../dao/entity-transport-relations.dao";
import { entityTransportRelationCreateSchema, entityTransportRelationParamsSchema,
  entityTransportRelationDeleteSchema, entityTransportRelationReplaceSchema,
  entityTransportRelationsQuerySchema
} from "../validation/entity-transport-relations.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic } from "../config/supabase-client.config";

export class EntityTransportRelationsController {

  private getService(req: Request): EntityTransportRelationsService {
    const db = getUserClientFromRequest(req);
    const dao = new EntityTransportRelationsDAO(db);
    return new EntityTransportRelationsService(dao);
  }

  private getPublicService(): EntityTransportRelationsService {
    const dao = new EntityTransportRelationsDAO(supabasePublic);
    return new EntityTransportRelationsService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const data = entityTransportRelationCreateSchema.parse(req.body);

      const result = await service.create(data);
      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByEntity = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { entityType, entityId } =
        entityTransportRelationParamsSchema.parse(req.params);

      const result = await service.getByEntity(entityType, entityId);
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByEntities = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { entity_type, entity_ids } =
        entityTransportRelationsQuerySchema.parse({
          entity_type: req.query.entity_type,
          entity_ids: req.query.entity_ids,
        });

      const result = await service.getByEntities(entity_type, entity_ids);
      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  replaceLines = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);

      const parsed = entityTransportRelationReplaceSchema.parse({
        params: req.params,
        body: req.body,
      });

      const { entityType, entityId } = parsed.params;
      const { line_ids } = parsed.body;

      await service.replaceLines(entityType, entityId, line_ids);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { entityType, entityId, lineId } =
        entityTransportRelationDeleteSchema.parse(req.params);

      await service.delete(entityType, entityId, lineId);
      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  deleteByEntity = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const { entityType, entityId } =
        entityTransportRelationParamsSchema.parse(req.params);

      await service.deleteByEntity(entityType, entityId);
      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };
}

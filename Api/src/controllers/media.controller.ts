import { Request, Response } from "express";
import { MediaService } from "../services/media.service";
import { MediaDAO } from "../dao/media.dao";
import { createMediaSchema, updateMediaSchema, mediaIdParamSchema,
  mediaEntityQuerySchema, mediaUrlSchema, MediaEntityQuery,
  mediaEntitiesQuerySchema,
  MediaEntitiesQuery
} from "../validation/media.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin } from "../config/supabase-client.config";
import { OwnershipService } from "../services/ownership.service";
import { isPrivileged } from "../helper/role.helper";
import { PublicEntityVisibilityService } from "../services/public-entity-visibility.service";

export class MediaController {

  private getService(req: Request): MediaService {
    const db = getUserClientFromRequest(req);
    const dao = new MediaDAO(db);
    return new MediaService(dao);
  }

  private getPublicService(): MediaService {
    const dao = new MediaDAO(supabaseAdmin);
    return new MediaService(dao);
  }

  private parseEntityQuery(req: Request): MediaEntityQuery {
    return mediaEntityQuerySchema.parse({
      entity_type: req.query.entity_type,
      entity_id: req.query.entity_id,
    });
  }

  private parseEntitiesQuery(req: Request): MediaEntitiesQuery {
    return mediaEntitiesQuerySchema.parse({
      entity_type: req.query.entity_type,
      entity_ids: req.query.entity_ids,
    });
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const validated = createMediaSchema.parse(req.body);
      await new OwnershipService(supabaseAdmin).validate(
        validated.entity_type,
        validated.entity_id,
        req.user!
      );

      const media = await service.create(validated);
      res.status(201).json(media);
    } catch (err) {
      return handleError(res, err, req);
    }
  };

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const rows = await service.getAll();

      res.json(rows);
    } catch (err) {
      return handleError(res, err, req);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const { id } = mediaIdParamSchema.parse(req.params);

      const row = await service.getById(id);

      if (
        !isPrivileged(req.user?.role ?? "") &&
        !(await PublicEntityVisibilityService.isVisible(
          row.entity_type,
          row.entity_id,
          req.user?.id
        ))
      ) {
        throw new Error("Media not found");
      }

      res.json(row);
    } catch (err) {
      return handleError(res, err, req);
    }
  };

  getByEntities = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const validated = this.parseEntitiesQuery(req);

      const entityIds = isPrivileged(req.user?.role ?? "")
        ? validated.entity_ids
        : await PublicEntityVisibilityService.filterVisibleIds(
            validated.entity_type,
            validated.entity_ids,
            req.user?.id
          );

      const result = await service.getByEntities(
        entityIds,
        validated.entity_type
      );

      res.json(result);
    } catch (err) {
      return handleError(res, err, req);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = mediaIdParamSchema.parse(req.params);
      const existing = await service.getById(id);
      await new OwnershipService(supabaseAdmin).validate(
        existing.entity_type,
        existing.entity_id,
        req.user!
      );

      const rawData = updateMediaSchema.parse(req.body);

      const data = Object.fromEntries(
        Object.entries(rawData).filter(([_, v]) => v !== undefined)
      );

      const updated = await service.update(id, data);
      res.json(updated);
    } catch (err) {
      return handleError(res, err, req);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { id } = mediaIdParamSchema.parse(req.params);
      const existing = await service.getById(id);
      await new OwnershipService(supabaseAdmin).validate(
        existing.entity_type,
        existing.entity_id,
        req.user!
      );

      await service.delete(id);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err, req);
    }
  };

  getByEntity = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const validated = this.parseEntityQuery(req);

      if (
        !isPrivileged(req.user?.role ?? "") &&
        !(await PublicEntityVisibilityService.isVisible(
          validated.entity_type,
          validated.entity_id,
          req.user?.id
        ))
      ) {
        res.json([]);
        return;
      }

      const mediaList = await service.getByEntity(
        validated.entity_id,
        validated.entity_type
      );

      res.json(mediaList);
    } catch (err) {
      return handleError(res, err, req);
    }
  };

  getPrimaryByEntity = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getPublicService();
      const validated = this.parseEntityQuery(req);

      if (
        !isPrivileged(req.user?.role ?? "") &&
        !(await PublicEntityVisibilityService.isVisible(
          validated.entity_type,
          validated.entity_id,
          req.user?.id
        ))
      ) {
        res.json(null);
        return;
      }

      const media = await service.getPrimaryByEntity(
        validated.entity_id,
        validated.entity_type
      );

      res.json(media);
    } catch (err) {
      return handleError(res, err, req);
    }
  };

  deleteAllByEntity = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const service = this.getService(req);
      const validated = this.parseEntityQuery(req);
      await new OwnershipService(supabaseAdmin).validate(
        validated.entity_type,
        validated.entity_id,
        req.user!
      );

      await service.deleteAllByEntity(
        validated.entity_id,
        validated.entity_type
      );

      res.status(204).send();
    } catch (err) {
      return handleError(res, err, req);
    }
  };

  deleteByUrl = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const { url } = mediaUrlSchema.parse(req.body);
      const existing = await service.getByUrl(url);
      await new OwnershipService(supabaseAdmin).validate(
        existing.entity_type,
        existing.entity_id,
        req.user!
      );

      await service.deleteByUrl(url);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err, req);
    }
  };
}

import { Request, Response } from "express";
import { TouristPlaceTagsService } from "../services/tourist-place-tags.service";
import { TouristPlaceTagsDAO } from "../dao/tourist-place-tags.dao";
import { touristPlaceTagSchema, touristPlaceIdSchema, tagIdSchema,
} from "../validation/tourist-place-tags.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic } from "../config/supabase-client.config";

export class TouristPlaceTagsController {
  private getService(req: Request): TouristPlaceTagsService {
    const db = getUserClientFromRequest(req);
    const dao = new TouristPlaceTagsDAO(db);
    return new TouristPlaceTagsService(dao);
  }

  private getPublicService(): TouristPlaceTagsService {
    const dao = new TouristPlaceTagsDAO(supabasePublic);
    return new TouristPlaceTagsService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = touristPlaceTagSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(input);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByPlace = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = touristPlaceIdSchema.parse({
        tourist_place_id: Number(req.params.placeId),
      });

      const service = this.getPublicService();
      const data = await service.getByPlace(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByTag = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = tagIdSchema.parse({
        tag_id: Number(req.params.tagId),
      });

      const service = this.getPublicService();
      const data = await service.getByTag(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = touristPlaceTagSchema.parse({
        tourist_place_id: Number(req.params.placeId),
        tag_id: Number(req.params.tagId),
      });

      const service = this.getService(req);
      await service.delete(input);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  replaceTags = async (req: Request, res: Response): Promise<void> => {
    try {
      const place = touristPlaceIdSchema.parse({
        tourist_place_id: Number(req.params.placeId),
      });

      const { tagIds } = req.body;

      if (!Array.isArray(tagIds)) {
        throw new Error("tagIds must be an array");
      }

      const service = this.getService(req);
      const result = await service.replaceTags(place, tagIds);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}
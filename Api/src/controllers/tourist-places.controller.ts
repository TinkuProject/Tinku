import { Request, Response } from "express";
import { TouristPlacesService } from "../services/tourist-places.service";
import { TouristPlacesDAO } from "../dao/tourist-places.dao";
import { touristPlaceCreateSchema, touristPlaceUpdateSchema, touristPlaceIdSchema,
  touristPlaceCategorySchema, touristPlaceBatchSchema } from "../validation/tourist-places.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";
import { EntityTransportRelationsDAO } from "../dao/entity-transport-relations.dao";
import { EntityTransportRelationsService } from "../services/entity-transport-relations.service";
import { CategoriesDAO } from "../dao/categories.dao";
import { MediaDAO } from "../dao/media.dao";

export class TouristPlacesController {
  private getService(req: Request): TouristPlacesService {
    const db = getUserClientFromRequest(req);
    const dao = new TouristPlacesDAO(db);
    const transportRelationsDao = new EntityTransportRelationsDAO(supabaseAdmin);
    const transportRelationsService = new EntityTransportRelationsService(transportRelationsDao);
    return new TouristPlacesService(dao, transportRelationsService);
  }

  private getPublicService(): TouristPlacesService {
    const dao = new TouristPlacesDAO(supabasePublic);
    const transportRelationsDao = new EntityTransportRelationsDAO(supabasePublic);
    const transportRelationsService = new EntityTransportRelationsService(transportRelationsDao);
    return new TouristPlacesService(dao, transportRelationsService);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      if (!req.user?.id) {
        throw new Error("Unauthorized");
      }

      const input = touristPlaceCreateSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(input, req.user);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const data = await service.getAll();

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = touristPlaceIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getPublicService();
      const data = await service.getById(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      if (!req.user?.id) {
        throw new Error("Unauthorized");
      }

      const limit = this.readBoundedNumber(req.query.limit, 20, 1, 100);
      const offset = this.readBoundedNumber(req.query.offset, 0, 0, 100000);

      const service = this.getService(req);
      const data = await service.getMine(req.user.id, limit, offset);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getPreviewList = async (req: Request, res: Response): Promise<void> => {
    try {
      const limit = this.readBoundedNumber(req.query.limit, 20, 1, 100);
      const offset = this.readBoundedNumber(req.query.offset, 0, 0, 100000);

      const placesDao = new TouristPlacesDAO(supabasePublic);
      const categoriesDao = new CategoriesDAO(supabasePublic);
      const mediaDao = new MediaDAO(supabasePublic);

      const [places, categories] = await Promise.all([
        placesDao.findAll(limit, offset),
        categoriesDao.findAll(),
      ]);

      const categoryNames = new Map(
        categories.map((category) => [category.id, category.name])
      );
      const placeIds = places.map((place) => String(place.id));
      const mediaMap = placeIds.length > 0
        ? await mediaDao.getByEntities(placeIds, "tourist_place")
        : {};

      res.json(
        places.map((place) => ({
          ...place,
          category_name: categoryNames.get(place.category_id) ?? null,
          primary_image_url: this.primaryImageUrl(mediaMap[String(place.id)] ?? []),
        }))
      );
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByIds = async (req: Request, res: Response): Promise<void> => {
    try {
      const { ids } = touristPlaceBatchSchema.parse(req.query);

      const service = this.getPublicService();
      const data = await service.getByIds(ids);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByCategory = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = touristPlaceCategorySchema.parse({
        category_id: Number(req.params.categoryId),
      });

      const service = this.getPublicService();
      const data = await service.getByCategory(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = touristPlaceUpdateSchema.parse({
        ...req.body,
        id: Number(req.params.id),
      });

      const service = this.getService(req);
      const result = await service.update(input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  softDelete = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = touristPlaceIdSchema.parse({
        id: Number(req.params.id),
      });

      const service = this.getService(req);
      const result = await service.softDelete(input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  private primaryImageUrl(media: Array<{ is_primary?: boolean; url?: string | null }>): string | null {
    if (media.length === 0) return null;

    const primary = media.find((item) => item.is_primary) ?? media[0];
    return primary?.url ?? null;
  }

  private readBoundedNumber(
    value: unknown,
    fallback: number,
    min: number,
    max: number
  ): number {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) return fallback;
    return Math.min(Math.max(Math.trunc(parsed), min), max);
  }
}

import { Request, Response } from "express";
import { supabasePublic } from "../config/supabase-client.config";
import { BusinessesDAO } from "../dao/businesses.dao";
import { CategoriesDAO } from "../dao/categories.dao";
import { EventsDAO } from "../dao/events.dao";
import { MediaDAO } from "../dao/media.dao";
import { ProductsDAO } from "../dao/products.dao";
import { ReviewsDAO } from "../dao/reviews.dao";
import { TouristPlacesDAO } from "../dao/tourist-places.dao";
import { handleError } from "../utils/handleError";

export class ExploreController {
  getFeed = async (req: Request, res: Response): Promise<void> => {
    try {
      const limit = this.readBoundedNumber(req.query.limit, 20, 1, 100);
      const offset = this.readBoundedNumber(req.query.offset, 0, 0, 100000);
      const query = this.readText(req.query.q, 100);
      const type = this.readType(req.query.type);
      const categoryId = this.readOptionalPositiveInt(req.query.category_id);
      const pageSize = limit + 1;
      const businessFilters = {
        ...(query ? { query } : {}),
        ...(categoryId ? { categoryId } : {}),
        ...(type === "service" ? { businessType: "service" } : {}),
        ...(type === "business" ? { excludeBusinessType: "service" } : {}),
      };
      const commonFilters = {
        ...(query ? { query } : {}),
        ...(categoryId ? { categoryId } : {}),
      };

      const businessesDao = new BusinessesDAO(supabasePublic);
      const categoriesDao = new CategoriesDAO(supabasePublic);
      const eventsDao = new EventsDAO(supabasePublic);
      const touristPlacesDao = new TouristPlacesDAO(supabasePublic);
      const mediaDao = new MediaDAO(supabasePublic);
      const reviewsDao = new ReviewsDAO(supabasePublic);
      const productsDao = new ProductsDAO(supabasePublic);

      const [
        businessPage,
        categories,
        touristPlacePage,
        eventPage,
        businessTotal,
        touristPlaceTotal,
        eventTotal,
      ] =
        await Promise.all([
          this.includesType(type, "business")
            ? businessesDao.findActiveValidated(pageSize, offset, businessFilters)
            : Promise.resolve([]),
          categoriesDao.findAll(),
          this.includesType(type, "tourist_place")
            ? touristPlacesDao.findPublic(pageSize, offset, commonFilters)
            : Promise.resolve([]),
          this.includesType(type, "event")
            ? eventsDao.findAll(pageSize, offset, true, commonFilters)
            : Promise.resolve([]),
          this.includesType(type, "business")
            ? businessesDao.countActiveValidated(businessFilters)
            : Promise.resolve(0),
          this.includesType(type, "tourist_place")
            ? touristPlacesDao.countPublic(commonFilters)
            : Promise.resolve(0),
          this.includesType(type, "event")
            ? eventsDao.countAll(true, commonFilters)
            : Promise.resolve(0),
        ]);

      const hasMore = {
        businesses: businessPage.length > limit,
        tourist_places: touristPlacePage.length > limit,
        events: eventPage.length > limit,
      };
      const businesses = businessPage.slice(0, limit);
      const touristPlaces = touristPlacePage.slice(0, limit);
      const events = eventPage.slice(0, limit);

      const businessIds = businesses.map((business) => business.id);
      const touristPlaceIds = touristPlaces.map((place) => place.id);
      const eventIds = events.map((event) => event.id);

      const [
        businessMedia,
        touristPlaceMedia,
        eventMedia,
        businessReviews,
        businessProducts,
      ] = await Promise.all([
        businessIds.length > 0
          ? mediaDao.getByEntities(businessIds.map(String), "business")
          : Promise.resolve({}),
        touristPlaceIds.length > 0
          ? mediaDao.getByEntities(touristPlaceIds.map(String), "tourist_place")
          : Promise.resolve({}),
        eventIds.length > 0
          ? mediaDao.getByEntities(eventIds.map(String), "event")
          : Promise.resolve({}),
        businessIds.length > 0
          ? reviewsDao.getByEntities("business", businessIds)
          : Promise.resolve({}),
        businessIds.length > 0
          ? productsDao.getByBusinesses(businessIds)
          : Promise.resolve({}),
      ]);

      res.json({
        businesses,
        categories,
        tourist_places: touristPlaces,
        events,
        business_images: this.primaryImageMap(businessMedia),
        tourist_images: this.primaryImageMap(touristPlaceMedia),
        event_images: this.primaryImageMap(eventMedia),
        business_ratings: this.ratingMap(businessReviews),
        business_prices: this.averagePriceMap(businessProducts),
        pagination: {
          limit,
          offset,
          has_more: hasMore,
          has_more_any: Object.values(hasMore).some(Boolean),
          total: {
            businesses: businessTotal,
            tourist_places: touristPlaceTotal,
            events: eventTotal,
            all: businessTotal + touristPlaceTotal + eventTotal,
          },
        },
      });
    } catch (err) {
      return handleError(res, err);
    }
  };

  private readText(value: unknown, maxLength: number): string | undefined {
    if (typeof value !== "string") return undefined;
    const text = value.trim().slice(0, maxLength);
    return text || undefined;
  }

  private readType(value: unknown): string {
    const allowed = new Set(["all", "business", "service", "tourist_place", "event"]);
    return typeof value === "string" && allowed.has(value) ? value : "all";
  }

  private readOptionalPositiveInt(value: unknown): number | undefined {
    if (value === undefined) return undefined;
    const parsed = Number(value);
    return Number.isInteger(parsed) && parsed > 0 ? parsed : undefined;
  }

  private includesType(selected: string, candidate: string): boolean {
    if (selected === "all") return true;
    if (candidate === "business") {
      return selected === "business" || selected === "service";
    }
    return selected === candidate;
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

  private primaryImageMap(mediaMap: Record<string, any[]>): Record<string, string | null> {
    const result: Record<string, string | null> = {};

    for (const [entityId, media] of Object.entries(mediaMap)) {
      if (media.length === 0) {
        result[entityId] = null;
        continue;
      }

      const primary = media.find((item) => item.is_primary) ?? media[0];
      result[entityId] = primary?.url ?? null;
    }

    return result;
  }

  private ratingMap(reviewMap: Record<number, any[]>): Record<string, number> {
    const result: Record<string, number> = {};

    for (const [entityId, reviews] of Object.entries(reviewMap)) {
      if (reviews.length === 0) continue;

      const total = reviews.reduce(
        (sum, review) => sum + Number(review.rating ?? 0),
        0
      );

      result[entityId] = Number((total / reviews.length).toFixed(1));
    }

    return result;
  }

  private averagePriceMap(productsMap: Record<number, any[]>): Record<string, number> {
    const result: Record<string, number> = {};

    for (const [businessId, products] of Object.entries(productsMap)) {
      if (products.length === 0) continue;

      const total = products.reduce(
        (sum, product) => sum + Number(product.price ?? 0),
        0
      );

      result[businessId] = total / products.length;
    }

    return result;
  }
}

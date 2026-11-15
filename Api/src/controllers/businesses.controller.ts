import { Request, Response } from "express";
import { BusinessesService } from "../services/businesses.service";
import { BusinessesDAO } from "../dao/businesses.dao";
import { createBusinessSchema, updateBusinessSchema, businessIdSchema,
  businessCategorySchema, businessModerationSchema,
  businessBatchSchema, businessRejectSchema } from "../validation/businesses.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";
import { assertUser } from "../helper/role.helper";
import { BusinessStatus } from "../constants/enums.constants";
import { NotificationsService } from "../services/notifications.service";
import { NotificationsDAO } from "../dao/notifications.dao";
import { EntityTransportRelationsDAO } from "../dao/entity-transport-relations.dao";
import { EntityTransportRelationsService } from "../services/entity-transport-relations.service";
import { CategoriesDAO } from "../dao/categories.dao";
import { MediaDAO } from "../dao/media.dao";
import { ProductsDAO } from "../dao/products.dao";
import { ReviewsDAO } from "../dao/reviews.dao";
import { DiscountsDAO } from "../dao/discounts.dao";
import { CertificationsDAO } from "../dao/certifications.dao";
import { SocialLinksDAO } from "../dao/social-links.dao";
import { OpeningHoursDAO } from "../dao/opening-hours.dao";
import { BoostsDAO } from "../dao/boosts.dao";
import { TransportLinesDAO } from "../dao/transport-lines.dao";
import { TransportRoutesDAO } from "../dao/transport-routes.dao";
import { isPrivileged } from "../helper/role.helper";

export class BusinessesController {
  private getService(req: Request): BusinessesService {
    const db = getUserClientFromRequest(req);
    const dao = new BusinessesDAO(db);
    const notificationsDao = new NotificationsDAO(supabaseAdmin);
    const notificationsService = new NotificationsService(notificationsDao);
    const transportRelationsDao = new EntityTransportRelationsDAO(supabaseAdmin);
    const transportRelationsService = new EntityTransportRelationsService(transportRelationsDao);

    return new BusinessesService(dao, db, notificationsService, transportRelationsService);
  }

  private getPublicService(): BusinessesService {
    const dao = new BusinessesDAO(supabasePublic);
    const notificationsDao = new NotificationsDAO(supabasePublic);
    const notificationsService = new NotificationsService(notificationsDao);
    const transportRelationsDao = new EntityTransportRelationsDAO(supabasePublic);
    const transportRelationsService = new EntityTransportRelationsService(transportRelationsDao);
    return new BusinessesService(dao, supabasePublic, notificationsService, transportRelationsService);
  }

  // =============================
  // CREATE SYSTEM (admin/master)
  // =============================
  createSystem = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = createBusinessSchema.parse(req.body);

      const service = this.getService(req);
      const business = await service.createSystem(input);

      res.status(201).json(business);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =============================
  // CREATE OWNED (admin/partner)
  // =============================
  createOwned = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = createBusinessSchema.parse(req.body);

      const service = this.getService(req);

      const business = await service.createOwned(input, {
        id: user.id,
        role: user.role,
      });

      res.status(201).json(business);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =============================
  // READ
  // =============================

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getPublicService();
      const data = await service.getAll(isPrivileged(req.user?.role ?? ""));

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = businessIdSchema.parse(req.params);

      const service = this.getPublicService();
      const business = await service.getById(
        input,
        isPrivileged(req.user?.role ?? "")
      );

      res.json(business);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getDetail = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = businessIdSchema.parse(req.params);

      const privileged = isPrivileged(req.user?.role ?? "");
      const businessesDao = new BusinessesDAO(supabasePublic);
      const business = privileged
        ? await businessesDao.findById(input)
        : await businessesDao.findPublicById(input);
      if (!business) throw new Error("Business not found");

      const categoriesDao = new CategoriesDAO(supabasePublic);
      const mediaDao = new MediaDAO(supabasePublic);
      const productsDao = new ProductsDAO(supabasePublic);
      const reviewsDao = new ReviewsDAO(supabasePublic);
      const discountsDao = new DiscountsDAO(supabasePublic);
      const certificationsDao = new CertificationsDAO(supabasePublic);
      const socialLinksDao = new SocialLinksDAO(supabasePublic);
      const openingHoursDao = new OpeningHoursDAO(supabasePublic);
      const boostsDao = new BoostsDAO(supabasePublic);
      const transportRelationsDao = new EntityTransportRelationsDAO(supabasePublic);
      const transportLinesDao = new TransportLinesDAO(supabasePublic);
      const transportRoutesDao = new TransportRoutesDAO(supabasePublic);

      const [
        category,
        media,
        products,
        reviews,
        discounts,
        certifications,
        socialLinks,
        openingHours,
        boosts,
        transportRelations,
      ] = await Promise.all([
        categoriesDao.findById(business.category_id),
        mediaDao.getByEntity(business.id, "business"),
        privileged
          ? productsDao.getByBusinessAdmin(business.id)
          : productsDao.getByBusiness(business.id),
        reviewsDao.getByEntity("business", business.id),
        discountsDao.getActiveByBusinessId(business.id),
        privileged
          ? certificationsDao.findByBusinessIdAdmin(business.id)
          : certificationsDao.findByBusinessId(business.id),
        socialLinksDao.findByBusinessId({ business_id: business.id }),
        openingHoursDao.getByEntity("business", business.id),
        boostsDao.findByEntity("business", business.id),
        transportRelationsDao.getByEntity("business", business.id),
      ]);

      const productIds = products.map((product) => product.id);
      const certificationIds = certifications.map((certification) => certification.id);
      const transportLineIds = transportRelations.map((relation) => relation.transport_line_id);

      const [productMedia, certificationMedia, transportLines, transportRoutes] =
        await Promise.all([
          productIds.length > 0
            ? mediaDao.getByEntities(productIds.map(String), "product")
            : Promise.resolve({}),
          certificationIds.length > 0
            ? mediaDao.getByEntities(certificationIds.map(String), "certification")
            : Promise.resolve({}),
          transportLineIds.length > 0
            ? transportLinesDao.findByIds(transportLineIds)
            : Promise.resolve([]),
          transportLineIds.length > 0
            ? transportRoutesDao.findByLines(transportLineIds)
            : Promise.resolve({}),
        ]);

      const rating = reviews.length > 0
        ? Number(
            (
              reviews.reduce((sum, review) => sum + Number(review.rating ?? 0), 0) /
              reviews.length
            ).toFixed(1)
          )
        : null;

      res.json({
        business,
        category,
        media,
        products,
        product_media: productMedia,
        reviews,
        rating,
        discounts,
        certifications,
        certification_media: certificationMedia,
        social_links: socialLinks,
        opening_hours: openingHours,
        boosts,
        transport_relations: transportRelations,
        transport_lines: transportLines,
        transport_routes: transportRoutes,
      });
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByIds = async (req: Request, res: Response): Promise<void> => {
    try {
      const { ids } = businessBatchSchema.parse(req.query);

      const service = this.getPublicService();
      const data = await service.getByIds(
        ids,
        isPrivileged(req.user?.role ?? "")
      );

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const service = this.getService(req);
      const data = await service.getByOwner(user.id);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getClaimable = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const service = this.getService(req);
      const data = await service.getClaimable();

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByCategory = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = businessCategorySchema.parse({
        category_id: Number(req.params.categoryId),
      });

      const service = this.getPublicService();
      const data = await service.getByCategory(
        input,
        isPrivileged(req.user?.role ?? "")
      );

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =============================
  // UPDATE
  // =============================
  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const data = updateBusinessSchema.parse(req.body);
      const { id } = businessIdSchema.parse(req.params);

      const service = this.getService(req);

      const updated = await service.update(
        { ...data, id },
        {
          id: user.id,
          role: user.role,
        }
      );

      res.json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =============================
  // DELETE
  // =============================
  softDelete = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = businessIdSchema.parse(req.params);

      const service = this.getService(req);
      const updated = await service.softDelete(input, user.id);

      res.status(200).json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };

  validate = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = businessIdSchema.parse(req.params);
      const { message } = businessRejectSchema.parse(req.body);

      const service = this.getService(req);
      const business = await service.validate(
        input,
        {
          id: user.id,
          role: user.role,
        },
        message
      );

      res.json(business);
    } catch (err) {
      return handleError(res, err);
    }
  };

  reject = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = businessIdSchema.parse(req.params);
      const { message } = businessModerationSchema.parse(req.body);

      const service = this.getService(req);
      const business = await service.reject(
        input,
        {
          id: user.id,
          role: user.role,
        },
        message
      );

      res.json(business);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByStatus = async (req: Request, res: Response): Promise<void> => {
    try {
      const status = req.query.status as BusinessStatus;

      if (!status) {
        throw new Error("Status query param is required");
      }

      const service = this.getService(req);
      const data = await service.getByStatus(status);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };
}

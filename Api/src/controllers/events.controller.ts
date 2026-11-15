import { Request, Response } from "express";
import { EventsService } from "../services/events.service";
import { EventsDAO } from "../dao/events.dao";
import { eventCreateSchema, eventUpdateSchema, eventIdSchema,
  eventBatchSchema, getByStatusQuerySchema, eventModerationSchema, eventRejectSchema,
  eventPageQuerySchema } from "../validation/events.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabasePublic, supabaseAdmin } from "../config/supabase-client.config";
import { assertUser } from "../helper/role.helper";
import { NotificationsService } from "../services/notifications.service";
import { NotificationsDAO } from "../dao/notifications.dao";
import { EntityTransportRelationsDAO } from "../dao/entity-transport-relations.dao";
import { EntityTransportRelationsService } from "../services/entity-transport-relations.service";
import { AuditLogsDAO } from "../dao/audit-logs.dao";
import { BusinessesDAO } from "../dao/businesses.dao";
import { CategoriesDAO } from "../dao/categories.dao";
import { MediaDAO } from "../dao/media.dao";
import { ReviewsDAO } from "../dao/reviews.dao";
import { UsersDAO } from "../dao/users.dao";
import { TransportLinesDAO } from "../dao/transport-lines.dao";
import { TransportRoutesDAO } from "../dao/transport-routes.dao";
import { isPrivileged } from "../helper/role.helper";

export class EventsController {
  private getService(req: Request): EventsService {
    const db = getUserClientFromRequest(req);
    const eventsDao = new EventsDAO(db);
    const notificationsDao = new NotificationsDAO(supabaseAdmin);
    const notificationsService = new NotificationsService(notificationsDao);
    const transportRelationsDao = new EntityTransportRelationsDAO(supabaseAdmin);
    const transportRelationsService = new EntityTransportRelationsService(transportRelationsDao);
    const auditDao = new AuditLogsDAO(supabaseAdmin);

    return new EventsService(eventsDao, db, notificationsService, transportRelationsService, auditDao);
  }

  private getPublicService(): EventsService {
    const dao = new EventsDAO(supabasePublic);
    const notificationsDao = new NotificationsDAO(supabaseAdmin);
    const notificationsService = new NotificationsService(notificationsDao);
    const transportRelationsDao = new EntityTransportRelationsDAO(supabasePublic);
    const transportRelationsService = new EntityTransportRelationsService(transportRelationsDao);

    return new EventsService(dao, supabasePublic, notificationsService, transportRelationsService);
  }

  private getPublicAvailabilityService(): EventsService {
    const dao = new EventsDAO(supabasePublic);
    const notificationsDao = new NotificationsDAO(supabaseAdmin);
    const notificationsService = new NotificationsService(notificationsDao);
    const transportRelationsDao = new EntityTransportRelationsDAO(supabaseAdmin);
    const transportRelationsService = new EntityTransportRelationsService(transportRelationsDao);

    return new EventsService(dao, supabaseAdmin, notificationsService, transportRelationsService);
  }

  // =========================
  // CREATE
  // =========================
  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = eventCreateSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(input, {
        id: user.id,
        role: user.role,
      });

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // APPROVE
  // =========================
  approve = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = eventIdSchema.parse(req.params);
      const { message } = eventModerationSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.approve(input, {
        id: user.id,
        role: user.role,
      }, message);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // REJECT
  // =========================
  reject = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = eventIdSchema.parse(req.params);
      const { message } = eventRejectSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.reject(input, {
        id: user.id,
        role: user.role,
      }, message);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByStatus = async (req: Request, res: Response): Promise<void> => {
    try {
      const { status } = getByStatusQuerySchema.parse(req.query);
      const service = this.getService(req);
      const result = await service.getByStatus(status);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
};

  // =========================
  // GETTERS
  // =========================
  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const result = await service.getAll(privileged);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = eventIdSchema.parse(req.params);

      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const result = await service.getById(input, privileged);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getPage = async (req: Request, res: Response): Promise<void> => {
    try {
      const { limit, offset } = eventPageQuerySchema.parse(req.query);
      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      res.json(await service.getPage(limit, offset, privileged));
    } catch (err) {
      return handleError(res, err);
    }
  };

  getDetail = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = eventIdSchema.parse(req.params);

      const privileged = isPrivileged(req.user?.role ?? "");
      const eventsDao = new EventsDAO(supabasePublic);
      const event = privileged
        ? await eventsDao.findById(input)
        : await eventsDao.findPublicById(input);
      if (!event) throw new Error("Event not found");

      const businessesDao = new BusinessesDAO(supabasePublic);
      const categoriesDao = new CategoriesDAO(supabasePublic);
      const mediaDao = new MediaDAO(supabasePublic);
      const reviewsDao = new ReviewsDAO(supabasePublic);
      const usersDao = new UsersDAO(supabasePublic);
      const transportRelationsDao = new EntityTransportRelationsDAO(supabasePublic);
      const transportLinesDao = new TransportLinesDAO(supabasePublic);
      const transportRoutesDao = new TransportRoutesDAO(supabasePublic);
      const availabilityService = this.getPublicAvailabilityService();

      const [
        category,
        media,
        reviews,
        organizerList,
        availability,
        business,
        transportRelations,
      ] = await Promise.all([
        categoriesDao.findById(event.category_id),
        mediaDao.getByEntity(event.id, "event"),
        reviewsDao.getByEntity("event", event.id),
        usersDao.findPublicProfilesByIds([event.creator_id]),
        availabilityService.getAvailability(input),
        event.business_id
          ? privileged
            ? businessesDao.findById({ id: event.business_id })
            : businessesDao.findPublicById({ id: event.business_id })
          : Promise.resolve(null),
        transportRelationsDao.getByEntity("event", event.id),
      ]);

      const transportLineIds = transportRelations.map((relation) => relation.transport_line_id);

      const [transportLines, transportRoutes] = await Promise.all([
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
        event,
        category,
        business,
        organizer: organizerList[0] ?? null,
        media,
        reviews,
        rating,
        availability,
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
      const { ids } = eventBatchSchema.parse(req.query);

      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const result = await service.getByIds(ids, privileged);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByCategory = async (req: Request, res: Response): Promise<void> => {
    try {
      const categoryId = Number(req.params.categoryId);

      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const result = await service.getByCategory(categoryId, privileged);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByBusiness = async (req: Request, res: Response): Promise<void> => {
    try {
      const businessId = Number(req.params.businessId);

      const privileged = isPrivileged(req.user?.role ?? "");
      const service = privileged ? this.getService(req) : this.getPublicService();
      const result = await service.getByBusiness(businessId, privileged);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const service = this.getService(req);
      const result = await service.getByCreator(userId);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // UPDATE
  // =========================
  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const data = eventUpdateSchema.parse(req.body);
      const { id } = eventIdSchema.parse(req.params);

      const service = this.getService(req);
      const result = await service.update(
        { ...data, id },
        userId
      );

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // DELETE
  // =========================
  softDelete = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;

      if (!userId) {
        throw new Error("Unauthorized");
      }

      const input = eventIdSchema.parse(req.params);
      const service = this.getService(req);
      const updated = await service.softDelete(input, userId);

      res.status(200).json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new Error("Unauthorized");

      const input = eventIdSchema.parse(req.params);

      const service = this.getService(req);
      await service.delete(input, userId);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // AVAILABILITY
  // =========================
  getAvailability = async (
    req: Request,
    res: Response
  ): Promise<void> => {
    try {
      const input = eventIdSchema.parse(req.params);

      const privileged = isPrivileged(req.user?.role ?? "");
      const service = this.getPublicAvailabilityService();
      const result = await service.getAvailability(input, privileged);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };
}

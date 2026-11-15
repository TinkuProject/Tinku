import { Request, Response } from "express";
import { EntityUpdatesService } from "../services/entity-updates.service";
import { EntityUpdatesDAO } from "../dao/entity-updates.dao";
import { OwnershipService } from "../services/ownership.service";
import { SocialLinksService } from "../services/social-links.service";
import { OpeningHoursService } from "../services/opening-hours.service";
import { EntityTransportRelationsService } from "../services/entity-transport-relations.service";

import { SocialLinksDAO } from "../dao/social-links.dao";
import { OpeningHoursDAO } from "../dao/opening-hours.dao";
import { EntityTransportRelationsDAO } from "../dao/entity-transport-relations.dao";

import { createEntityUpdateSchema, reviewEntityUpdateSchema,
} from "../validation/entity-updates.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest,} from "../config/supabase-client.config";
import { assertUser } from "../helper/role.helper";

export class EntityUpdatesController {
  private getService(req: Request): EntityUpdatesService {
    const db = getUserClientFromRequest(req);

    const dao = new EntityUpdatesDAO(db);
    const socialLinksDao = new SocialLinksDAO(db);
    const openingHoursDao = new OpeningHoursDAO(db);
    const transportRelationsDao = new EntityTransportRelationsDAO(db);

    const ownershipService = new OwnershipService(db);
    const socialLinksService = new SocialLinksService(socialLinksDao);
    const openingHoursService = new OpeningHoursService(openingHoursDao);
    const transportRelationsService = new EntityTransportRelationsService(transportRelationsDao);

    return new EntityUpdatesService(
      dao,
      ownershipService,
      db,
      socialLinksService,
      openingHoursService,
      transportRelationsService
    );
  }

  // =========================
  // CREATE
  // =========================
  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const input = createEntityUpdateSchema.parse(req.body);

      const service = this.getService(req);
      const result = await service.create(input, user);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // GET ALL (ADMIN)
  // =========================
  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const service = this.getService(req);
      const result = await service.getAll();

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // GET BY ID
  // =========================
  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const id = Number(req.params.id);

      const service = this.getService(req);
      const result = await service.getById(id);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // GET BY ENTITY
  // =========================
  getByEntity = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const entityType = req.query.entity_type as any;
      const entityId = Number(req.query.entity_id);

      const service = this.getService(req);
      const result = await service.getByEntity(entityType, entityId, user);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  // =========================
  // GET MINE
  // =========================
  getMine = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = req.user;
      assertUser(user);

      const service = this.getService(req);
      const result = await service.getByCreator(user.id);

      res.json(result);
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

      const input = reviewEntityUpdateSchema.parse({
        update_id: Number(req.params.id),
        ...req.body,
      });

      const service = this.getService(req);
      await service.approve(input, user);

      res.json({ message: "Update approved" });
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

      const input = reviewEntityUpdateSchema.parse({
        update_id: Number(req.params.id),
        ...req.body,
      });

      const service = this.getService(req);
      await service.reject(input, user);

      res.json({ message: "Update rejected" });
    } catch (err) {
      return handleError(res, err);
    }
  };
}

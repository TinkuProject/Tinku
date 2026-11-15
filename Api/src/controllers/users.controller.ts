import { Request, Response } from "express";
import { UsersService } from "../services/users.service";
import { UsersDAO } from "../dao/users.dao";
import { userUpdateSchema, userSelfUpdateSchema, userIdSchema, userBatchSchema } from "../validation/users.validation";
import { adminCreateUserSchema } from "../validation/auth.validation";
import { AuthService } from "../services/auth.service";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin } from "../config/supabase-client.config";
import { MediaService } from "../services/media.service";
import { MediaDAO } from "../dao/media.dao";

export class UsersController {
  private getService(req: Request): UsersService {
    const db = getUserClientFromRequest(req);

    const usersDAO = new UsersDAO(db);
    const mediaDAO = new MediaDAO(db);
    const mediaService = new MediaService(mediaDAO);

    return new UsersService(usersDAO, mediaService);
  }

  private getPublicProfileService(): UsersService {
    const usersDAO = new UsersDAO(supabaseAdmin);
    const mediaDAO = new MediaDAO(supabaseAdmin);
    const mediaService = new MediaService(mediaDAO);

    return new UsersService(usersDAO, mediaService);
  }

  getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const service = this.getService(req);
      const users = await service.getAll();

      res.json(users);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getProfilePicture = async (req: Request, res: Response): Promise<void> => {
    try {
      if (!req.user) {
        res.status(401).json({ error: "Unauthorized" });
        return;
      }

      const service = this.getService(req);
      const url = await service.getProfilePicture(req.user.id);

      res.json({ url });

    } catch (err) {
      return handleError(res, err);
    }
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = userIdSchema.parse({
        id: req.params.id,
      });

      const service = this.getService(req);
      const user = await service.getById(input);

      res.json(user);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByIds = async (req: Request, res: Response): Promise<void> => {
    try {
      const { ids } = userBatchSchema.parse({
        ids: req.query.ids,
      });

      const service = this.getPublicProfileService();
      const users = await service.getPublicProfilesByIds(ids);

      res.json(users);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = userUpdateSchema.parse({
        ...req.body,
        id: req.params.id,
      });

      const service = this.getService(req);
      const updated = await service.update(input);

      res.json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = adminCreateUserSchema.parse(req.body);
      const created = await AuthService.createUserByAdmin(input);

      res.status(201).json(created);
    } catch (err) {
      return handleError(res, err);
    }
  };

  updateMe = async (req: Request, res: Response): Promise<void> => {
    try {
      if (!req.user) {
        res.status(401).json({ error: "Unauthorized" });
        return;
      }

      const selfUpdates = userSelfUpdateSchema.parse(req.body);
      const input = userUpdateSchema.parse({
        ...selfUpdates,
        id: req.user.id,
      });

      const service = this.getService(req);
      const updated = await service.update(input);

      res.json(updated);
    } catch (err) {
      return handleError(res, err);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = userIdSchema.parse({
        id: req.params.id,
      });

      const service = this.getService(req);
      await service.delete(input);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };

  updateProfilePicture = async (req: Request, res: Response): Promise<void> => {
    try {
      if (!req.user) {
        res.status(401).json({ error: "Unauthorized" });
        return;
      }

      const userId = req.user.id;
      const file = req.file as Express.Multer.File;

      if (!file) {
        res.status(400).json({ error: "No file uploaded" });
        return;
      }

      const service = this.getService(req);

      const url = await service.updateProfilePicture(userId, {
        buffer: file.buffer,
        originalName: file.originalname,
        mimeType: file.mimetype,
      });

      res.json({ url });

    } catch (err) {
      return handleError(res, err);
    }
  };
}

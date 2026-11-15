import { Request, Response } from "express";
import { v4 as uuidv4 } from "uuid";
import { uploadSchema, deleteMediaSchema, deleteEntityMediaSchema } from "../validation/storage.validation";
import { processFile } from "../utils/fileProcessor";
import { StorageService } from "../services/storage.service";
import { OwnershipService } from "../services/ownership.service";
import { MediaService } from "../services/media.service";
import { MediaDAO } from "../dao/media.dao";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest } from "../config/supabase-client.config";

const MAX_UPLOAD_TOTAL_SIZE = 60 * 1024 * 1024;
const MAX_PAYMENT_PROOF_FILES = 1;
const MAX_PROFILE_FILES = 1;

export class StorageController {
  private static getServices(req: Request) {
    const db = getUserClientFromRequest(req);

    return {
      mediaService: new MediaService(new MediaDAO(db)),
      ownershipService: new OwnershipService(db),
    };
  }

  static async upload(req: Request, res: Response) {
    const uploadedPaths: string[] = [];

    try {
      if (!req.user) {
        return res.status(401).json({ error: "Unauthorized" });
      }

      const userId = req.user.id;
      const { entityType, entityId, uploadMode } = uploadSchema.parse(req.body);
      const persistMedia = uploadMode === "direct";

      const files = req.files as Express.Multer.File[];

      if (!files || files.length === 0) {
        return res.status(400).json({ error: "No files uploaded" });
      }

      const totalSize = files.reduce((total, file) => total + file.size, 0);
      if (totalSize > MAX_UPLOAD_TOTAL_SIZE) {
        return res.status(413).json({ error: "Upload total size is too large" });
      }

      const maxFiles =
        entityType === "payment" || entityType === "user"
          ? MAX_PAYMENT_PROOF_FILES
          : 6;

      if (entityType === "user" && files.length > MAX_PROFILE_FILES) {
        return res.status(400).json({ error: "Only one profile file is allowed" });
      }

      if (files.length > maxFiles) {
        return res.status(400).json({ error: "Too many files for this entity" });
      }

      const { mediaService, ownershipService } = StorageController.getServices(req);

      await ownershipService.validate(entityType, entityId, req.user);

      const urls: string[] = [];
      const filesMeta: Array<{
        url: string;
        type: string;
        is_primary: boolean;
      }> = [];

      for (const file of files) {
        const processed = await processFile(file);

        const fileName = `${uuidv4()}.${processed.extension}`;

        const filePath = StorageService.generateFilePath(
          entityType,
          entityId,
          fileName
        );

        const url = await StorageService.uploadFile({
          filePath,
          buffer: processed.buffer,
          contentType: processed.contentType,
        });

        uploadedPaths.push(filePath);

        const isPrimary = urls.length === 0;

        filesMeta.push({
          url,
          type: processed.type,
          is_primary: isPrimary,
        });

        if (persistMedia) {
          if (entityType === "user") {
            await mediaService.create({
              entity_id: entityId as string,
              entity_type: "user",
              url,
              type: processed.type,
              is_primary: isPrimary,
            });
          } else {
            await mediaService.create({
              entity_id: entityId as number,
              entity_type: entityType,
              url,
              type: processed.type,
              is_primary: isPrimary,
            });
          }
        }

        urls.push(url);
      }

      return res.status(201).json({
        urls,
        files: filesMeta,
        upload_mode: uploadMode,
      });
    } catch (err) {
      if (uploadedPaths.length > 0) {
        await Promise.all(
          uploadedPaths.map((path) => StorageService.deleteFile(path))
        );
      }

      return handleError(res, err, req);
    }
  }

  static async deleteByEntity(req: Request, res: Response) {
    try {
      if (!req.user) {
        return res.status(401).json({ error: "Unauthorized" });
      }

      const userId = req.user.id;
      const { entityType, entityId } = deleteEntityMediaSchema.parse(req.body);
      const { mediaService, ownershipService } = StorageController.getServices(req);

      await ownershipService.validate(entityType, entityId, req.user);
      const mediaList = await mediaService.getByEntity(entityId, entityType);

      if (mediaList.length === 0) {
        return res.status(200).json({
          message: "No media found",
          deleted: 0,
        });
      }

      const paths = mediaList.map((media) =>
        StorageService.extractFilePath(media.url)
      );

      await Promise.all(paths.map((path) => StorageService.deleteFile(path)));
      await mediaService.deleteAllByEntity(entityId, entityType);

      return res.status(200).json({
        message: "Deleted successfully",
        deleted: mediaList.length,
      });
    } catch (err) {
      return handleError(res, err, req);
    }
  }

  static async delete(req: Request, res: Response) {
    try {
      if (!req.user) {
        return res.status(401).json({ error: "Unauthorized" });
      }

      const userId = req.user.id;
      const { mediaId } = deleteMediaSchema.parse(req.body);
      const { mediaService, ownershipService } = StorageController.getServices(req);
      const media = await mediaService.getById(mediaId);

      if (!media) {
        return res.status(404).json({ error: "Media not found" });
      }

      const entityId =
        media.entity_type === "user" ? media.entity_id : Number(media.entity_id);

      await ownershipService.validate(media.entity_type, entityId, req.user);

      await mediaService.delete(mediaId);

      return res.status(200).json({
        message: "Deleted successfully",
      });
    } catch (err) {
      return handleError(res, err, req);
    }
  }
}

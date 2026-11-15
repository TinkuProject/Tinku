import express from "express";
import multer from "multer";
import { StorageController } from "../controllers/storage.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { MEDIA_RULES } from "../config/media.config";

const router = express.Router();

// =========================
// MULTER CONFIG (MEMORY)
// =========================
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    // El control fino por MIME queda en processFile; acá evitamos cargas enormes en memoria.
    fileSize: MEDIA_RULES.video.maxSize,
    files: 6,
  },
});

// POST /storage/upload
//
// Headers:
// Authorization: Bearer <access_token>
//
// Body: form-data
// - entityType: string (ej: "business", "event")
// - entityId: number
// - files: file[]
//
// Ejemplo:
// entityType: business
// entityId: 12
// files: [file1, file2]
//

router.use(authMiddleware);

router.post("/upload",
  upload.array("files", 10),
  (req, res, next) => {
    if (!req.files || (req.files as Express.Multer.File[]).length === 0) {
      return res.status(400).json({ error: "No files uploaded" });
    }
    next();
  },
  StorageController.upload
);

// DELETE /storage/delete
//
// Headers:
// Authorization: Bearer <access_token>
//
// Body (JSON):
// {
//   "mediaId": 123
// }
//
router.delete("/delete", StorageController.delete);

router.delete("/entity", StorageController.deleteByEntity);

export default router;

import sharp from "sharp";
import { MEDIA_RULES } from "../config/media.config";
import { MediaType } from "../constants/enums.constants";
import { ProcessedFile } from "../types/media.type";

export const processFile = async (
  file: Express.Multer.File
): Promise<ProcessedFile> => {
  if (!file || !file.buffer) {
    throw new Error("Invalid file");
  }

  const { fileTypeFromBuffer } = await import("file-type");

  const detected = await fileTypeFromBuffer(file.buffer);

  if (!detected) {
    throw new Error("Cannot detect file type");
  }

  const mime = detected.mime;

  const entry = Object.entries(MEDIA_RULES).find(([_, rule]) =>
    rule.mimeTypes.includes(mime)
  );

  if (!entry) {
    throw new Error(`Unsupported file type: ${mime}`);
  }

  const [mediaType, rule] = entry as [
    MediaType,
    (typeof MEDIA_RULES)[MediaType]
  ];

  if (file.size > rule.maxSize) {
    throw new Error(`File too large for type ${mediaType}`);
  }

  // =========================
  // IMAGE
  // =========================
  if (mediaType === "image" && rule.process) {
    const metadata = await sharp(file.buffer).metadata();

    if (
      (metadata.width && metadata.width > 8000) ||
      (metadata.height && metadata.height > 8000)
    ) {
      throw new Error("Image dimensions too large");
    }

    const buffer = await sharp(file.buffer)
      .resize({
        width: 1600,
        withoutEnlargement: true,
      })
      .webp({ quality: 80 })
      .toBuffer();

    return {
      buffer,
      extension: "webp",
      contentType: "image/webp",
      type: "image",
    };
  }

  // =========================
  // VIDEO / FILE
  // =========================
  return {
    buffer: file.buffer,
    extension: detected.ext,
    contentType: mime,
    type: mediaType,
  };
};
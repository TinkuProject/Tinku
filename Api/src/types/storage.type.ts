import { MediaEntityType, MediaType } from "../constants/enums.constants";

// =========================
// FILE UPLOAD
// =========================
export type UploadFileParams = {
  filePath: string;
  buffer: Buffer;
  contentType: string;
  isPublic?: boolean;
};

// =========================
// MEDIA CREATION
// =========================
export type CreateMediaParams = {
  entityType: MediaEntityType;
  entityId: number;
  url: string;
  type: MediaType;
};

// =========================
// REPLACE FILE
// =========================
export type ReplaceFileParams = {
  oldUrl: string;
  newFile: UploadFileParams;
};
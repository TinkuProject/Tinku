import { MediaType } from "../constants/enums.constants";

export const MEDIA_RULES: Record<
  MediaType,
  {
    mimeTypes: string[];
    maxSize: number;
    process: boolean;
  }
> = {
  image: {
    mimeTypes: ["image/jpeg", "image/png", "image/webp"],
    maxSize: 5 * 1024 * 1024, // 5MB
    process: true,
  },
  video: {
    mimeTypes: ["video/mp4"],
    maxSize: 50 * 1024 * 1024, // 50MB
    process: false,
  },
  file: {
    mimeTypes: ["application/pdf"],
    maxSize: 10 * 1024 * 1024, // 10MB
    process: false,
  },
};
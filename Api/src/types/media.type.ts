import { MediaType } from "../constants/enums.constants";

export type ProcessedFile = {
  buffer: Buffer;
  extension: string;
  contentType: string;
  type: MediaType;
};
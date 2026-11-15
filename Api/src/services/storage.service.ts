import { firebaseBucket } from "../config/firebase-client.config";
import { MediaEntityType } from "../constants/enums.constants";
import { UploadFileParams, ReplaceFileParams } from "../types/storage.type";
import { randomUUID } from "crypto";

export class StorageService {

  static async uploadFile({
    filePath,
    buffer,
    contentType,
    isPublic = true,
  }: UploadFileParams): Promise<string> {
    const file = firebaseBucket.file(filePath);

    await file.save(buffer, {
      contentType,
      public: isPublic,
    });

    return this.buildPublicUrl(filePath);
  }


  static buildPublicUrl(filePath: string): string {
    return `https://storage.googleapis.com/${firebaseBucket.name}/${filePath}`;
  }


  static async deleteFile(filePath: string): Promise<void> {
    const file = firebaseBucket.file(filePath);

    try {
      await file.delete();
    } catch (err) {
      throw new Error(`Error deleting file: ${err}`);
    }
  }


  static extractFilePath(url: string): string {
    try {
      const urlObj = new URL(url);
      const bucketName = firebaseBucket.name;
      const prefix = `/${bucketName}/`;
      if (urlObj.protocol !== "https:" || urlObj.hostname !== "storage.googleapis.com" ||
          !urlObj.pathname.startsWith(prefix)) throw new Error("Invalid storage URL");
      const path = decodeURIComponent(urlObj.pathname.slice(prefix.length));
      if (!path || path.split("/").some(part => part === "." || part === ".." || !part)) {
        throw new Error("Invalid storage URL");
      }
      return path;
    } catch {
      throw new Error("Invalid storage URL");
    }
  }

  static assertEntityFile(url: string, entityType: string, entityId: string | number): string {
    const path = this.extractFilePath(url);
    if (!path.startsWith(`${entityType}/${entityId}/`)) throw new Error("Forbidden");
    return path;
  }

  static async signedReadUrl(url: string): Promise<string> {
    const [signed] = await firebaseBucket.file(this.extractFilePath(url)).getSignedUrl({
      action: "read", expires: Date.now() + 15 * 60 * 1000,
    });
    return signed;
  }


  static generateFilePath(
    entityType: MediaEntityType,
    entityId: string | number,
    fileName: string
  ): string {
    const uniqueName = `${randomUUID()}-${fileName}`;
    return `${entityType}/${entityId}/${uniqueName}`;
  }


  static async replaceFile({
    oldUrl,
    newFile,
  }: ReplaceFileParams): Promise<string> {
    const oldPath = this.extractFilePath(oldUrl);

    const newUrl = await this.uploadFile(newFile);
    await this.deleteFile(oldPath);

    return newUrl;
  }
}

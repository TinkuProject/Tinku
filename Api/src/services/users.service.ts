import { UsersDAO } from "../dao/users.dao";
import { MediaService } from "./media.service";
import { StorageService } from "./storage.service";
import { UserUpdateInput, UserIdInput } from "../validation/users.validation";
import { User } from "../dto/user.dto";

export class UsersService {
  constructor(
    private readonly dao: UsersDAO,
    private readonly mediaService: MediaService
  ) { }

  async getAll(): Promise<User[]> {
    return this.dao.findAll();
  }

  async getProfilePicture(userId: string): Promise<string | null> {
    const media = await this.mediaService.getPrimaryByEntity(userId, "user");
    return media?.url ?? null;
  }

  async getById(input: UserIdInput): Promise<User> {
    const user = await this.dao.findById(input);

    if (!user) {
      throw new Error("User not found");
    }

    return user;
  }

  async getPublicProfilesByIds(ids: string[]): Promise<User[]> {
    return this.dao.findPublicProfilesByIds(ids);
  }

  async update(input: UserUpdateInput): Promise<User> {
    const exists = await this.dao.findById({ id: input.id });

    if (!exists) {
      throw new Error("User not found");
    }

    if (input.email !== undefined && input.email.toLowerCase() !== exists.email.toLowerCase()) {
      throw new Error("Email changes require verification");
    }
    return this.dao.update(input);
  }

  async delete(input: UserIdInput): Promise<void> {
    const exists = await this.dao.findById(input);

    if (!exists) {
      throw new Error("User not found");
    }

    await this.dao.delete(input);
  }

  async updateProfilePicture(
    userId: string,
    file: {
      buffer: Buffer;
      originalName: string;
      mimeType: string;
    }
  ): Promise<string> {

    // validar usuario
    const exists = await this.dao.findById({ id: userId });
    if (!exists) {
      throw new Error("User not found");
    }

    // 1. eliminar foto anterior (si existe)
    const current = await this.mediaService.getPrimaryByEntity(userId, "user");

    if (current) {
      // eliminar archivo físico
      await StorageService.deleteFile(
        StorageService.extractFilePath(current.url)
      );

      // eliminar registro en DB
      await this.mediaService.delete(current.id);
    }

    // 2. generar path
    const filePath = StorageService.generateFilePath(
      "user",
      userId,
      file.originalName
    );

    // 3. subir archivo
    const url = await StorageService.uploadFile({
      filePath,
      buffer: file.buffer,
      contentType: file.mimeType,
    });

    // 4. registrar media nueva
    await this.mediaService.create({
      entity_id: userId,
      entity_type: "user",
      url,
      type: "image",
      is_primary: true,
    });

    return url;
  }
}

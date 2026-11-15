import { PermissionsDAO } from "../dao/permissions.dao";
import { PermissionCreateInput, PermissionUpdateInput,
} from "../validation/permissions.validation";
import { Permission } from "../dto/permission.dto";

export class PermissionsService {
  constructor(private dao: PermissionsDAO) { }

  create(data: PermissionCreateInput): Promise<Permission> {
    return this.dao.create(data);
  }

  getAll(): Promise<Permission[]> {
    return this.dao.getAll();
  }

  async getById(id: number): Promise<Permission> {
    const permission = await this.dao.getById(id);

    if (!permission) {
      throw new Error("Permission not found");
    }

    return permission;
  }

  async getByCode(code: string): Promise<Permission> {
    const permission = await this.dao.getByCode(code);

    if (!permission) {
      throw new Error("Permission not found");
    }

    return permission;
  }

  getByCodes(codes: string[]): Promise<Permission[]> {
    return this.dao.getByCodes(codes);
  }

  async update(
    id: number,
    data: PermissionUpdateInput
  ): Promise<Permission> {
    const existing = await this.dao.getById(id);

    if (!existing) {
      throw new Error("Permission not found");
    }

    return this.dao.update(id, data);
  }

  delete(id: number): Promise<void> {
    return this.dao.delete(id);
  }
}

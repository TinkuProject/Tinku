import { RolePermissionsDAO } from "../dao/role-permissions.dao";
import { AssignPermissionInput, RolePermissionFilter, RemovePermissionInput,
} from "../validation/role-permissions.validation";
import { RolePermission } from "../dto/role-permission.dto";

export class RolePermissionsService {
  constructor(private readonly dao: RolePermissionsDAO) {}

  async assign(input: AssignPermissionInput): Promise<void> {
    const exists = await this.dao.exists(input);

    if (exists) {
      throw new Error("Permission already assigned to role");
    }

    await this.dao.assign(input);
  }

  async getByRole(filter: RolePermissionFilter): Promise<RolePermission[]> {
    return this.dao.findByRole(filter);
  }

  async remove(input: RemovePermissionInput): Promise<void> {
    const exists = await this.dao.exists(input);

    if (!exists) {
      throw new Error("Permission not found for role");
    }

    await this.dao.remove(input);
  }

  // útil para checks rápidos tipo auth
  async getPermissionIdsByRole(role: RolePermissionFilter): Promise<number[]> {
    return this.dao.findPermissionsByRole(role.role);
  }
}
import { DbClient } from "../types/db-client";
import { RolePermission } from "../dto/role-permission.dto";
import { AssignPermissionInput, RolePermissionFilter, RemovePermissionInput,
} from "../validation/role-permissions.validation";

export class RolePermissionsDAO {
  private table = "role_permissions";
  constructor(private readonly db: DbClient) {}

  async assign(input: AssignPermissionInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .insert(input);

    if (error) throw error;
  }

  async findByRole(filter: RolePermissionFilter): Promise<RolePermission[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("role", filter.role);

    if (error) throw error;

    return (data ?? []) as RolePermission[];
  }

  async remove(input: RemovePermissionInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .match({
        role: input.role,
        permission_id: input.permission_id,
      });

    if (error) throw error;
  }

  async exists(input: RemovePermissionInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("permission_id")
      .match({
        role: input.role,
        permission_id: input.permission_id,
      })
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }

  async findPermissionsByRole(role: string): Promise<number[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("permission_id")
      .eq("role", role);

    if (error) throw error;

    return (data ?? []).map((item) => item.permission_id);
  }
}
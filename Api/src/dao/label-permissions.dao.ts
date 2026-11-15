import { DbClient } from "../types/db-client";
import { LabelPermission } from "../dto/label-permission.dto";
import { AssignLabelPermissionInput } from "../validation/label-permissions.validation";

export class LabelPermissionsDAO {
  private table = "label_permissions";
  constructor(private db: DbClient) {}

  async assign(data: AssignLabelPermissionInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .insert(data);

    if (error) throw error;
  }

  async getByLabel(labelId: number): Promise<LabelPermission[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("label_id", labelId);

    if (error) throw error;
    return data as LabelPermission[];
  }

  async remove(
    labelId: number,
    permissionId: number
  ): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("label_id", labelId)
      .eq("permission_id", permissionId);

    if (error) throw error;
  }

  async removeAllByLabel(labelId: number): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("label_id", labelId);

    if (error) throw error;
  }
}
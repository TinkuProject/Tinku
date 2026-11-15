import { LabelPermissionsDAO } from "../dao/label-permissions.dao";
import { LabelPermission } from "../dto/label-permission.dto";
import { AssignLabelPermissionInput } from "../validation/label-permissions.validation";

export class LabelPermissionsService {
  constructor(private dao: LabelPermissionsDAO) {}

  assign(data: AssignLabelPermissionInput): Promise<void> {
    return this.dao.assign(data);
  }

  getByLabel(labelId: number): Promise<LabelPermission[]> {
    return this.dao.getByLabel(labelId);
  }

  remove(labelId: number, permissionId: number): Promise<void> {
    return this.dao.remove(labelId, permissionId);
  }

  removeAllByLabel(labelId: number): Promise<void> {
    return this.dao.removeAllByLabel(labelId);
  }
}
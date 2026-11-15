import { UserRole } from "../constants/enums.constants";

export interface RolePermission {
  role: UserRole;
  permission_id: number;
}
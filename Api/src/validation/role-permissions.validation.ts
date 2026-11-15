import { z } from "zod";
import { USER_ROLES } from "../constants/enums.constants";

export const assignPermissionSchema = z.object({
  role: z.enum(USER_ROLES),
  permission_id: z.number().int().positive(),
});

export const rolePermissionFilterSchema = z.object({
  role: z.enum(USER_ROLES),
});

export const removePermissionSchema = assignPermissionSchema;

export type AssignPermissionInput = z.infer<typeof assignPermissionSchema>;
export type RolePermissionFilter = z.infer<typeof rolePermissionFilterSchema>;
export type RemovePermissionInput = z.infer<typeof removePermissionSchema>;
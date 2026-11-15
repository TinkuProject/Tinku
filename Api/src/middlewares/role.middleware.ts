import { Request, Response, NextFunction } from "express";
import {
  PERMISSIONS,
  PermissionCode,
  permissionForRoles,
} from "../constants/permissions.constants";

export const permissionMiddleware = (permission: PermissionCode) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    if (permission === PERMISSIONS.authorizationManage) {
      if (req.user.role !== "master") {
        return res.status(403).json({ error: "Forbidden" });
      }
      next();
      return;
    }

    if (!req.user.permissions.includes(permission)) {
      return res.status(403).json({ error: "Forbidden" });
    }

    next();
  };
};

// Compatibilidad para las rutas actuales. La autorización efectiva se
// resuelve mediante permisos, no comparando el rol del usuario directamente.
export const roleMiddleware = (roles: string[]) => {
  return permissionMiddleware(permissionForRoles(roles));
};

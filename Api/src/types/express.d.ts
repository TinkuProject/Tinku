import { UserRole } from "../constants/enums.constants";

declare module "express-serve-static-core" {
  interface Request {
    user?: {
      id: string;
      email?: string;
      role?: UserRole;
      permissions: string[];
    };
  }
}

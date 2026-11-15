import { Request } from "express";
import { PgDbClient } from "./pg-supabase-client";
import { UserRole } from "../constants/enums.constants";
import { DbClient } from "../types/db-client";

export const supabasePublic = new PgDbClient() as unknown as DbClient;

export const supabaseAdmin = new PgDbClient({
  role: "master",
}) as unknown as DbClient;

export const createUserClient = (
  userId: string,
  role?: UserRole
): DbClient => {
  if (!userId) {
    throw new Error("User ID is required");
  }

  return new PgDbClient({
    userId,
    ...(role ? { role } : {}),
  }) as unknown as DbClient;
};

export const getUserClientFromRequest = (req: Request): DbClient => {
  if (!req.user?.id) {
    throw new Error("Unauthorized");
  }

  return createUserClient(req.user.id, req.user.role);
};

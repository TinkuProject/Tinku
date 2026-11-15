import { UserRole } from "../constants/enums.constants";

export type Actor = {
  id: string;
  role?: UserRole | string;
};

export const isPrivileged = (role?: string): boolean => {
  return role === "admin" || role === "master";
};

export const isPartner = (role: string): boolean => {
  return role === "partner";
};

export function assertUser(
  user: any
): asserts user is Actor & { role: UserRole } {
  if (!user?.id || !user?.role) {
    throw new Error("Unauthorized");
  }
}

export function hasOwnershipAccess(
  ownerId: string | null | undefined,
  actor: Actor
): boolean {
  return ownerId === actor.id || isPrivileged(actor.role);
}

export function assertOwnershipAccess(
  ownerId: string | null | undefined,
  actor: Actor,
  notFoundMessage: string
): void {
  if (hasOwnershipAccess(ownerId, actor)) return;
  if (!ownerId) throw new Error(notFoundMessage);
  throw new Error("Unauthorized");
}

export function assertPrivileged(actor: Actor): void {
  if (!isPrivileged(actor.role)) {
    throw new Error("Unauthorized");
  }
}

export function assertDirectOwner(
  ownerId: string | null | undefined,
  userId: string,
  notFoundMessage: string
): void {
  if (ownerId === userId) return;
  if (!ownerId) throw new Error(notFoundMessage);
  throw new Error("Unauthorized");
}

export const PERMISSIONS = {
  accountAccess: "account.access",
  partnerAccess: "partner.access",
  paymentRequestCreate: "payment_request.create",
  ownedContentManage: "owned_content.manage",
  administrationManage: "administration.manage",
  authorizationManage: "authorization.manage",
} as const;

export type PermissionCode = typeof PERMISSIONS[keyof typeof PERMISSIONS];

const canonicalRoles = (roles: readonly string[]) => [...roles].sort().join(",");

const LEGACY_ROLE_POLICIES = new Map<string, PermissionCode>([
  [canonicalRoles(["user", "partner", "admin", "master"]), PERMISSIONS.accountAccess],
  [canonicalRoles(["partner"]), PERMISSIONS.partnerAccess],
  [canonicalRoles(["user", "partner"]), PERMISSIONS.paymentRequestCreate],
  [canonicalRoles(["partner", "admin", "master"]), PERMISSIONS.ownedContentManage],
  [canonicalRoles(["admin", "master"]), PERMISSIONS.administrationManage],
  [canonicalRoles(["master"]), PERMISSIONS.authorizationManage],
]);

export function permissionForRoles(roles: readonly string[]): PermissionCode {
  const permission = LEGACY_ROLE_POLICIES.get(canonicalRoles(roles));
  if (!permission) {
    throw new Error(`RBAC policy is not configured for roles: ${roles.join(", ")}`);
  }
  return permission;
}

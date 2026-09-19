import { handleCreateAccount } from "../_shared/createAccount.ts";

Deno.serve((req) =>
  handleCreateAccount(req, {
    requiredPermission: "manage_suppliers",
    defaultRoleId: "supplier",
    auditAction: "supplier_invited",
    entityType: "supplier",
  })
);

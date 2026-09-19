import { handleCreateAccount } from "../_shared/createAccount.ts";

Deno.serve((req) =>
  handleCreateAccount(req, {
    requiredPermission: "manage_customers",
    defaultRoleId: "customer",
    auditAction: "customer_invited",
    entityType: "customer",
  })
);

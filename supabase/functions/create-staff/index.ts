import { handleCreateAccount } from "../_shared/createAccount.ts";

Deno.serve((req) =>
  handleCreateAccount(req, {
    requiredPermission: "manage_employees",
    defaultRoleId: "sales_staff",
    auditAction: "staff_invited",
    entityType: "shop_member",
  })
);

import { corsHeaders } from "./cors.ts";
import { getClients, requireShopPermission, HttpError } from "./authz.ts";

export interface CreateAccountBody {
  shopId: string;
  name: string;
  phone?: string;
  email: string;
  roleId: string; // 'sales_staff' | 'manager' | ... for staff, or 'customer' / 'supplier'
  cnic?: string;
  joiningDate?: string;
  salary?: number;
  extra?: Record<string, unknown>; // e.g. { productsSupplied } for suppliers
  customPermissions?: string[];
}

export interface CreateAccountConfig {
  requiredPermission: string; // 'manage_employees' | 'manage_customers' | 'manage_suppliers'
  defaultRoleId: string; // fallback roleId when the caller doesn't specify one (customer/supplier)
  auditAction: string;
  entityType: string;
}

export async function handleCreateAccount(
  req: Request,
  config: CreateAccountConfig
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body: CreateAccountBody = await req.json();
    const { shopId, name, email } = body;
    if (!shopId || !name || !email) {
      throw new HttpError(400, "shopId, name and email are required.");
    }

    const { callerClient, adminClient } = getClients(req);
    const { callerId, callerName } = await requireShopPermission(
      callerClient,
      shopId,
      config.requiredPermission
    );

    // Look up the shop name once, purely for the invite email's context —
    // never used for any authorization decision.
    const { data: shop } = await adminClient
      .from("shops")
      .select("name")
      .eq("id", shopId)
      .single();

    // Invite (not create-with-password): Supabase sends the activation
    // email and the user sets their OWN password when they accept — the
    // shop never sees or shares a plain-text password, per the secure
    // invitation requirement.
    const { data: invited, error: inviteErr } =
      await adminClient.auth.admin.inviteUserByEmail(email, {
        redirectTo: "https://kznubtwfzvqvynqpbyve.supabase.co/auth/v1/callback",
        data: { full_name: name, invited_to_shop: shop?.name ?? "" },
      });
    if (inviteErr) {
      if (inviteErr.message?.toLowerCase().includes("already registered")) {
        throw new HttpError(
          409,
          "An account with this email already exists on the platform."
        );
      }
      throw new HttpError(500, inviteErr.message);
    }
    const newUserId = invited.user.id;

    const roleId = body.roleId || config.defaultRoleId;

    const { data: membership, error: memberErr } = await adminClient
      .from("shop_memberships")
      .insert({
        user_id: newUserId,
        shop_id: shopId,
        role_id: roleId,
        name,
        phone: body.phone ?? "",
        email,
        cnic: body.cnic ?? null,
        joining_date: body.joiningDate ?? null,
        salary: body.salary ?? null,
        custom_permissions: body.customPermissions ?? null,
        status: "invited",
        invited_by: callerId,
      })
      .select()
      .single();
    if (memberErr) throw new HttpError(500, memberErr.message);

    await adminClient.from("invitations").insert({
      shop_id: shopId,
      membership_id: membership.id,
      invited_email: email,
      invited_phone: body.phone ?? null,
      invited_by: callerId,
      status: "sent",
    });

    await adminClient.from("audit_logs").insert({
      shop_id: shopId,
      actor_id: callerId,
      actor_name: callerName,
      action: config.auditAction,
      entity_type: config.entityType,
      entity_id: membership.id,
      summary: `${callerName} invited ${name} (${config.entityType})`,
    });

    return new Response(
      JSON.stringify({ membershipId: membership.id, userId: newUserId }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    const status = err instanceof HttpError ? err.status : 500;
    const message = err instanceof Error ? err.message : "Unknown error";
    return new Response(JSON.stringify({ error: message }), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
}

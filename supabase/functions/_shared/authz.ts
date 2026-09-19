import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Every create-staff / create-customer / create-supplier function needs
 * two different Supabase clients:
 *
 *  - `callerClient`: authenticated AS the person calling the function, used
 *    only to verify who they are and that they actually have the
 *    permission they're claiming — the same "never trust the client"
 *    check RLS would do, run here explicitly because creating another
 *    user's Auth account requires the service-role key, which bypasses
 *    RLS entirely and must never reach the Flutter app.
 *
 *  - `adminClient`: the service-role client, used ONLY after the
 *    permission check passes, to actually create the Auth user and
 *    insert the membership/invitation rows.
 */
export function getClients(req: Request) {
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  return { callerClient, adminClient };
}

export async function requireShopPermission(
  callerClient: SupabaseClient,
  shopId: string,
  permission: string
) {
  const { data: userRes, error: userErr } = await callerClient.auth.getUser();
  if (userErr || !userRes?.user) {
    throw new HttpError(401, "You must be signed in.");
  }
  const callerId = userRes.user.id;

  const { data: allowed, error: permErr } = await callerClient.rpc(
    "has_permission",
    { p_shop_id: shopId, p_permission: permission }
  );
  if (permErr) throw new HttpError(500, permErr.message);
  if (!allowed) {
    throw new HttpError(403, `Missing permission: ${permission}`);
  }

  const { data: membership } = await callerClient
    .from("shop_memberships")
    .select("name")
    .eq("shop_id", shopId)
    .eq("user_id", callerId)
    .single();

  return { callerId, callerName: membership?.name ?? "Someone" };
}

export class HttpError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

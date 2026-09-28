# Mandi — Architecture

## Stack

- **Client**: Flutter (Android primary, iOS supported by the same code)
- **Backend**: Supabase — Postgres, Auth, Storage, Edge Functions
- **State**: `provider` package — `ChangeNotifierProxyProvider` wires
  shop-scoped providers to whichever shop is currently active

Originally built on Firebase (Firestore + Cloud Functions); migrated to
Supabase to move tenant isolation from hand-written security-rule logic
to real Postgres Row Level Security, and to drop the Blaze billing
requirement Cloud Functions needed. See `docs/MEMORY.md` for why, in
more detail.

## The one rule everything else follows

```
auth.uid()
   →  shop_memberships (status = 'active')
   →  shop_id + role_id + custom_permissions
   →  has_permission(shop_id, 'x') / is_shop_member(shop_id)
   →  every single RLS policy's actual check
```

No table trusts a `shop_id` the client sends. Client-side filtering
(`.eq('shop_id', ...)`) exists for correctness and performance only —
the real boundary is server-side RLS, re-deriving the same chain
independently on every request. See `supabase/schema.sql` for the full
policy set, and its own bottom-of-file security test checklist.

## Auth → Dashboard flow

```
Login (phone or email, no role/shop picker)
   ↓
AuthProvider resolves the Supabase session
   ↓
AppRoot calls ShopContextProvider.loadForUser(uid)
   ↓
Loads every active shop_memberships row for this user
   ↓
0 memberships  → NoShopPage ("Create New Shop")
1 membership   → that shop's dashboard, immediately
2+ memberships → "Choose Shop" (the ONLY case this ever shows)
   ↓
ShopContextProvider now exposes currentShop / currentMember /
currentRole / hasPermission(x) — every screen reads from here,
never from a hardcoded or passed-in shop id
```

## Why staff/customer/supplier creation needs Edge Functions

Creating another person's Auth account requires the service-role key,
which must never reach the Flutter app (it bypasses RLS entirely). So:

- `create-staff` / `create-customer` / `create-supplier` (Deno, in
  `supabase/functions/`) share one implementation
  (`_shared/createAccount.ts`): verify the caller's permission
  server-side via `has_permission()`, then use
  `admin.inviteUserByEmail()` — which sends an activation email and lets
  the person set their **own** password. No plain-text password is ever
  created, shown, or shared by the shop.
- Everything that does NOT need the service role stays a plain
  RLS-guarded client call: editing a member's profile, deactivating them
  (`shop_memberships.status = 'inactive'` — RLS already requires
  `status = 'active'` everywhere, so this alone fully cuts off access),
  and password resets (`supabase.auth.resetPasswordForEmail`, no
  privileged key needed at all).

## Atomic multi-table operations

Postgres doesn't give a Flutter client a "batch/transaction" primitive
the way Firestore did, so anywhere multiple tables must succeed or fail
together, it's a `plpgsql` RPC instead:

- `create_shop_with_owner(shop, ownerName, ownerPhone, ownerEmail, defaultRoles)`
  — shop row + default roles + owner's own membership, in one transaction.
- `create_invoice_with_stock_deduction(invoice, items)` — row-locks each
  product (`for update`), refuses the whole invoice if any item is
  short on stock, then inserts the invoice + items + inventory
  transactions. Not wired to any screen yet (invoicing UI is Planned).

## Data layer conventions

- **`SupabaseService`** (`lib/data/services/`) — one static class, one
  method per query/mutation, always filtered by `shop_id`. This is the
  only place `Supabase.instance.client.from(...)` should appear.
- **`AccountInviteService`** — the three Edge Function callers.
- **Model `fromMap`** parses real Postgres rows → **snake_case** keys.
- **Model `toMap`** on `Shop`/`Role` is the one deliberate exception:
  camelCase, because it feeds the `create_shop_with_owner` RPC's jsonb
  arguments, not a direct table insert. `ShopMember.toMap()` IS
  snake_case, because it's used as a real insert/update payload. This
  split is intentional — see the comment at the top of each `toMap()`.
- **`Product`/`Customer`/`Supplier`/`Invoice` models** still use their
  original camelCase Firebase-era `fromMap`/`toMap` — harmless today
  because nothing calls them yet, but they need the same snake_case
  pass before their screens get built (see TASKS.md).

## Folder structure

```
lib/
  core/
    theme/            design tokens (see DESIGN.md)
    utils/             pk_phone.dart, pk_cnic.dart — Pakistani formatting/validation
  data/
    models/            Shop, ShopMember, Role, + not-yet-wired Product/Customer/Supplier/Invoice
    services/          SupabaseService, AccountInviteService
  providers/           AuthProvider, ShopContextProvider
  modules/
    auth/               welcome, login, forgot-password (3 screens), register
    onboarding/          shop_setup_wizard (4 steps), no_shop_page
    employees/           list / add (invite) / detail — the template for
                          customers/suppliers screens when they get built
    home/                dashboard
  routes/               app_root.dart — the actual auth+shop gate
supabase/
  schema.sql            tables, RLS, RPCs, storage policies
  config.toml            CLI project link config
  functions/             create-staff, create-customer, create-supplier
docs/                   this folder
```

## Known architectural gaps

See `TASKS.md` for the live list. The two worth knowing up front:
phone-based invites aren't built (Supabase's invite API is email-only),
and Customer/Supplier have real backend support but no Flutter screens.

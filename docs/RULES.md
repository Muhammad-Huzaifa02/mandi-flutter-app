# Mandi — Rules

Conventions and hard constraints for whoever (or whatever agent) works
on this codebase next. Where a rule exists because of a real bug that
already happened here, that's noted — it's not a hypothetical.

## Security — non-negotiable

1. **Never trust a `shop_id` from the client for authorization.**
   Client-side `.eq('shop_id', ...)` is for performance/correctness
   only. Every table that holds shop data must have RLS policies that
   re-derive the caller's shop membership from `auth.uid()` — see the
   `has_permission()` / `is_shop_member()` pattern in
   `supabase/schema.sql`.
2. **Never put the Supabase service-role key in the Flutter app.** It
   bypasses RLS entirely. It lives only in Edge Function secrets. If a
   new feature seems to need it client-side, that's a sign the
   operation belongs in a new Edge Function instead.
3. **Never display, store, or transmit a plain-text password** for an
   account someone else created. Staff/customer/supplier creation is
   invitation-only (`admin.inviteUserByEmail` — the person sets their
   own password). Password resets use
   `supabase.auth.resetPasswordForEmail`, which needs no privileged key.
4. When you add a new shop-owned table, it needs: a `shop_id` column, an
   index on it, RLS enabled, and at minimum a "members can read" +
   permission-gated write policy — copy the pattern already used for
   `products`/`customers`/`suppliers` rather than inventing a new shape.
5. Before shipping a new RLS policy, ask: **could a customer read this?**
   The first draft of `shop_memberships`'s read policy let any active
   member (including a customer) read the full staff roster — phone
   numbers, salaries, everything. Fixed by requiring `manage_employees`
   permission to read anyone else's membership row, not just shop
   membership. Same principle applies to `profiles`.

## Data layer

6. `SupabaseService` fromMap parses **snake_case** Postgres columns.
   `toMap()` is snake_case too, UNLESS the model is `Shop` or `Role`,
   whose `toMap()` feeds the `create_shop_with_owner` RPC's jsonb
   arguments and is deliberately camelCase to match what that RPC
   parses. Don't "fix" one without checking the other side.
7. Any operation touching more than one table that must not partially
   succeed is a Postgres `plpgsql` function (see `create_shop_with_owner`,
   `create_invoice_with_stock_deduction`), not a client-side sequence of
   inserts. Postgres has no Firestore-style client batch/transaction.
8. `Product`/`Customer`/`Supplier`/`Invoice` models still carry
   Firebase-era camelCase `fromMap`/`toMap`. They compile today only
   because nothing calls them. Give them the snake_case pass `Shop`/
   `ShopMember`/`Role` already got *before* wiring up their screens, not
   after — otherwise the bug won't surface until runtime.

## Auth

9. `signUp()` succeeding does **not** mean the user is signed in. If the
   project has "Confirm email" enabled, `AuthResponse.session` is `null`
   until the confirmation link is clicked. Always check `.session`
   before navigating into a flow that assumes a live session — this
   exact gap once let someone fill out the entire Shop Setup Wizard
   before failing at the very last step with a confusing "session
   expired" error.
10. Supabase's `User` is not Firebase's `User`. There is no
    `.displayName`, `.photoURL`, `.emailVerified`. Use
    `user.userMetadata?['full_name']` etc. instead, and pass `data:
    {'full_name': ...}` to `signUp()`/invites so it's actually populated.
11. Error messages must match **Supabase's (GoTrue's)** actual message
    text ("Invalid login credentials", "Email not confirmed", ...), not
    Firebase's error codes ("wrong-password", "user-not-found"). They
    look similar enough to copy-paste wrong.

## Pakistani formatting

12. Always normalize phone numbers to E.164 (`+92...`) before any Auth
    call — use `PkPhone.toE164()`, never a raw typed string. Display
    formatting (`PkPhone.formatAsTyped`) and normalization are different
    functions for a reason: two different-looking inputs must resolve
    to the same account.
13. CNIC is masked (`35202-*******-1`) everywhere except the
    registration/profile-edit screen itself. Don't add a new screen
    that prints a full CNIC without checking whether it needs to.
14. Don't collect CNIC from customers unless the specific business
    process genuinely requires it (per the PRD) — it's optional on
    owner/staff registration, and deliberately absent from the
    Add Customer flow.

## SQL migrations

15. `supabase/schema.sql` must stay re-runnable from empty **and** from
    a partially-applied state. Every `create policy` needs a matching
    `drop policy if exists` immediately before it (already true for all
    51 current policies — keep the pattern for new ones). This isn't
    theoretical: a real SQL Editor run once died halfway through on a
    duplicate-policy error.

## UI

16. New shop-scoped screens: copy the Staff module's pattern
    (`modules/employees/`) — a `ChangeNotifierProxyProvider` keyed off
    `ShopContextProvider.currentShopId`, a list screen, an add/invite
    screen, a detail screen. It's the one module built end-to-end.
17. Design tokens live in `lib/core/theme/app_theme.dart`
    (`MColors`/`MSpacing`/`MRadius`/`MText`) — don't hardcode a color or
    spacing value that already has a token. See DESIGN.md.

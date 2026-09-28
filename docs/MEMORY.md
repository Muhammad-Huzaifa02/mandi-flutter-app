# Mandi — Project Memory

Running context for whoever picks this project up next — the *why*
behind decisions, not just the *what* (that's TASKS.md). Read this
before re-deriving something that was already figured out.

## Origin

Mandi is a ground-up rebuild of an existing single-shop app, **Saith
Commission Shop**. The instruction going in was explicit: don't
retrofit multi-tenancy onto the old single-shop codebase — start a new
Flutter project, but carry over what was already proven: the
Shop/ShopMember/Role data shapes, the commission/pricing math, the
invoicing logic. That's why the models look considered rather than
sketched — they were designed for multi-tenancy from the first line,
not patched later.

## Why Supabase, not Firebase (the app started on Firebase)

The original build (Batches 1–2: multi-tenant foundation + Staff
management) was Firebase/Firestore. It was migrated to Supabase because:

- Firestore Security Rules can express "is this the caller's shop" but
  awkwardly compared to real SQL joins/functions; Postgres RLS +
  `has_permission()`/`is_shop_member()` helper functions read much more
  directly as "the actual authorization logic," not a rules DSL bolted
  on top.
- Creating a staff/customer/supplier's Auth account without signing out
  the person creating it needs an Admin SDK — Firebase's version is
  Cloud Functions, which needs the Blaze (pay-as-you-go) plan even for
  a function that's rarely called. Supabase Edge Functions have no
  equivalent billing-tier gate.
- A genuine simplification fell out of the switch, not just a
  like-for-like swap: in Firestore, deactivating a member also had to
  disable their Firebase Auth account (Admin SDK call), because rules
  couldn't cheaply express "and is this membership currently active."
  In Postgres, **every single RLS policy already requires
  `status = 'active'`** — so deactivation is just a plain,
  RLS-guarded `update`, no privileged function needed at all. Same
  realization applied to password resets:
  `supabase.auth.resetPasswordForEmail` needs no service-role key,
  so that dropped its Edge Function too.

## The invitation model (why no plain-text passwords, ever)

Early exploration (in the standalone HTML prototypes, before the real
Supabase work) considered "owner creates account, shows a temp
password, shares it manually" — then a later round of requirements
explicitly ruled that out in favor of a secure invitation/activation
flow. The Edge Functions use `admin.inviteUserByEmail()`, which creates
the Auth user in an unconfirmed state and emails them an activation
link; they set their own password on acceptance. The shop never
sees or handles a credential for someone else's account. This is why
`shop_memberships.status` has three states (`invited`/`active`/
`inactive`), not two — `invited` is "account exists, hasn't accepted
yet," which is itself useful UI state (see `employee_detail_page.dart`'s
"waiting to activate" banner).

## Real bugs found along the way (and why they matter beyond the fix)

- **RLS over-exposure**: the first draft of `shop_memberships`'s
  "members can read" policy used `is_shop_member()`, which is true for
  a customer too — meaning a customer could've read the entire staff
  roster (phone numbers, salaries). Fixed by requiring
  `has_permission(shop_id, 'manage_employees')` instead. Lesson: "is a
  member" and "should see this data" are different questions; don't
  reach for the weaker check because it's already written.
- **`signUp()` "succeeding" isn't the same as being signed in.** With
  email confirmation on, `AuthResponse.session` is `null` until the
  link is clicked. The registration screen originally didn't check
  this, so someone could fill out the entire 4-step Shop Setup Wizard
  and only find out there was no session at the very last step
  ("Session expired. Please log in again.") — a real, reported failure,
  not a hypothetical. Now checked immediately after `signUp()`.
- **Supabase's `User` isn't Firebase's `User`.** `.displayName` doesn't
  exist; a leftover Firebase-shaped reference in `no_shop_page.dart`
  (written during the migration) didn't get caught until compile time.
  Swept the rest of the codebase for the same class of mistake
  afterward rather than assuming it was the only one.
- **`schema.sql` wasn't idempotent.** First real run against the user's
  own Supabase project died partway through on a duplicate-policy
  error — meaning a partial apply is unrecoverable without manual
  cleanup unless the file can be safely re-run from scratch. Fixed by
  adding `drop policy if exists` before all 51 policies. Any new policy
  added later needs the same guard, or this regresses.

## Decisions that look like inconsistencies but aren't

- **`Shop.toMap()`/`Role.toMap()` are camelCase; `ShopMember.toMap()` is
  snake_case.** Not an oversight — the first two feed the
  `create_shop_with_owner` RPC's jsonb arguments (which the RPC itself
  parses with camelCase keys), while `ShopMember` rows are inserted
  directly via PostgREST, which needs real column names. Don't
  "normalize" one without checking what actually consumes it.
- **Owner CNIC is set via a follow-up `updateShopMember` call, not a
  `create_shop_with_owner` RPC parameter.** Adding it to the RPC
  signature would've meant changing a function already in use; a
  one-line follow-up update was lower-risk for a field that's optional
  anyway.

## What hasn't been tested end-to-end

Everything in TASKS.md's "Done" list has been reasoned through
carefully and, where the user reported back, fixed against real runtime
errors on their actual Supabase project. But there is no automated test
suite yet, and several modules (Customer/Supplier UI, Products,
Invoicing) have real backend support with zero UI exercise. Treat
"schema + RLS exist" as "designed and reasoned about," not "battle
tested" — the same way the RLS gap and the idempotency gap above were
both things that looked right on paper first.

# Mandi — Multi-Shop Agricultural Business Platform

Flutter app, Supabase backend (Postgres + Auth + Storage + Edge Functions).
Migrated from an earlier Firebase-based build — see "Why Supabase" below
for what changed and why.

## Architecture

```
Flutter app
     │
     ▼
  Supabase
     │
 ┌───┼────────┬─────────────┐
 │   │        │             │
Auth │     Storage    Edge Functions
     ▼                      │
 PostgreSQL         (create-staff, create-customer,
 (RLS-enforced          create-supplier — the only
  multi-tenant           operations needing the
  data)                  service-role key)
```

The core rule enforced end to end:

```
auth.uid()  →  shop_memberships (active)  →  shop_id + role + permissions
                                                     ↓
                                    every table's Row Level Security check
```

No table trusts a `shop_id` sent by the client for authorization — every
RLS policy re-derives it from `shop_memberships` against `auth.uid()`.
Client-side filtering (`.eq('shop_id', ...)`) is there for correctness and
performance, not security.

## What's implemented

- **`supabase/schema.sql`** — full Postgres schema: `profiles`, `shops`,
  `roles`, `shop_memberships`, `invitations`, `audit_logs`, plus scaffolded
  business tables (`products`, `customers`, `suppliers`, `invoices`/
  `invoice_items`, `purchase_orders`, `inventory_transactions`, `expenses`,
  `payments`, `notifications`). RLS on every table. Two RPCs for the
  operations that need atomicity: `create_shop_with_owner` and
  `create_invoice_with_stock_deduction`.
- **`supabase/functions/`** — three Edge Functions (`create-staff`,
  `create-customer`, `create-supplier`) sharing one implementation.
  Invitation-based: they call Supabase's `inviteUserByEmail`, which sends
  an activation email and lets the person set their own password — no
  plain-text password is ever created, shown, or shared by the shop.
- **Flutter data layer**: `SupabaseService` (shop-scoped queries),
  `AccountInviteService` (calls the three Edge Functions),
  `ShopContextProvider` (resolves active shop + role + permissions),
  `AuthProvider` (Supabase Auth wrapper, email and phone sign-in).
- **Staff management**: list, add (invite), edit, deactivate/reactivate,
  send password reset — fully wired to Supabase, no code left assuming
  Firebase.
- **Onboarding**: Welcome → Owner Registration → 4-step Shop Setup Wizard
  → Dashboard, creating the shop via the `create_shop_with_owner` RPC.

## Why Supabase (what changed from the Firebase version)

- Firestore Security Rules → **Postgres Row Level Security**. Same idea
  (never trust the client's claimed shop), expressed as SQL policies
  instead of a separate rules DSL.
- Firebase Cloud Functions (Admin SDK, to create staff Auth accounts
  without signing the owner out) → **Supabase Edge Functions** using the
  service-role key, same reasoning.
- A genuine simplification: deactivating a member no longer needs a
  privileged function call at all. Firebase's Firestore rules couldn't
  cheaply express "is this membership currently active," so deactivation
  had to also disable the person's Firebase Auth account via the Admin
  SDK. Here, **every single RLS policy already requires
  `status = 'active'`** before granting any shop data access — flipping
  that one column via a plain, RLS-guarded update is enough to fully cut
  someone off. Same for password resets: Supabase's own
  `resetPasswordForEmail` needs no service-role key at all, so there's no
  Edge Function for it either.
- Temp passwords shown once by the owner → **secure invitation** (Supabase
  sends the activation email; the person sets their own password). This
  was also a requirement change, not just a backend swap.

## Known gaps — read before running

- **Phone-based invites aren't built.** `inviteUserByEmail` is what
  Supabase provides out of the box; there's no equivalent one-call phone
  invite. The Edge Functions currently require an email for every
  staff/customer/supplier invite. A phone-first invite would need
  `admin.createUser({phone, phone_confirm: true})` plus a custom SMS
  step — flagged here rather than left silently unsupported.
- **Customer/Supplier Flutter screens don't exist yet.** The Edge
  Functions (`create-customer`, `create-supplier`) and their RLS policies
  are real and ready; only the HTML prototype has UI for them so far. The
  Staff screens are the template to copy.
- **Products, Inventory, Invoices, Purchases, Expenses, Reports** have
  real schema and RLS but no Flutter UI — same "Planned" status as in the
  SRS, just now on the new backend. Note: `Product`, `Customer`,
  `Supplier`, `Invoice` model classes (`lib/data/models/`) still use their
  original camelCase `fromMap`/`toMap` keys from the Firebase version —
  they compile fine today only because nothing calls them yet. Give them
  the same snake_case pass `Shop`/`ShopMember`/`Role` already got (see
  those three files for the pattern) before wiring up their screens.
- `register_owner_page.dart` registers the owner by email (Supabase's
  `signUp` needs one identifier); phone-first *login* is fully wired, but
  a phone-first *signup* path for a brand-new owner isn't built yet.

## Setup

1. **Create a Supabase project** at supabase.com, then grab the Project
   URL and anon key from Project Settings → API.

2. **Run the schema**: Supabase Dashboard → SQL Editor → paste and run
   `supabase/schema.sql` (or `supabase db push` with the Supabase CLI).

3. **Deploy the Edge Functions** (requires the Supabase CLI):
   ```
   supabase functions deploy create-staff
   supabase functions deploy create-customer
   supabase functions deploy create-supplier
   ```
   These need `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
   `SUPABASE_SERVICE_ROLE_KEY` available as function secrets — the CLI
   sets the first two automatically; set the service role key with:
   ```
   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   ```
   Never put the service-role key anywhere in the Flutter app.

4. **Configure email templates** (optional but recommended): Supabase
   Dashboard → Authentication → Email Templates → customize the "Invite
   user" template so it matches Mandi's branding.

5. **Get Flutter platform folders** (this project only has `lib/`,
   `pubspec.yaml`, `supabase/` — no `android/`/`ios/` yet):
   ```
   flutter create --org com.yourcompany --project-name mandi .
   ```
   Decline overwriting `lib/` and `pubspec.yaml` if prompted.

6. **Install dependencies**:
   ```
   flutter pub get
   ```

7. **Run it**, passing your Supabase credentials at build/run time (never
   hardcode them into `lib/supabase_config.dart`):
   ```
   flutter run --dart-define=SUPABASE_URL=https://your-ref.supabase.co \
               --dart-define=SUPABASE_ANON_KEY=your-anon-key
   ```

## Security testing checklist

Run these manually against two seeded shops before trusting this in
production (see the bottom of `supabase/schema.sql` for the same list):

1. A member of Shop A can read Shop A's rows.
2. The same user selects Shop B's rows → empty result.
3. The same user tries to insert a row claiming `shop_id = Shop B` →
   denied by RLS regardless of what the client sends.
4. A customer account tries to read the full staff roster
   (`shop_memberships`) → denied; they can still read only their own
   membership row.
5. A deactivated membership (`status = 'inactive'`) immediately loses all
   access — no new login required, no Auth account changes needed.

## Phone-first login + Forgot Password (this batch)

- **`lib/core/utils/pk_phone.dart`** / **`pk_cnic.dart`** — live formatting,
  validation, normalization (to E.164 for Auth calls) and masking, shared
  by every screen that collects a phone number or CNIC.
- **`welcome_page.dart`** — rebuilt to match the unified-login
  architecture: "Login / Continue" is the one primary action; "Create New
  Shop" is a secondary link, not an equal second button.
- **`login_page.dart`** — one field accepts either a Pakistani phone
  number (live-formatted as you type) or an email address, routing to
  `AuthProvider.signInWithPhone` or `.signInWithEmail` accordingly. Nobody
  picks a role or a shop here — same as the HTML prototype's architecture,
  now real.
- **Forgot Password**, three screens (`forgot_password_phone_page.dart` →
  `forgot_password_otp_page.dart` → `forgot_password_new_password_page.dart`):
  phone entry → 6-digit OTP (auto-advance, 30s resend countdown, wrong-code
  state) → new password with a strength meter and visibility toggle. Uses
  Supabase's `signInWithOtp`/`verifyOTP` for phone, which is also how
  Supabase expects phone-based recovery to work (there's no phone
  equivalent of an email reset link). Verifying the OTP creates a real
  session, so "Password Updated" hands the person straight to their
  dashboard via `AppRoot` rather than back to the login form.
- **`register_owner_page.dart`** — mobile number now uses the same
  live-formatted, validated phone field; added an optional CNIC field with
  live formatting, persisted onto the owner's `shop_memberships` row after
  shop creation.

## Suggested next batches

1. Customer and Supplier Flutter screens, mirroring the Staff module.
2. Products/Inventory screens on `SupabaseService.productsStream`.
3. Invoice creation screen using `create_invoice_with_stock_deduction`.
4. A phone-based invite path for staff/customer/supplier creation (the
   Edge Functions are currently email-only — see "Known gaps" above).
5. Roles editor UI (permissions are already fully modeled; no UI to
   customize them per shop yet).

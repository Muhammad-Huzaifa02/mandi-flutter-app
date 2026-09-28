# Mandi — Tasks

## Done

- [x] Batch 1 — multi-tenant foundation: `Shop`/`ShopMember`/`Role`
      models, `ShopContextProvider`, `FirebaseService` (later replaced),
      Firestore rules, migration script.
- [x] Batch 2 — Employee (Staff) management: list, add, detail,
      activate/deactivate, per-member audit log.
- [x] Firebase → Supabase migration: full Postgres schema + RLS
      (`supabase/schema.sql`), three Edge Functions
      (`create-staff`/`create-customer`/`create-supplier`), rewired
      every Dart file that touched Firebase.
- [x] Fixed an RLS gap found during the migration: customers could have
      read the full staff roster (phone numbers, salaries) before the
      `manage_employees`-gated policy was added.
- [x] Phone-first login + Forgot Password (OTP) flow, wired into the
      real app (not just the HTML prototype): `pk_phone.dart`,
      `pk_cnic.dart`, rebuilt `welcome_page.dart`/`login_page.dart`,
      3-screen forgot-password flow.
- [x] CNIC field (live-formatted, optional) added to owner registration.
- [x] Original app icon + logo generated and wired into
      Splash/Welcome (`assets/icons/app_icon.png`,
      `assets/images/logo.png`).
- [x] `supabase/config.toml` for CLI project linking; real project
      credentials wired into `lib/supabase_config.dart`.
- [x] Fixed: `schema.sql` wasn't safely re-runnable (duplicate-policy
      error) — added `drop policy if exists` before all 51 policies.
- [x] Fixed: `no_shop_page.dart` used Firebase's `.displayName`, which
      doesn't exist on Supabase's `User` — swapped for `userMetadata`.
- [x] Fixed: registration navigated into the Shop Setup Wizard even
      when `signUp()` returned no session (project has "Confirm email"
      on) — now checks `.session` and shows a confirm-your-email step
      instead of failing at the very last screen of the wizard.

## In progress / next up

- [ ] **Customer Flutter screens** — list/add(invite)/detail, mirroring
      `modules/employees/`. Backend (`create-customer` Edge Function,
      RLS) is ready; no UI yet.
- [ ] **Supplier Flutter screens** — same shape, plus the dedicated
      Supplier Dashboard (purchase orders, deliveries, ledger,
      outstanding balance) sketched in the HTML prototype.
- [ ] **Products/Inventory screens** on `SupabaseService.productsStream`
      — schema and RLS exist, no UI.
- [ ] **Invoice creation screen** using the
      `create_invoice_with_stock_deduction` RPC (already atomic,
      already row-locks stock) — no UI yet.
- [ ] **Phone-based invite path** for staff/customer/supplier — Edge
      Functions currently only support `inviteUserByEmail`; a real
      Pakistani deployment will need phone-first invites too
      (`admin.createUser({phone, phone_confirm:true})` + a custom SMS
      step, since Supabase has no built-in phone-invite equivalent).
- [ ] **Roles editor UI** — permissions are fully modeled
      (`roles.permissions`, `shop_memberships.custom_permissions`); no
      screen to customize them per shop yet.
- [ ] **snake_case pass** on `Product`/`Customer`/`Supplier`/`Invoice`
      models (still Firebase-era camelCase `fromMap`/`toMap`) — do this
      *before* wiring up their screens, per RULES.md #8.
- [ ] Expenses, Reports, Notifications UI — schema ready, nothing built.
- [ ] Bring the HTML prototypes' "3D" visual language (layered
      shadows, staggered entrance, glass app bars) into the real
      Flutter theme, if wanted — see DESIGN.md's note on this.

## Explicitly out of scope for now

Mandi marketplace, shop-to-shop trading, farmer management, market
price analytics, delivery/transport management, multi-branch shops,
platform administrator console, subscription billing. (See PRD.md.)

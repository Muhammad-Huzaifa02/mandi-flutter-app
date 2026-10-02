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

- [x] **Customer Flutter screens** — list/add(invite)/detail, mirroring
      `modules/employees/`.
- [x] **Supplier Flutter screens** — list/add(invite)/detail, mirroring
      `modules/employees/`.
- [x] **snake_case pass** on `Customer` & `Supplier` models per RULES.md #8.
- [x] **Products/Inventory screens** on `SupabaseService.productsStream`
      + Mandi 40kg (Maund/Mann) pricing math calculator & low-stock alerts.
- [x] **snake_case pass** on `Product`, `Customer` & `Supplier` models per RULES.md #8.
- [x] **Invoice creation screen** using the
      `create_invoice_with_stock_deduction` RPC (atomic stock deduction & mandi commission math).
- [x] **snake_case pass** on `Product`, `Customer`, `Supplier` & `Invoice` models per RULES.md #8.
- [x] **Expenses Management screens** on `SupabaseService.expensesStream`
      (Labor, Transport, Rent, Packing, Electricity, Tea/Food, Other).
- [x] **Payments & Settlements screens** on `SupabaseService.paymentsStream`
      (Customer Receipts & Supplier Payments with automatic running_balance updates).
- [x] **Roles & Permissions Management** — customization of permissions per role (Manager, Accountant, Sales Staff, Inventory Staff, Custom).
- [x] **Audit Logs & Activity Trail** — live stream of shop actions (member activations, invoices, stock changes).
- [x] **Purchase Orders & Supplier Procurement** — purchase order management (`purchase_orders` table) with status tracking (`received`, `pending`, `cancelled`).
- [x] **Excel / CSV Report Exporting** — one-tap `.xlsx` report export for Invoices, Expenses, and Customer Ledgers.
- [ ] Bring the HTML prototypes' "3D" visual language (layered
      shadows, staggered entrance, glass app bars) into the real
      Flutter theme, if wanted — see DESIGN.md's note on this.

## Explicitly out of scope for now

Mandi marketplace, shop-to-shop trading, farmer management, market
price analytics, delivery/transport management, multi-branch shops,
platform administrator console, subscription billing. (See PRD.md.)

-- ============================================================================
-- Mandi — Supabase schema
-- ============================================================================
-- Replaces the Firebase/Firestore data model with normalized PostgreSQL +
-- Row Level Security. The core rule this schema enforces, matching the
-- Dart-side ShopContextProvider design:
--
--   auth.uid()  →  shop_memberships (active)  →  shop_id + role + permissions
--                                                        ↓
--                                          every shop-owned table's RLS check
--
-- No table trusts a shop_id sent by the client for authorization — every
-- policy re-derives it from shop_memberships against auth.uid().
-- ============================================================================

-- ── Extensions ───────────────────────────────────────────────────────────
create extension if not exists "pgcrypto"; -- gen_random_uuid()

-- ============================================================================
-- 1. PROFILES — one row per Supabase Auth user
-- ============================================================================
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null default '',
  phone       text,               -- normalized E.164, e.g. +923001234567
  email       text,
  cnic        text,               -- only ever populated where genuinely required
  avatar_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.profiles is
  'One row per Supabase Auth user. Never store a plain unmasked CNIC display '
  'in client code — mask it (35202-*******-1) outside secure edit screens.';

-- Auto-create a profile row the moment an Auth user is created (self-signup,
-- or an owner-invited staff/customer/supplier accepting their invite).
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.phone,
    new.email
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- ============================================================================
-- 2. SHOPS
-- ============================================================================
create table if not exists public.shops (
  id                          uuid primary key default gen_random_uuid(),
  name                        text not null,
  logo_url                    text,
  owner_id                    uuid not null references auth.users(id),
  business_types              text[] not null default '{}',
  phone                       text default '',
  whatsapp                    text default '',
  email                       text default '',
  address                     text default '',
  city                        text default '',
  district                    text default '',
  province                    text default '',
  ntn                         text default '',
  strn                        text default '',
  default_weight_unit         text default '40kg',
  default_commission_percent  numeric default 0,
  invoice_prefix              text default 'INV',
  invoice_next_number         integer not null default 1,
  receipt_prefix              text default 'RCPT',
  receipt_next_number         integer not null default 1,
  currency                    text default 'PKR',
  status                      text not null default 'active' check (status in ('active','suspended')),
  setup_complete              boolean not null default false,
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now()
);

create index if not exists idx_shops_owner on public.shops(owner_id);

-- ============================================================================
-- 3. ROLES — scoped per shop; permissions live directly on the role
--    (a per-membership `custom_permissions` override lives on shop_memberships
--    below, so two Sales Staff can still diverge without needing a second role)
-- ============================================================================
create table if not exists public.roles (
  id            text not null,             -- 'owner' | 'manager' | ... | custom slug
  shop_id       uuid not null references public.shops(id) on delete cascade,
  name          text not null,
  is_default    boolean not null default false,
  permissions   text[] not null default '{}',
  created_at    timestamptz not null default now(),
  primary key (shop_id, id)
);

-- ============================================================================
-- 4. SHOP_MEMBERSHIPS — the foundation of the entire multi-tenant system
-- ============================================================================
create table if not exists public.shop_memberships (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users(id) on delete cascade,
  shop_id             uuid not null references public.shops(id) on delete cascade,
  role_id             text not null,
  custom_permissions  text[],             -- null = use role's permissions as-is
  name                text not null default '',
  phone               text default '',
  email               text default '',
  cnic                text,
  joining_date        date,
  salary              numeric,
  status              text not null default 'invited'
                        check (status in ('invited','active','inactive')),
  invited_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (user_id, shop_id),
  foreign key (shop_id, role_id) references public.roles(shop_id, id)
);

create index if not exists idx_memberships_user on public.shop_memberships(user_id);
create index if not exists idx_memberships_shop on public.shop_memberships(shop_id);

comment on column public.shop_memberships.status is
  'invited = Auth account created, invite sent, not yet activated. '
  'active = normal working account. inactive = deactivated, login blocked by RLS.';

-- ── Helper functions used throughout RLS policies ──────────────────────────

-- Returns the caller's active membership row for a shop, or null.
create or replace function public.current_membership(p_shop_id uuid)
returns public.shop_memberships
language sql stable security definer set search_path = public as $$
  select * from public.shop_memberships
  where shop_id = p_shop_id and user_id = auth.uid() and status = 'active'
  limit 1;
$$;

-- Is the caller an active member of this shop at all (any role)?
create or replace function public.is_shop_member(p_shop_id uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from public.shop_memberships
    where shop_id = p_shop_id and user_id = auth.uid() and status = 'active'
  );
$$;

-- Does the caller's membership in this shop grant a specific permission?
-- custom_permissions overrides the role's permission list entirely when set,
-- so an owner can grant/revoke individual permissions per staff member.
create or replace function public.has_permission(p_shop_id uuid, p_permission text)
returns boolean
language plpgsql stable security definer set search_path = public as $$
declare
  m public.shop_memberships;
  role_perms text[];
begin
  select * into m from public.shop_memberships
    where shop_id = p_shop_id and user_id = auth.uid() and status = 'active'
    limit 1;
  if m is null then return false; end if;

  if m.custom_permissions is not null then
    return p_permission = any(m.custom_permissions);
  end if;

  select permissions into role_perms from public.roles
    where shop_id = p_shop_id and id = m.role_id;
  return coalesce(p_permission = any(role_perms), false);
end;
$$;

-- ============================================================================
-- 5. INVITATIONS — audit trail of the secure invite/activation flow
--    (the actual credential handoff is Supabase Auth's own invite email;
--    this table just tracks status for the owner-facing UI)
-- ============================================================================
create table if not exists public.invitations (
  id              uuid primary key default gen_random_uuid(),
  shop_id         uuid not null references public.shops(id) on delete cascade,
  membership_id   uuid not null references public.shop_memberships(id) on delete cascade,
  invited_email   text,
  invited_phone   text,
  invited_by      uuid not null references auth.users(id),
  status          text not null default 'sent' check (status in ('sent','accepted','expired','revoked')),
  created_at      timestamptz not null default now(),
  accepted_at     timestamptz
);

-- ============================================================================
-- 6. AUDIT LOGS — append-only
-- ============================================================================
create table if not exists public.audit_logs (
  id           uuid primary key default gen_random_uuid(),
  shop_id      uuid not null references public.shops(id) on delete cascade,
  actor_id     uuid references auth.users(id),
  actor_name   text default '',
  action       text not null,
  entity_type  text not null,
  entity_id    text,
  summary      text not null default '',
  created_at   timestamptz not null default now()
);

create index if not exists idx_audit_shop on public.audit_logs(shop_id);
create index if not exists idx_audit_actor on public.audit_logs(shop_id, actor_id);

-- ============================================================================
-- 7. BUSINESS TABLES — schema now, most UI in a later batch (see README)
-- ============================================================================
create table if not exists public.products (
  id                 uuid primary key default gen_random_uuid(),
  shop_id            uuid not null references public.shops(id) on delete cascade,
  supplier_id        uuid,
  supplier_name      text default '',
  name               text not null,
  category           text default '',
  sku                text,
  description        text default '',
  unit               text default 'kg',
  weight_per_unit_kg numeric default 0,
  purchase_price     numeric default 0,
  selling_price      numeric default 0,
  min_stock_level    numeric default 0,
  current_stock      numeric default 0,
  image_url          text,
  is_active          boolean not null default true,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
alter table public.products add column if not exists supplier_id uuid;
alter table public.products add column if not exists supplier_name text default '';
create index if not exists idx_products_shop on public.products(shop_id);

create table if not exists public.customers (
  id               uuid primary key default gen_random_uuid(),
  shop_id          uuid not null references public.shops(id) on delete cascade,
  user_id          uuid references auth.users(id),  -- null until/unless they get a login
  name             text not null,
  phone            text default '',
  email            text default '',
  address          text default '',
  city             text default '',
  opening_balance  numeric default 0,
  running_balance  numeric default 0,
  created_at       timestamptz not null default now()
);
create index if not exists idx_customers_shop on public.customers(shop_id);

create table if not exists public.suppliers (
  id                 uuid primary key default gen_random_uuid(),
  shop_id            uuid not null references public.shops(id) on delete cascade,
  user_id            uuid references auth.users(id),
  name               text not null,
  phone              text default '',
  email              text default '',
  products_supplied  text default '',
  opening_balance    numeric default 0,
  running_balance    numeric default 0,
  created_at         timestamptz not null default now()
);
create index if not exists idx_suppliers_shop on public.suppliers(shop_id);

create table if not exists public.invoices (
  id              uuid primary key default gen_random_uuid(),
  shop_id         uuid not null references public.shops(id) on delete cascade,
  customer_id     uuid references public.customers(id),
  invoice_number  text not null,
  subtotal        numeric default 0,
  commission      numeric default 0,
  expenses        numeric default 0,
  discount        numeric default 0,
  total           numeric default 0,
  received_amount numeric default 0,
  pending_amount  numeric default 0,
  payment_method  text default 'cash',
  status          text not null default 'unpaid' check (status in ('unpaid','partial','paid','void')),
  created_by      uuid references auth.users(id),
  created_at      timestamptz not null default now(),
  unique (shop_id, invoice_number)
);
-- Added after the fact: consignment-sale (supplier) invoices. The app's
-- Dart side (Invoice model, create_invoice_page.dart) and the
-- cancel_invoice_and_restore_stock RPC already assumed these two columns
-- existed; they never did, so cancelling ANY invoice crashed at runtime
-- the instant PL/pgSQL tried to read v_invoice.supplier_id from a record
-- that had no such field.
alter table public.invoices add column if not exists supplier_id uuid references public.suppliers(id);
alter table public.invoices add column if not exists supplier_payout numeric default 0;
create index if not exists idx_invoices_shop on public.invoices(shop_id);

create table if not exists public.invoice_items (
  id              uuid primary key default gen_random_uuid(),
  invoice_id      uuid not null references public.invoices(id) on delete cascade,
  shop_id         uuid not null references public.shops(id) on delete cascade,
  product_id      uuid references public.products(id),
  quantity        numeric not null default 0,
  weight_kg       numeric default 0,
  unit_price      numeric default 0,
  line_total      numeric default 0
);
create index if not exists idx_invoice_items_shop on public.invoice_items(shop_id);

create table if not exists public.purchase_orders (
  id              uuid primary key default gen_random_uuid(),
  shop_id         uuid not null references public.shops(id) on delete cascade,
  supplier_id     uuid references public.suppliers(id),
  status          text not null default 'pending' check (status in ('pending','received','cancelled')),
  total           numeric default 0,
  paid_amount     numeric default 0,
  pending_amount  numeric default 0,
  created_by      uuid references auth.users(id),
  created_at      timestamptz not null default now()
);
create index if not exists idx_po_shop on public.purchase_orders(shop_id);

create table if not exists public.inventory_transactions (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid not null references public.shops(id) on delete cascade,
  product_id  uuid not null references public.products(id),
  change_kg   numeric not null,
  type        text not null check (type in ('sale','purchase','adjustment','damage','return')),
  reference   text,
  created_by  uuid references auth.users(id),
  created_at  timestamptz not null default now()
);
create index if not exists idx_inv_txn_shop on public.inventory_transactions(shop_id);

create table if not exists public.expenses (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid not null references public.shops(id) on delete cascade,
  category    text not null default 'other',
  amount      numeric not null default 0,
  note        text default '',
  reference   text,
  created_by  uuid references auth.users(id),
  created_at  timestamptz not null default now()
);
create index if not exists idx_expenses_shop on public.expenses(shop_id);

create table if not exists public.payments (
  id            uuid primary key default gen_random_uuid(),
  shop_id       uuid not null references public.shops(id) on delete cascade,
  party_type    text not null check (party_type in ('customer','supplier')),
  party_id      uuid not null,
  amount        numeric not null,
  method        text default 'cash',
  reference     text,
  created_by    uuid references auth.users(id),
  created_at    timestamptz not null default now()
);
create index if not exists idx_payments_shop on public.payments(shop_id);

create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid not null references public.shops(id) on delete cascade,
  user_id     uuid references auth.users(id),
  title       text not null,
  message     text default '',
  type        text default 'info',
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists idx_notifications_user on public.notifications(user_id, shop_id);

-- ============================================================================
-- 7b. CONSIGNMENT_LOTS (Dheri / آمد و ڈھیری)
--     Tracks incoming crop consignments from farmers, auction bidding,
--     and conversion to sales invoices.
-- ============================================================================
create table if not exists public.consignment_lots (
  id                  uuid primary key default gen_random_uuid(),
  shop_id             uuid not null references public.shops(id) on delete cascade,
  lot_number          text not null,
  supplier_id         uuid references public.suppliers(id) on delete set null,
  supplier_name       text not null default '',
  product_id          uuid references public.products(id) on delete set null,
  product_name        text not null default '',
  vehicle_number      text not null default '',
  bag_count           integer not null default 0,
  weight_kg           numeric not null default 0,
  rate_per_maund      numeric default 0,
  winning_buyer_id    uuid references public.customers(id) on delete set null,
  winning_buyer_name  text not null default '',
  invoice_id          uuid references public.invoices(id) on delete set null,
  status              text not null default 'arrived' check (status in ('arrived', 'auctioning', 'sold', 'settled', 'cancelled')),
  notes               text not null default '',
  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index if not exists idx_consignment_lots_shop on public.consignment_lots(shop_id);
create index if not exists idx_consignment_lots_supplier on public.consignment_lots(supplier_id);
create index if not exists idx_consignment_lots_date on public.consignment_lots(shop_id, created_at desc);

-- ============================================================================
-- 7c. BANK_ACCOUNTS & CHEQUES (PDC / بینکاری اور چیک رجسٹر)
--     Commercial bank accounts, post-dated cheques, clearance lifecycle,
--     and dishonored/bounced tracking.
-- ============================================================================
create table if not exists public.bank_accounts (
  id                  uuid primary key default gen_random_uuid(),
  shop_id             uuid not null references public.shops(id) on delete cascade,
  bank_name           text not null,
  account_title       text not null default '',
  account_number      text not null default '',
  iban                text not null default '',
  branch_name         text not null default '',
  branch_code         text not null default '',
  opening_balance     numeric not null default 0,
  current_balance     numeric not null default 0,
  is_default          boolean not null default false,
  is_active           boolean not null default true,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index if not exists idx_bank_accounts_shop on public.bank_accounts(shop_id);

create table if not exists public.cheques (
  id                      uuid primary key default gen_random_uuid(),
  shop_id                 uuid not null references public.shops(id) on delete cascade,
  cheque_number           text not null,
  type                    text not null default 'received' check (type in ('received', 'issued')),
  party_type              text not null default 'customer' check (party_type in ('customer', 'supplier', 'other')),
  party_id                uuid,
  party_name              text not null default '',
  bank_name               text not null default '',
  target_bank_account_id  uuid references public.bank_accounts(id) on delete set null,
  amount                  numeric not null default 0,
  issue_date              timestamptz not null default now(),
  due_date                timestamptz not null default now(),
  deposit_date            timestamptz,
  clearance_date          timestamptz,
  status                  text not null default 'in_hand' check (status in ('in_hand', 'deposited', 'cleared', 'bounced', 'returned')),
  bounce_reason           text not null default '',
  notes                   text not null default '',
  created_by              uuid references auth.users(id),
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create index if not exists idx_cheques_shop on public.cheques(shop_id);
create index if not exists idx_cheques_due on public.cheques(shop_id, due_date asc);
create index if not exists idx_cheques_status on public.cheques(shop_id, status);

-- ============================================================================
-- 7d. STORAGE_LOCATIONS, STORAGE_ALLOCATIONS & BARDANA_TRANSACTIONS
--     Tracks Godowns, Cold Stores, batch stock allocations, and gunny bag /
--     sack / crate (باردانہ) ledger between farmers and buyers.
-- ============================================================================
create table if not exists public.storage_locations (
  id                      uuid primary key default gen_random_uuid(),
  shop_id                 uuid not null references public.shops(id) on delete cascade,
  name                    text not null,
  location_type           text not null default 'godown' check (location_type in ('godown', 'cold_storage', 'shop_pharr')),
  address                 text not null default '',
  contact_person          text not null default '',
  phone                   text not null default '',
  capacity_bags           integer not null default 0,
  current_bags            integer not null default 0,
  monthly_rent_per_bag    numeric not null default 0,
  is_active               boolean not null default true,
  notes                   text not null default '',
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create index if not exists idx_storage_locations_shop on public.storage_locations(shop_id);

create table if not exists public.storage_allocations (
  id                      uuid primary key default gen_random_uuid(),
  shop_id                 uuid not null references public.shops(id) on delete cascade,
  storage_location_id     uuid not null references public.storage_locations(id) on delete cascade,
  product_id              uuid references public.products(id) on delete set null,
  product_name            text not null default '',
  lot_number              text not null default '',
  party_name              text not null default '',
  bag_count               integer not null default 0,
  weight_kg               numeric not null default 0,
  inward_date             timestamptz not null default now(),
  outward_date            timestamptz,
  status                  text not null default 'in_store' check (status in ('in_store', 'dispatched', 'released', 'partially_dispatched')),
  rent_rate_per_bag       numeric not null default 0,
  total_rent_charged      numeric not null default 0,
  notes                   text not null default '',
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create index if not exists idx_storage_allocations_shop on public.storage_allocations(shop_id);
create index if not exists idx_storage_allocations_loc on public.storage_allocations(storage_location_id);

create table if not exists public.bardana_transactions (
  id                      uuid primary key default gen_random_uuid(),
  shop_id                 uuid not null references public.shops(id) on delete cascade,
  party_type              text not null default 'supplier' check (party_type in ('supplier', 'customer', 'other')),
  party_id                uuid,
  party_name              text not null default '',
  bardana_type            text not null default 'jute' check (bardana_type in ('jute', 'plastic_pp', 'wooden_crate', 'plastic_crate', 'other')),
  direction               text not null default 'issued' check (direction in ('issued', 'returned', 'purchased', 'damaged')),
  bag_count               integer not null default 0,
  unit_deposit_rate       numeric not null default 0,
  total_deposit_amount    numeric not null default 0,
  transaction_date        timestamptz not null default now(),
  due_return_date         timestamptz,
  status                  text not null default 'pending' check (status in ('pending', 'returned', 'settled', 'forfeited')),
  notes                   text not null default '',
  created_by              uuid references auth.users(id),
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create index if not exists idx_bardana_transactions_shop on public.bardana_transactions(shop_id);
create index if not exists idx_bardana_party on public.bardana_transactions(shop_id, party_id);
create index if not exists idx_bardana_status on public.bardana_transactions(shop_id, status);

-- 7e. WEIGHBRIDGE_TICKETS (Mandi Kanda & Weighbridge / دھرم کنڈا)
create table if not exists public.weighbridge_tickets (
  id                      uuid primary key default gen_random_uuid(),
  shop_id                 uuid not null references public.shops(id) on delete cascade,
  ticket_number           text not null,
  vehicle_number          text not null,
  vehicle_type            text not null default 'trolley', -- trolley, truck_mazda, shehzore, pickup_dala, rickshaw_loader, other
  driver_name             text not null default '',
  driver_phone            text not null default '',
  party_name              text not null default '', -- Farmer or Buyer name
  party_type              text not null default 'farmer', -- farmer, buyer, other
  party_id                uuid,
  commodity_name          text not null default '',
  gross_weight_kg         numeric(12,2) not null default 0,
  tare_weight_kg          numeric(12,2) not null default 0,
  net_weight_kg           numeric(12,2) not null default 0,
  deduction_kg            numeric(12,2) not null default 0,
  deduction_reason        text not null default '',
  final_weight_kg         numeric(12,2) not null default 0,
  bag_count               int not null default 0,
  kanda_fee               numeric(10,2) not null default 0,
  fee_paid_by             text not null default 'farmer', -- farmer, buyer, shop, waived
  status                  text not null default 'gross_recorded', -- gross_recorded, completed, cancelled
  gross_weighed_at        timestamptz not null default now(),
  tare_weighed_at         timestamptz,
  operator_name           text not null default '',
  consignment_lot_id      uuid references public.consignment_lots(id) on delete set null,
  notes                   text not null default '',
  created_by              uuid references auth.users(id),
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create index if not exists idx_weighbridge_tickets_shop on public.weighbridge_tickets(shop_id);
create index if not exists idx_weighbridge_vehicle on public.weighbridge_tickets(shop_id, vehicle_number);
create index if not exists idx_weighbridge_status on public.weighbridge_tickets(shop_id, status);
create index if not exists idx_weighbridge_created on public.weighbridge_tickets(shop_id, created_at desc);

-- 7f. FARMER_ADVANCES & ADVANCE_RECOVERIES (زمیندار ایڈوانس اور کھاد بیج کھاتہ)
create table if not exists public.farmer_advances (
  id                      uuid primary key default gen_random_uuid(),
  shop_id                 uuid not null references public.shops(id) on delete cascade,
  supplier_id             uuid not null references public.suppliers(id) on delete cascade,
  farmer_name             text not null default '',
  farmer_phone            text not null default '',
  advance_type            text not null default 'cash', -- cash, fertilizer, seed, pesticide, diesel, other
  description             text not null default '',
  principal_amount        numeric(12,2) not null default 0,
  markup_percent          numeric(5,2) not null default 0,
  markup_amount           numeric(12,2) not null default 0,
  total_payable           numeric(12,2) not null default 0,
  recovered_amount        numeric(12,2) not null default 0,
  remaining_balance       numeric(12,2) not null default 0,
  disbursement_date       timestamptz not null default now(),
  expected_harvest_date   timestamptz,
  target_crop             text not null default '',
  status                  text not null default 'active', -- active, partially_recovered, fully_recovered, written_off
  payment_method          text not null default 'cash', -- cash, bank_transfer, cheque
  bank_account_id         uuid references public.bank_accounts(id) on delete set null,
  notes                   text not null default '',
  created_by              uuid references auth.users(id),
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create index if not exists idx_farmer_advances_shop on public.farmer_advances(shop_id);
create index if not exists idx_farmer_advances_supplier on public.farmer_advances(shop_id, supplier_id);
create index if not exists idx_farmer_advances_status on public.farmer_advances(shop_id, status);

create table if not exists public.farmer_advance_recoveries (
  id                      uuid primary key default gen_random_uuid(),
  shop_id                 uuid not null references public.shops(id) on delete cascade,
  advance_id              uuid not null references public.farmer_advances(id) on delete cascade,
  consignment_lot_id      uuid references public.consignment_lots(id) on delete set null,
  invoice_id              uuid references public.invoices(id) on delete set null,
  recovered_amount        numeric(12,2) not null default 0,
  recovery_date           timestamptz not null default now(),
  recovery_method         text not null default 'consignment_deduction', -- consignment_deduction, cash_payment, bank_transfer
  notes                   text not null default '',
  created_by              uuid references auth.users(id),
  created_at              timestamptz not null default now()
);

create index if not exists idx_advance_recoveries_advance on public.farmer_advance_recoveries(advance_id);
create index if not exists idx_advance_recoveries_shop on public.farmer_advance_recoveries(shop_id);

-- 7g. CROSS_BORDER_SHIPMENTS (پاک افغان و پاک ایران سرحدی تجارت اور کرنسی کھاتہ)
create table if not exists public.cross_border_shipments (
  id                          uuid primary key default gen_random_uuid(),
  shop_id                     uuid not null references public.shops(id) on delete cascade,
  shipment_number             text not null default '',
  origin_country              text not null default 'Afghanistan', -- Afghanistan, Iran, CentralAsia, Other
  origin_city                 text not null default '',
  border_crossing             text not null default 'Torkham', -- Torkham, Chaman, Taftan, Gabd_Rimdan, Khunjerab, Other
  vehicle_number              text not null default '',
  driver_name                 text not null default '',
  driver_phone                text not null default '',
  customs_gd_number           text not null default '', -- Goods Declaration (GD) Number
  customs_clearance_date      timestamptz,
  clearing_agent_name         text not null default '',
  supplier_id                 uuid references public.suppliers(id) on delete set null,
  supplier_name               text not null default '',
  commodity                   text not null default '',
  package_type                text not null default 'Wooden Crate', -- Wooden Crate, Carton Box, Sack, Reusable Bin
  package_count               integer not null default 0,
  gross_weight_kg             numeric(12,2) not null default 0,
  currency                    text not null default 'USD', -- USD, AFN, IRR, PKR
  exchange_rate_to_pkr        numeric(12,4) not null default 1.0,
  foreign_contract_amount     numeric(14,2) not null default 0,
  base_pkr_amount             numeric(14,2) not null default 0,
  customs_duty_pkr            numeric(12,2) not null default 0,
  border_freight_pkr          numeric(12,2) not null default 0,
  clearing_charges_pkr        numeric(12,2) not null default 0,
  other_expenses_pkr          numeric(12,2) not null default 0,
  total_landed_cost_pkr       numeric(14,2) not null default 0,
  paid_to_supplier_foreign    numeric(14,2) not null default 0,
  remaining_supplier_foreign  numeric(14,2) not null default 0,
  status                      text not null default 'in_transit', -- in_transit, cleared_at_border, arrived_in_mandi, auctioned, settled
  consignment_lot_id          uuid references public.consignment_lots(id) on delete set null,
  notes                       text not null default '',
  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now()
);

create index if not exists idx_cross_border_shop on public.cross_border_shipments(shop_id);
create index if not exists idx_cross_border_status on public.cross_border_shipments(shop_id, status);
create index if not exists idx_cross_border_country on public.cross_border_shipments(shop_id, origin_country);
create index if not exists idx_cross_border_created on public.cross_border_shipments(shop_id, created_at desc);

-- 7h. SMS_GATEWAY_SETTINGS & SMS_LOGS (خودکار ایس ایم ایس گیٹ وے اور تصدیقی پیغامات)
create table if not exists public.sms_gateway_settings (
  id                          uuid primary key default gen_random_uuid(),
  shop_id                     uuid not null unique references public.shops(id) on delete cascade,
  provider                    text not null default 'mock', -- mock, twilio, generic_http, telco_pakistan
  is_enabled                  boolean not null default false,
  sender_id                   text not null default 'MANDI-ERP', -- Alphanumeric mask or sender phone
  api_key                     text not null default '',
  api_secret                  text not null default '', -- Auth token / API Secret
  account_sid                 text not null default '', -- Twilio Account SID or User ID
  from_number                 text not null default '', -- Sender phone number e.g. Twilio number
  webhook_url                 text not null default '', -- Generic HTTP API URL
  http_method                 text not null default 'POST', -- POST, GET
  http_headers_json           jsonb not null default '{}'::jsonb,
  http_payload_template       text not null default '{"to": "{to}", "message": "{message}", "sender": "{sender}"}',
  auto_send_on_invoice        boolean not null default true,
  auto_send_on_payment        boolean not null default true,
  auto_send_on_boli           boolean not null default false,
  auto_send_on_weighbridge    boolean not null default false,
  auto_send_on_advance        boolean not null default false,
  sms_credit_balance          numeric(10,2) not null default 0.00,
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now()
);

create index if not exists idx_sms_settings_shop on public.sms_gateway_settings(shop_id);

create table if not exists public.sms_logs (
  id                          uuid primary key default gen_random_uuid(),
  shop_id                     uuid not null references public.shops(id) on delete cascade,
  recipient_phone             text not null,
  recipient_name              text not null default '',
  message_body                text not null,
  event_type                  text not null default 'manual', -- invoice, payment, boli, weighbridge, farmer_advance, recovery_reminder, manual_test
  provider                    text not null default 'mock',
  status                      text not null default 'pending', -- pending, sent, delivered, failed
  external_message_id         text not null default '',
  error_message               text,
  parts_count                 integer not null default 1,
  cost_pkr                    numeric(10,2) not null default 0.00,
  created_at                  timestamptz not null default now()
);

create index if not exists idx_sms_logs_shop on public.sms_logs(shop_id);
create index if not exists idx_sms_logs_status on public.sms_logs(shop_id, status);
create index if not exists idx_sms_logs_event on public.sms_logs(shop_id, event_type);
create index if not exists idx_sms_logs_created on public.sms_logs(shop_id, created_at desc);

-- 7i. INTER_SHOP_STOCK_TRANSFERS (بین المانڈی اسٹاک منتقلی اور برانچ کھاتہ)
create table if not exists public.inter_shop_transfers (
  id                          uuid primary key default gen_random_uuid(),
  transfer_number             text not null default '',
  source_shop_id              uuid not null references public.shops(id) on delete cascade,
  destination_shop_id         uuid not null references public.shops(id) on delete cascade,
  product_id                  uuid references public.products(id) on delete set null,
  commodity_name              text not null default '',
  quantity_kg                 numeric(12,2) not null default 0,
  quantity_maunds             numeric(12,2) not null default 0,
  package_type                text not null default 'Bag', -- Bag, Crate, Carton, Loose
  package_count               integer not null default 0,
  unit_cost_pkr               numeric(12,2) not null default 0,
  total_value_pkr             numeric(14,2) not null default 0,
  transit_freight_pkr         numeric(12,2) not null default 0,
  vehicle_number              text not null default '',
  driver_name                 text not null default '',
  driver_phone                text not null default '',
  dispatched_at               timestamptz not null default now(),
  received_at                 timestamptz,
  status                      text not null default 'in_transit', -- in_transit, received, cancelled
  notes                       text not null default '',
  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now(),
  constraint chk_diff_shops check (source_shop_id <> destination_shop_id)
);

create index if not exists idx_transfers_source on public.inter_shop_transfers(source_shop_id);
create index if not exists idx_transfers_destination on public.inter_shop_transfers(destination_shop_id);
create index if not exists idx_transfers_status on public.inter_shop_transfers(source_shop_id, destination_shop_id, status);
create index if not exists idx_transfers_created on public.inter_shop_transfers(source_shop_id, created_at desc);

-- 7j. AUDIO_VOICE_NOTES (منشی صوتی نوٹس اور آواز سے کھاتہ اندراج)
create table if not exists public.audio_voice_notes (
  id                          uuid primary key default gen_random_uuid(),
  shop_id                     uuid not null references public.shops(id) on delete cascade,
  title                       text not null default '',
  audio_url                   text not null default '',
  storage_path                text not null default '',
  duration_seconds            integer not null default 0,
  file_size_bytes             integer not null default 0,
  mime_type                   text not null default 'audio/m4a',
  transcription_text          text not null default '',
  detected_party_type         text not null default 'none', -- none, customer, supplier
  party_id                    uuid,
  party_name                  text not null default '',
  entity_type                 text not null default 'general', -- general, invoice, consignment_lot, weighbridge, khata_payment
  entity_id                   uuid,
  parsed_amount_pkr           numeric(12,2) not null default 0,
  parsed_maunds               numeric(10,2) not null default 0,
  status                      text not null default 'pending', -- pending, processed, archived
  notes                       text not null default '',
  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now()
);

create index if not exists idx_audio_notes_shop on public.audio_voice_notes(shop_id);
create index if not exists idx_audio_notes_status on public.audio_voice_notes(shop_id, status);
create index if not exists idx_audio_notes_entity on public.audio_voice_notes(shop_id, entity_type, entity_id);
create index if not exists idx_audio_notes_created on public.audio_voice_notes(shop_id, created_at desc);

-- 7k. CUSTOMER_LOYALTY_REBATES (گاہک رعایت، والیم بونس اور سالانہ انعامات)
create table if not exists public.customer_loyalty_rebates (
  id                          uuid primary key default gen_random_uuid(),
  shop_id                     uuid not null references public.shops(id) on delete cascade,
  customer_id                 uuid not null references public.customers(id) on delete cascade,
  customer_name               text not null default '',
  customer_phone              text not null default '',
  program_name                text not null default 'Seasonal Volume Rebate',
  season_year                 text not null default '',
  qualifying_maunds           numeric(12,2) not null default 0,
  qualifying_turnover_pkr     numeric(14,2) not null default 0,
  tier_level                  text not null default 'standard', -- standard, silver, gold, platinum
  rebate_percentage           numeric(5,2) not null default 0,
  rebate_amount_pkr           numeric(12,2) not null default 0,
  credit_note_number          text not null default '',
  status                      text not null default 'accruing', -- accruing, approved, credited, cancelled
  credited_at                 timestamptz,
  notes                       text not null default '',
  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now()
);

create index if not exists idx_customer_rebates_shop on public.customer_loyalty_rebates(shop_id);
create index if not exists idx_customer_rebates_customer on public.customer_loyalty_rebates(shop_id, customer_id);
create index if not exists idx_customer_rebates_status on public.customer_loyalty_rebates(shop_id, status);
create index if not exists idx_customer_rebates_created on public.customer_loyalty_rebates(shop_id, created_at desc);

-- 7l. MANDI_COMMODITY_RATES (منڈی روزانہ ریٹ لسٹ اور براڈکاسٹ)
create table if not exists public.mandi_commodity_rates (
  id                          uuid primary key default gen_random_uuid(),
  shop_id                     uuid not null references public.shops(id) on delete cascade,
  commodity_name              text not null default '',
  variety                     text not null default '', -- e.g. "Super Kernel", "Kisan 1121", "Desi"
  rate_date                   date not null default current_date,
  min_rate_per_maund          numeric(12,2) not null default 0,
  max_rate_per_maund          numeric(12,2) not null default 0,
  modal_rate_per_maund        numeric(12,2) not null default 0,
  previous_modal_rate         numeric(12,2) not null default 0,
  price_change_pkr            numeric(10,2) not null default 0,
  price_change_percent        numeric(5,2) not null default 0,
  market_trend                text not null default 'stable', -- bullish, bearish, stable
  arrivals_maunds             numeric(10,2) not null default 0,
  quality_grade               text not null default 'Grade A',
  notes                       text not null default '',
  broadcast_sent_at           timestamptz,
  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now()
);

create index if not exists idx_commodity_rates_shop on public.mandi_commodity_rates(shop_id);
create index if not exists idx_commodity_rates_date on public.mandi_commodity_rates(shop_id, rate_date desc);
create index if not exists idx_commodity_rates_name on public.mandi_commodity_rates(shop_id, commodity_name);

-- 7m. STAFF_ATTENDANCE & PAYROLL (عملہ حاضری اور تنخواہ کھاتہ)
create table if not exists public.staff_attendance (
  id                          uuid primary key default gen_random_uuid(),
  shop_id                     uuid not null references public.shops(id) on delete cascade,
  member_id                   uuid not null references public.shop_memberships(id) on delete cascade,
  staff_name                  text not null default '',
  attendance_date             date not null default current_date,
  status                      text not null default 'present', -- present, absent, half_day, leave
  check_in_time               timestamptz,
  check_out_time              timestamptz,
  overtime_hours              numeric(4,2) not null default 0,
  notes                       text not null default '',
  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now(),
  constraint uq_staff_daily_att unique(shop_id, member_id, attendance_date)
);

create index if not exists idx_attendance_shop on public.staff_attendance(shop_id);
create index if not exists idx_attendance_member on public.staff_attendance(shop_id, member_id);
create index if not exists idx_attendance_date on public.staff_attendance(shop_id, attendance_date desc);

create table if not exists public.staff_payroll (
  id                          uuid primary key default gen_random_uuid(),
  shop_id                     uuid not null references public.shops(id) on delete cascade,
  member_id                   uuid not null references public.shop_memberships(id) on delete cascade,
  staff_name                  text not null default '',
  month_year                  text not null default '', -- e.g. "November 2026"
  base_monthly_salary         numeric(12,2) not null default 0,
  days_present                integer not null default 0,
  days_absent                 integer not null default 0,
  days_half_day               integer not null default 0,
  overtime_hours              numeric(6,2) not null default 0,
  overtime_allowance_pkr      numeric(12,2) not null default 0,
  bonus_incentive_pkr         numeric(12,2) not null default 0,
  advance_salary_deduction_pkr numeric(12,2) not null default 0,
  absentee_deduction_pkr      numeric(12,2) not null default 0,
  net_payable_salary_pkr      numeric(12,2) not null default 0,
  status                      text not null default 'draft', -- draft, approved, paid
  payment_method              text not null default 'cash', -- cash, bank_transfer, cheque
  paid_at                     timestamptz,
  voucher_number              text not null default '',
  notes                       text not null default '',
  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now()
);

create index if not exists idx_payroll_shop on public.staff_payroll(shop_id);
create index if not exists idx_payroll_member on public.staff_payroll(shop_id, member_id);
create index if not exists idx_payroll_month on public.staff_payroll(shop_id, month_year);
create index if not exists idx_payroll_status on public.staff_payroll(shop_id, status);

-- ============================================================================
-- 8. RPC — create_shop_with_owner
--    Atomically creates a shop, its 5 default roles, and the owner's
--    membership. Runs as the calling user (not security definer) because
--    every insert here is something the authenticated user is allowed to
--    do to their OWN new shop — no elevated privilege needed, unlike staff/
--    customer/supplier creation which requires Edge Functions (see below).
-- ============================================================================
create or replace function public.create_shop_with_owner(
  p_shop            jsonb,
  p_owner_name      text,
  p_owner_phone     text,
  p_owner_email     text,
  p_default_roles   jsonb  -- [{id, name, is_default, permissions}, ...]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_shop_id uuid;
  r jsonb;
begin
  insert into public.shops (
    name, logo_url, business_types, phone, whatsapp, email, address, city, district,
    province, default_weight_unit, default_commission_percent, invoice_prefix,
    invoice_next_number, receipt_prefix, receipt_next_number, currency,
    status, setup_complete, owner_id
  )
  select
    p_shop->>'name',
    nullif(p_shop->>'logoUrl', ''),
    coalesce((select array_agg(x) from jsonb_array_elements_text(p_shop->'businessTypes') x), '{}'),
    p_shop->>'phone', p_shop->>'whatsapp', p_shop->>'email', p_shop->>'address',
    p_shop->>'city', p_shop->>'district', p_shop->>'province',
    coalesce(p_shop->>'defaultWeightUnit', '40kg'),
    coalesce((p_shop->>'defaultCommissionPercent')::numeric, 0),
    coalesce(p_shop->>'invoicePrefix', 'INV'), 1,
    coalesce(p_shop->>'receiptPrefix', 'RCPT'), 1,
    coalesce(p_shop->>'currency', 'PKR'),
    coalesce(p_shop->>'status', 'active'),
    coalesce((p_shop->>'setupComplete')::boolean, true),
    auth.uid()
  returning id into v_shop_id;

  for r in select * from jsonb_array_elements(p_default_roles) loop
    insert into public.roles (id, shop_id, name, is_default, permissions)
    values (
      r->>'id', v_shop_id, r->>'name',
      coalesce((r->>'isDefault')::boolean, false),
      coalesce((select array_agg(x) from jsonb_array_elements_text(r->'permissions') x), '{}')
    );
  end loop;

  insert into public.shop_memberships (
    user_id, shop_id, role_id, name, phone, email, status
  ) values (
    auth.uid(), v_shop_id, 'owner', p_owner_name, p_owner_phone, p_owner_email, 'active'
  );

  return v_shop_id;
end;
$$;

-- ============================================================================
-- 8b. RPC — create_invoice_with_stock_deduction
--    Atomically inserts an invoice + its line items and deducts stock,
--    refusing the whole operation if any product doesn't have enough —
--    Postgres's equivalent of the old Firestore transaction. `for update`
--    row-locks each product for the duration of this function call, so two
--    simultaneous sales can't both read the same stock level and both
--    succeed in over-selling it.
-- ============================================================================
create or replace function public.create_invoice_with_stock_deduction(
  p_invoice jsonb,       -- {shopId, customerId, invoiceNumber, subtotal, commission, expenses, discount, total, receivedAmount, pendingAmount, paymentMethod}
  p_items   jsonb        -- [{productId, quantity, weightKg, unitPrice, lineTotal, changeKg}, ...]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invoice_id uuid;
  v_shop_id uuid := (p_invoice->>'shopId')::uuid;
  item jsonb;
  v_current numeric;
  v_change numeric;
  v_new_stock numeric;
begin
  if not public.has_permission(v_shop_id, 'create_invoice') then
    raise exception 'Missing permission: create_invoice';
  end if;

  for item in select * from jsonb_array_elements(p_items) loop
    select current_stock into v_current from public.products
      where id = (item->>'productId')::uuid and shop_id = v_shop_id
      for update; -- lock this product row until the transaction commits

    if v_current is null then
      raise exception 'Product % not found in this shop', item->>'productId';
    end if;

    v_change := (item->>'changeKg')::numeric; -- negative for a sale
    v_new_stock := v_current + v_change;
    if v_new_stock < 0 then
      raise exception 'Insufficient stock for product %', item->>'productId';
    end if;

    update public.products set current_stock = v_new_stock, updated_at = now()
      where id = (item->>'productId')::uuid;
  end loop;

  insert into public.invoices (
    shop_id, customer_id, supplier_id, invoice_number, subtotal, commission,
    expenses, discount, total, received_amount, pending_amount,
    supplier_payout, payment_method, created_by
  ) values (
    v_shop_id,
    nullif(p_invoice->>'customerId','')::uuid,
    nullif(p_invoice->>'supplierId','')::uuid,
    p_invoice->>'invoiceNumber',
    coalesce((p_invoice->>'subtotal')::numeric, 0),
    coalesce((p_invoice->>'commission')::numeric, 0),
    coalesce((p_invoice->>'expenses')::numeric, 0),
    coalesce((p_invoice->>'discount')::numeric, 0),
    coalesce((p_invoice->>'total')::numeric, 0),
    coalesce((p_invoice->>'receivedAmount')::numeric, 0),
    coalesce((p_invoice->>'pendingAmount')::numeric, 0),
    coalesce((p_invoice->>'supplierPayout')::numeric, 0),
    coalesce(p_invoice->>'paymentMethod', 'cash'),
    auth.uid()
  ) returning id into v_invoice_id;

  update public.shops
    set invoice_next_number = invoice_next_number + 1, updated_at = now()
    where id = v_shop_id;

  for item in select * from jsonb_array_elements(p_items) loop
    insert into public.invoice_items (
      invoice_id, shop_id, product_id, quantity, weight_kg, unit_price, line_total
    ) values (
      v_invoice_id, v_shop_id, (item->>'productId')::uuid,
      coalesce((item->>'quantity')::numeric, 0),
      coalesce((item->>'weightKg')::numeric, 0),
      coalesce((item->>'unitPrice')::numeric, 0),
      coalesce((item->>'lineTotal')::numeric, 0)
    );

    insert into public.inventory_transactions (
      shop_id, product_id, change_kg, type, reference, created_by
    ) values (
      v_shop_id, (item->>'productId')::uuid, (item->>'changeKg')::numeric,
      'sale', v_invoice_id::text, auth.uid()
    );
  end loop;

  -- Customer Khata: credit the pending amount atomically. A plain UPDATE
  -- takes a row lock for the statement's duration, so two simultaneous
  -- invoices for the same customer can't read-then-write and clobber each
  -- other — this replaces a separate client-side select-then-update that
  -- had exactly that race (and silently swallowed any failure).
  if nullif(p_invoice->>'customerId','') is not null
     and coalesce((p_invoice->>'pendingAmount')::numeric, 0) > 0 then
    update public.customers
      set running_balance = running_balance + (p_invoice->>'pendingAmount')::numeric
      where id = (p_invoice->>'customerId')::uuid and shop_id = v_shop_id;
  end if;

  -- Supplier consignment payout: same atomicity fix, for the net amount
  -- owed to the supplier on a consignment sale.
  if nullif(p_invoice->>'supplierId','') is not null
     and coalesce((p_invoice->>'supplierPayout')::numeric, 0) > 0 then
    update public.suppliers
      set running_balance = running_balance + (p_invoice->>'supplierPayout')::numeric
      where id = (p_invoice->>'supplierId')::uuid and shop_id = v_shop_id;
  end if;

  return v_invoice_id;
end;
$$;

-- ============================================================================
-- 8c. RPC — cancel_invoice_and_restore_stock
--    Cancels an invoice (status='void'), restores product stock,
--    reverses running balance on customer/supplier, and logs audit record.
-- ============================================================================
create or replace function public.cancel_invoice_and_restore_stock(
  p_invoice_id uuid,
  p_shop_id uuid,
  p_actor_id text,
  p_actor_name text,
  p_reason text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invoice record;
  item record;
begin
  if not public.has_permission(p_shop_id, 'create_invoice') then
    raise exception 'Missing permission: create_invoice';
  end if;

  select * into v_invoice from public.invoices
    where id = p_invoice_id and shop_id = p_shop_id
    for update;

  if v_invoice is null then
    raise exception 'Invoice not found';
  end if;

  if v_invoice.status = 'void' or v_invoice.status = 'cancelled' then
    raise exception 'Invoice is already cancelled';
  end if;

  -- 1. Restore product stock for each line item
  for item in select * from public.invoice_items where invoice_id = p_invoice_id loop
    update public.products
      set current_stock = current_stock + item.weight_kg, updated_at = now()
      where id = item.product_id and shop_id = p_shop_id;
  end loop;

  -- 2. Reverse running balance on customer if pending amount was added
  if v_invoice.customer_id is not null and v_invoice.pending_amount > 0 then
    update public.customers
      set running_balance = running_balance - v_invoice.pending_amount
      where id = v_invoice.customer_id and shop_id = p_shop_id;
  end if;

  -- 3. Reverse running balance on supplier — by supplier_payout, the
  --    amount actually credited at creation time (see
  --    create_invoice_with_stock_deduction).
  if v_invoice.supplier_id is not null and v_invoice.supplier_payout > 0 then
    update public.suppliers
      set running_balance = running_balance - v_invoice.supplier_payout
      where id = v_invoice.supplier_id and shop_id = p_shop_id;
  end if;

  -- 4. Mark invoice status as void
  update public.invoices
    set status = 'void', updated_at = now()
    where id = p_invoice_id and shop_id = p_shop_id;

  -- 5. Add audit log entry
  insert into public.audit_logs (
    shop_id, actor_id, actor_name, action, entity_type, entity_id, summary
  ) values (
    p_shop_id, p_actor_id, p_actor_name, 'invoice_cancelled', 'invoice', p_invoice_id::text,
    p_actor_name || ' cancelled invoice #' || v_invoice.invoice_number || '. Reason: ' || coalesce(p_reason, 'None')
  );
end;
$$;

-- ============================================================================
-- 8d. RPC — record_payment
--    Replaces SupabaseService.addPayment's old two-step client-side
--    pattern (insert the payment row, then separately select-then-update
--    running_balance). That pattern had two real bugs:
--      1. No lock between the select and the update, so two near-
--         simultaneous payments for the same customer/supplier could
--         read the same starting balance and the slower write would be
--         lost — a payment that silently never reduced what's owed.
--      2. The balance update ran as the calling user, subject to RLS's
--         "manage_customers"/"manage_suppliers can write" policy — NOT
--         "create_receipt", the permission that actually gates this
--         action. A member with create_receipt but not manage_customers
--         (explicitly supported via shop_memberships.custom_permissions,
--         see role_model.dart) would have the payment insert succeed and
--         the balance update silently affect zero rows: PostgREST does
--         not raise an error when RLS blocks an UPDATE, it just updates
--         nothing. The payment would exist with no visible error, and
--         the ledger would quietly be wrong.
--    security definer + checking has_permission(shop_id,'create_receipt')
--    directly fixes both: one atomic statement (a plain UPDATE takes a
--    row lock for its duration — no explicit FOR UPDATE needed), and the
--    right permission is what's actually enforced.
-- ============================================================================
create or replace function public.record_payment(
  p_payment jsonb  -- {shopId, partyType, partyId, amount, method, reference}
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment_id uuid;
  v_shop_id uuid := (p_payment->>'shopId')::uuid;
  v_party_type text := p_payment->>'partyType';
  v_party_id uuid := (p_payment->>'partyId')::uuid;
  v_amount numeric := coalesce((p_payment->>'amount')::numeric, 0);
begin
  if not public.has_permission(v_shop_id, 'create_receipt') then
    raise exception 'Missing permission: create_receipt';
  end if;

  if v_amount <= 0 then
    raise exception 'Payment amount must be greater than zero';
  end if;

  if v_party_type not in ('customer', 'supplier') then
    raise exception 'Unknown party_type: %', v_party_type;
  end if;

  insert into public.payments (
    shop_id, party_type, party_id, amount, method, reference, created_by
  ) values (
    v_shop_id, v_party_type, v_party_id, v_amount,
    coalesce(p_payment->>'method', 'cash'),
    p_payment->>'reference',
    auth.uid()
  ) returning id into v_payment_id;

  if v_party_type = 'customer' then
    update public.customers
      set running_balance = running_balance - v_amount
      where id = v_party_id and shop_id = v_shop_id;
  else
    update public.suppliers
      set running_balance = running_balance - v_amount
      where id = v_party_id and shop_id = v_shop_id;
  end if;

  insert into public.audit_logs (
    shop_id, actor_id, action, entity_type, entity_id, summary
  ) values (
    v_shop_id, auth.uid(), 'payment_recorded', 'payment', v_payment_id::text,
    'Recorded a ' || coalesce(p_payment->>'method', 'cash') || ' payment of ' ||
      v_amount::text || ' for ' || v_party_type || ' ' || v_party_id::text
  );

  return v_payment_id;
end;
$$;

-- ============================================================================
-- 8e. RPC — create_purchase_order_with_stock_addition
--    Atomically creates a purchase order, increments product stock using
--    row-locking (FOR UPDATE), records an inventory_transaction, and credits
--    the supplier running balance. Replaces client-side non-atomic sequence.
-- ============================================================================
create or replace function public.create_purchase_order_with_stock_addition(
  p_po jsonb -- {shopId, supplierId, productId, weightKg, ratePer40kg, total, paidAmount, pendingAmount, status}
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_po_id uuid;
  v_shop_id uuid := (p_po->>'shopId')::uuid;
  v_supplier_id uuid := nullif(p_po->>'supplierId', '')::uuid;
  v_product_id uuid := nullif(p_po->>'productId', '')::uuid;
  v_weight_kg numeric := coalesce((p_po->>'weightKg')::numeric, 0);
  v_rate numeric := coalesce((p_po->>'ratePer40kg')::numeric, 0);
  v_total numeric := coalesce((p_po->>'total')::numeric, 0);
  v_paid numeric := coalesce((p_po->>'paidAmount')::numeric, 0);
  v_pending numeric := coalesce((p_po->>'pendingAmount')::numeric, v_total - v_paid);
  v_status text := coalesce(p_po->>'status', 'received');
  v_current_stock numeric;
begin
  if not public.has_permission(v_shop_id, 'create_purchase') then
    raise exception 'Missing permission: create_purchase';
  end if;

  if v_total < 0 or v_paid < 0 or v_pending < 0 then
    raise exception 'Amounts cannot be negative';
  end if;

  insert into public.purchase_orders (
    shop_id, supplier_id, status, total, paid_amount, pending_amount, created_by
  ) values (
    v_shop_id, v_supplier_id, v_status, v_total, v_paid, v_pending, auth.uid()
  ) returning id into v_po_id;

  -- If status is received, atomically increase product stock and log inventory txn
  if v_status = 'received' and v_product_id is not null and v_weight_kg > 0 then
    select current_stock into v_current_stock from public.products
      where id = v_product_id and shop_id = v_shop_id
      for update;

    if v_current_stock is not null then
      update public.products
        set current_stock = current_stock + v_weight_kg,
            purchase_price = case when v_rate > 0 then v_rate else purchase_price end,
            updated_at = now()
        where id = v_product_id and shop_id = v_shop_id;

      insert into public.inventory_transactions (
        shop_id, product_id, change_kg, type, reference, created_by
      ) values (
        v_shop_id, v_product_id, v_weight_kg, 'purchase', v_po_id::text, auth.uid()
      );
    end if;
  end if;

  -- Atomically update supplier's running balance with row lock
  if v_supplier_id is not null and v_pending > 0 then
    update public.suppliers
      set running_balance = running_balance + v_pending
      where id = v_supplier_id and shop_id = v_shop_id;
  end if;

  insert into public.audit_logs (
    shop_id, actor_id, action, entity_type, entity_id, summary
  ) values (
    v_shop_id, auth.uid(), 'purchase_order_created', 'purchase_order', v_po_id::text,
    'Recorded purchase order #' || v_po_id::text || ' for Rs. ' || v_total::text
  );

  return v_po_id;
end;
$$;

-- Trigger to prevent self-privilege escalation on shop_memberships
create or replace function public.check_shop_membership_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- If caller lacks manage_employees, strictly block alterations to sensitive fields
  if not public.has_permission(OLD.shop_id, 'manage_employees') then
    if NEW.role_id is distinct from OLD.role_id then
      raise exception 'Cannot modify role_id without manage_employees permission';
    end if;
    if NEW.custom_permissions is distinct from OLD.custom_permissions then
      raise exception 'Cannot modify custom_permissions without manage_employees permission';
    end if;
    if NEW.status is distinct from OLD.status then
      raise exception 'Cannot modify membership status without manage_employees permission';
    end if;
    if NEW.salary is distinct from OLD.salary then
      raise exception 'Cannot modify salary without manage_employees permission';
    end if;
    if NEW.shop_id is distinct from OLD.shop_id or NEW.user_id is distinct from OLD.user_id then
      raise exception 'Cannot reassign shop or user';
    end if;
  end if;
  NEW.updated_at := now();
  return NEW;
end;
$$;

drop trigger if exists trg_check_shop_membership_update on public.shop_memberships;
create trigger trg_check_shop_membership_update
  before update on public.shop_memberships
  for each row execute function public.check_shop_membership_update();

-- ============================================================================
-- 9. ROW LEVEL SECURITY
-- ============================================================================
alter table public.profiles              enable row level security;
alter table public.shops                 enable row level security;
alter table public.roles                 enable row level security;
alter table public.shop_memberships      enable row level security;
alter table public.invitations           enable row level security;
alter table public.audit_logs            enable row level security;
alter table public.products              enable row level security;
alter table public.customers             enable row level security;
alter table public.suppliers             enable row level security;
alter table public.invoices              enable row level security;
alter table public.invoice_items         enable row level security;
alter table public.purchase_orders       enable row level security;
alter table public.inventory_transactions enable row level security;
alter table public.expenses              enable row level security;
alter table public.payments              enable row level security;
alter table public.notifications         enable row level security;
alter table public.consignment_lots       enable row level security;
alter table public.bank_accounts          enable row level security;
alter table public.cheques                enable row level security;
alter table public.storage_locations      enable row level security;
alter table public.storage_allocations    enable row level security;
alter table public.bardana_transactions   enable row level security;
alter table public.weighbridge_tickets    enable row level security;
alter table public.farmer_advances        enable row level security;
alter table public.farmer_advance_recoveries enable row level security;
alter table public.cross_border_shipments enable row level security;
alter table public.sms_gateway_settings   enable row level security;
alter table public.sms_logs               enable row level security;
alter table public.inter_shop_transfers   enable row level security;

-- profiles: read your own; owners can read profiles of people they've
-- invited into one of their shops (needed to show staff/customer/supplier
-- lists with names).
drop policy if exists "profiles: read own" on public.profiles;
create policy "profiles: read own" on public.profiles
  for select using (id = auth.uid());

drop policy if exists "profiles: manage_employees can read shop-mates" on public.profiles;
create policy "profiles: manage_employees can read shop-mates" on public.profiles
  for select using (
    exists (
      select 1 from public.shop_memberships m1
      join public.shop_memberships m2 on m1.shop_id = m2.shop_id
      where m1.user_id = auth.uid() and m1.status = 'active'
        and public.has_permission(m1.shop_id, 'manage_employees')
        and m2.user_id = profiles.id and m2.status = 'active'
    )
  );

drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: update own" on public.profiles
  for update using (id = auth.uid());

-- shops: any active member can read their shop; only the owner updates it.
drop policy if exists "shops: members can read" on public.shops;
create policy "shops: members can read" on public.shops
  for select using (public.is_shop_member(id));

drop policy if exists "shops: owner can update" on public.shops;
create policy "shops: owner can update" on public.shops
  for update using (owner_id = auth.uid());

drop policy if exists "shops: authenticated users can create" on public.shops;
create policy "shops: authenticated users can create" on public.shops
  for insert with check (owner_id = auth.uid());

-- roles: any active member can read; only manage_roles permission can write.
drop policy if exists "roles: members can read" on public.roles;
create policy "roles: members can read" on public.roles
  for select using (public.is_shop_member(shop_id));

drop policy if exists "roles: manage_roles can write" on public.roles;
create policy "roles: manage_roles can write" on public.roles
  for all using (public.has_permission(shop_id, 'manage_roles'))
  with check (public.has_permission(shop_id, 'manage_roles'));

-- shop_memberships: you can read your own memberships (any shop) and every
-- membership in a shop you belong to (to show the staff/customer list).
drop policy if exists "memberships: read own" on public.shop_memberships;
create policy "memberships: read own" on public.shop_memberships
  for select using (user_id = auth.uid());

drop policy if exists "memberships: manage_employees can read the roster" on public.shop_memberships;
drop policy if exists "memberships: shop staff can read roster" on public.shop_memberships;
create policy "memberships: shop staff can read roster" on public.shop_memberships
  for select using (
    public.has_permission(shop_id, 'manage_employees') or
    public.has_permission(shop_id, 'manage_customers') or
    public.has_permission(shop_id, 'manage_suppliers')
  );

drop policy if exists "memberships: manage_employees can write" on public.shop_memberships;
create policy "memberships: manage_employees can write" on public.shop_memberships
  for update using (public.has_permission(shop_id, 'manage_employees'))
  with check (public.has_permission(shop_id, 'manage_employees'));

drop policy if exists "memberships: update own" on public.shop_memberships;
create policy "memberships: update own" on public.shop_memberships
  for update using (user_id = auth.uid());

-- Inserts for staff/customer/supplier go through Edge Functions using the
-- service role (bypasses RLS by design — see supabase/functions/). The one
-- client-side insert allowed here is the OWNER's own membership, created
-- inside create_shop_with_owner() above (security invoker, so this policy
-- still applies — it's allowed because user_id = auth.uid() there).
drop policy if exists "memberships: self-insert only" on public.shop_memberships;
create policy "memberships: self-insert only" on public.shop_memberships
  for insert with check (user_id = auth.uid());

-- invitations: owner/managers of the shop can read; writes are Edge-Function-only.
drop policy if exists "invitations: shop managers can read" on public.invitations;
create policy "invitations: shop managers can read" on public.invitations
  for select using (public.has_permission(shop_id, 'manage_employees'));

-- audit_logs: append-only, readable by any active member of the shop.
drop policy if exists "audit_logs: members can read" on public.audit_logs;
create policy "audit_logs: members can read" on public.audit_logs
  for select using (public.is_shop_member(shop_id));

drop policy if exists "audit_logs: members can insert" on public.audit_logs;
create policy "audit_logs: members can insert" on public.audit_logs
  for insert with check (public.is_shop_member(shop_id) and (actor_id is null or actor_id = auth.uid()));

-- Generic pattern for every remaining shop-owned business table: readable
-- by any active member, writable only with the matching permission.
drop policy if exists "products: members can read" on public.products;
create policy "products: members can read" on public.products
  for select using (public.is_shop_member(shop_id));

-- Restored: this had regressed to is_shop_member-only (the comment above
-- still described the intended "writable only with the matching
-- permission" behavior, but the policy itself no longer enforced it) —
-- any active shop member, including a customer or supplier role with no
-- permissions at all, could create, edit, or delete products.
drop policy if exists "products: manage_products can write" on public.products;
drop policy if exists "products: members can write" on public.products;
create policy "products: manage_products can write" on public.products
  for all using (public.has_permission(shop_id, 'manage_products'))
  with check (public.has_permission(shop_id, 'manage_products'));

-- customers: staff can read shop customers; customers can strictly read only their own record
drop policy if exists "customers: members can read" on public.customers;
drop policy if exists "customers: staff can read" on public.customers;
create policy "customers: staff can read" on public.customers
  for select using (
    public.has_permission(shop_id, 'manage_customers') or
    public.has_permission(shop_id, 'create_invoice') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'create_receipt') or
    public.has_permission(shop_id, 'manage_employees') or
    user_id = auth.uid()
  );

-- Restored: same regression as products above — any active shop member,
-- including a customer themselves, could edit or delete ANY customer
-- record in the shop (their own or someone else's).
drop policy if exists "customers: manage_customers can write" on public.customers;
drop policy if exists "customers: members can write" on public.customers;
create policy "customers: manage_customers can write" on public.customers
  for all using (public.has_permission(shop_id, 'manage_customers'))
  with check (public.has_permission(shop_id, 'manage_customers'));

drop policy if exists "customers: self read" on public.customers;
create policy "customers: self read" on public.customers
  for select using (user_id = auth.uid());

-- suppliers: staff can read shop suppliers; suppliers can strictly read only their own record
drop policy if exists "suppliers: members can read" on public.suppliers;
drop policy if exists "suppliers: staff can read" on public.suppliers;
create policy "suppliers: staff can read" on public.suppliers
  for select using (
    public.has_permission(shop_id, 'manage_suppliers') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'create_receipt') or
    public.has_permission(shop_id, 'manage_employees') or
    user_id = auth.uid()
  );

-- Restored: same regression as products/customers above — any active
-- shop member, including a supplier themselves, could edit or delete
-- ANY supplier record in the shop.
drop policy if exists "suppliers: manage_suppliers can write" on public.suppliers;
drop policy if exists "suppliers: members can write" on public.suppliers;
create policy "suppliers: manage_suppliers can write" on public.suppliers
  for all using (public.has_permission(shop_id, 'manage_suppliers'))
  with check (public.has_permission(shop_id, 'manage_suppliers'));

drop policy if exists "suppliers: self read" on public.suppliers;
create policy "suppliers: self read" on public.suppliers
  for select using (user_id = auth.uid());

drop policy if exists "invoices: members can read" on public.invoices;
create policy "invoices: members can read" on public.invoices
  for select using (
    public.has_permission(shop_id, 'create_invoice') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'manage_employees') or
    customer_id in (select id from public.customers where user_id = auth.uid()) or
    customer_id in (select id from public.shop_memberships where user_id = auth.uid())
  );

-- No direct client INSERT/UPDATE/DELETE on invoices or invoice_items.
-- Invoices are created exclusively through create_invoice_with_stock_deduction RPC
-- and cancelled through cancel_invoice_and_restore_stock RPC.
drop policy if exists "invoices: create_invoice can write" on public.invoices;
drop policy if exists "invoice_items: create_invoice can write" on public.invoice_items;

drop policy if exists "invoice_items: members can read" on public.invoice_items;
create policy "invoice_items: members can read" on public.invoice_items
  for select using (public.is_shop_member(shop_id));

drop policy if exists "purchase_orders: members can read" on public.purchase_orders;
create policy "purchase_orders: members can read" on public.purchase_orders
  for select using (
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'manage_suppliers') or
    public.has_permission(shop_id, 'manage_employees') or
    supplier_id in (select id from public.suppliers where user_id = auth.uid()) or
    supplier_id in (select id from public.shop_memberships where user_id = auth.uid())
  );

-- No direct client INSERT/UPDATE/DELETE on purchase_orders.
-- Purchase orders are created exclusively through create_purchase_order_with_stock_addition RPC.
drop policy if exists "purchase_orders: create_purchase can write" on public.purchase_orders;

drop policy if exists "inventory_txn: members can read" on public.inventory_transactions;
create policy "inventory_txn: members can read" on public.inventory_transactions
  for select using (public.is_shop_member(shop_id));

drop policy if exists "inventory_txn: manage_inventory can write" on public.inventory_transactions;
create policy "inventory_txn: manage_inventory can write" on public.inventory_transactions
  for all using (public.has_permission(shop_id, 'manage_inventory'))
  with check (public.has_permission(shop_id, 'manage_inventory'));

drop policy if exists "expenses: members can read" on public.expenses;
create policy "expenses: members can read" on public.expenses
  for select using (public.is_shop_member(shop_id));

drop policy if exists "expenses: manage_expenses can write" on public.expenses;
create policy "expenses: manage_expenses can write" on public.expenses
  for all using (public.has_permission(shop_id, 'manage_expenses'))
  with check (public.has_permission(shop_id, 'manage_expenses'));

drop policy if exists "payments: members can read" on public.payments;
create policy "payments: members can read" on public.payments
  for select using (
    public.has_permission(shop_id, 'create_receipt') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'manage_employees') or
    party_id in (select id from public.customers where user_id = auth.uid()) or
    party_id in (select id from public.suppliers where user_id = auth.uid()) or
    party_id in (select id from public.shop_memberships where user_id = auth.uid())
  );

-- No INSERT/UPDATE/DELETE policy on this table at all, intentionally.
-- Payments are created exclusively through the record_payment RPC
-- (security definer, checks has_permission(shop_id,'create_receipt')
-- itself and bypasses RLS to do its one atomic insert-plus-balance-
-- update). Dropping the old write policy closes a real hole: it only
-- checked is_shop_member, so any active member of the shop — including
-- a customer or supplier role, which gets no permissions by default —
-- could previously insert, edit, or delete any payment record, their
-- own or anyone else's, with no permission or ownership check at all.
drop policy if exists "payments: create_receipt can write" on public.payments;
drop policy if exists "payments: members can write" on public.payments;

drop policy if exists "notifications: recipient can read" on public.notifications;
create policy "notifications: recipient can read" on public.notifications
  for select using (user_id = auth.uid());

drop policy if exists "notifications: recipient can mark read" on public.notifications;
create policy "notifications: recipient can mark read" on public.notifications
  for update using (user_id = auth.uid());

drop policy if exists "notifications: members can insert for their shop" on public.notifications;
create policy "notifications: members can insert for their shop" on public.notifications
  for insert with check (public.is_shop_member(shop_id));

drop policy if exists "consignment_lots: members can read" on public.consignment_lots;
create policy "consignment_lots: members can read" on public.consignment_lots
  for select using (
    public.is_shop_member(shop_id) or
    supplier_id in (select id from public.suppliers where user_id = auth.uid()) or
    winning_buyer_id in (select id from public.customers where user_id = auth.uid())
  );

drop policy if exists "consignment_lots: authorized staff can write" on public.consignment_lots;
create policy "consignment_lots: authorized staff can write" on public.consignment_lots
  for all using (
    public.has_permission(shop_id, 'manage_suppliers') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'create_invoice') or
    public.has_permission(shop_id, 'manage_employees')
  )
  with check (
    public.has_permission(shop_id, 'manage_suppliers') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'create_invoice') or
    public.has_permission(shop_id, 'manage_employees')
  );

drop policy if exists "bank_accounts: members can read" on public.bank_accounts;
create policy "bank_accounts: members can read" on public.bank_accounts
  for select using (public.is_shop_member(shop_id));

drop policy if exists "bank_accounts: authorized staff can write" on public.bank_accounts;
create policy "bank_accounts: authorized staff can write" on public.bank_accounts
  for all using (
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'create_receipt')
  )
  with check (
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'create_receipt')
  );

drop policy if exists "cheques: members can read" on public.cheques;
create policy "cheques: members can read" on public.cheques
  for select using (public.is_shop_member(shop_id));

drop policy if exists "cheques: authorized staff can write" on public.cheques;
create policy "cheques: authorized staff can write" on public.cheques
  for all using (
    public.has_permission(shop_id, 'create_receipt') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'create_purchase')
  )
  with check (
    public.has_permission(shop_id, 'create_receipt') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'create_purchase')
  );

drop policy if exists "storage_locations: members can read" on public.storage_locations;
create policy "storage_locations: members can read" on public.storage_locations
  for select using (public.is_shop_member(shop_id));

drop policy if exists "storage_locations: authorized staff can write" on public.storage_locations;
create policy "storage_locations: authorized staff can write" on public.storage_locations
  for all using (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'create_purchase')
  )
  with check (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'create_purchase')
  );

drop policy if exists "storage_allocations: members can read" on public.storage_allocations;
create policy "storage_allocations: members can read" on public.storage_allocations
  for select using (public.is_shop_member(shop_id));

drop policy if exists "storage_allocations: authorized staff can write" on public.storage_allocations;
create policy "storage_allocations: authorized staff can write" on public.storage_allocations
  for all using (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase')
  )
  with check (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase')
  );

drop policy if exists "bardana_transactions: members can read" on public.bardana_transactions;
create policy "bardana_transactions: members can read" on public.bardana_transactions
  for select using (
    public.is_shop_member(shop_id) or
    party_id in (select id from public.suppliers where user_id = auth.uid()) or
    party_id in (select id from public.customers where user_id = auth.uid())
  );

drop policy if exists "bardana_transactions: authorized staff can write" on public.bardana_transactions;
create policy "bardana_transactions: authorized staff can write" on public.bardana_transactions
  for all using (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'create_invoice') or
    public.has_permission(shop_id, 'view_ledger')
  )
  with check (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'create_invoice') or
    public.has_permission(shop_id, 'view_ledger')
  );

drop policy if exists "weighbridge_tickets: members can read" on public.weighbridge_tickets;
create policy "weighbridge_tickets: members can read" on public.weighbridge_tickets
  for select using (
    public.is_shop_member(shop_id) or
    party_id in (select id from public.suppliers where user_id = auth.uid()) or
    party_id in (select id from public.customers where user_id = auth.uid())
  );

drop policy if exists "weighbridge_tickets: authorized staff can write" on public.weighbridge_tickets;
create policy "weighbridge_tickets: authorized staff can write" on public.weighbridge_tickets
  for all using (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'create_invoice')
  )
  with check (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'create_invoice')
  );

drop policy if exists "farmer_advances: members can read" on public.farmer_advances;
create policy "farmer_advances: members can read" on public.farmer_advances
  for select using (
    public.is_shop_member(shop_id) or
    supplier_id in (select id from public.suppliers where user_id = auth.uid())
  );

drop policy if exists "farmer_advances: authorized staff can write" on public.farmer_advances;
create policy "farmer_advances: authorized staff can write" on public.farmer_advances
  for all using (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'view_ledger')
  )
  with check (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'view_ledger')
  );

drop policy if exists "farmer_advance_recoveries: members can read" on public.farmer_advance_recoveries;
create policy "farmer_advance_recoveries: members can read" on public.farmer_advance_recoveries
  for select using (public.is_shop_member(shop_id));

drop policy if exists "farmer_advance_recoveries: authorized staff can write" on public.farmer_advance_recoveries;
create policy "farmer_advance_recoveries: authorized staff can write" on public.farmer_advance_recoveries
  for all using (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'view_ledger')
  )
  with check (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'view_ledger')
  );

drop policy if exists "cross_border_shipments: members can read" on public.cross_border_shipments;
create policy "cross_border_shipments: members can read" on public.cross_border_shipments
  for select using (public.is_shop_member(shop_id));

drop policy if exists "cross_border_shipments: authorized staff can write" on public.cross_border_shipments;
create policy "cross_border_shipments: authorized staff can write" on public.cross_border_shipments
  for all using (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'manage_products')
  )
  with check (
    public.has_permission(shop_id, 'manage_inventory') or
    public.has_permission(shop_id, 'create_purchase') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'manage_products')
  );

drop policy if exists "sms_gateway_settings: members can read" on public.sms_gateway_settings;
create policy "sms_gateway_settings: members can read" on public.sms_gateway_settings
  for select using (public.is_shop_member(shop_id));

drop policy if exists "sms_gateway_settings: authorized staff can write" on public.sms_gateway_settings;
create policy "sms_gateway_settings: authorized staff can write" on public.sms_gateway_settings
  for all using (
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'create_receipt') or
    public.has_permission(shop_id, 'create_invoice')
  )
  with check (
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'create_receipt') or
    public.has_permission(shop_id, 'create_invoice')
  );

drop policy if exists "sms_logs: members can read" on public.sms_logs;
create policy "sms_logs: members can read" on public.sms_logs
  for select using (public.is_shop_member(shop_id));

drop policy if exists "sms_logs: members can write" on public.sms_logs;
create policy "sms_logs: members can write" on public.sms_logs
  for all using (public.is_shop_member(shop_id))
  with check (public.is_shop_member(shop_id));

drop policy if exists "inter_shop_transfers: members can read" on public.inter_shop_transfers;
create policy "inter_shop_transfers: members can read" on public.inter_shop_transfers
  for select using (
    public.is_shop_member(source_shop_id) or
    public.is_shop_member(destination_shop_id)
  );

drop policy if exists "inter_shop_transfers: members can write" on public.inter_shop_transfers;
create policy "inter_shop_transfers: members can write" on public.inter_shop_transfers
  for all using (
    public.is_shop_member(source_shop_id) or
    public.is_shop_member(destination_shop_id)
  )
  with check (
    public.is_shop_member(source_shop_id) or
    public.is_shop_member(destination_shop_id)
  );

drop policy if exists "audio_voice_notes: members can read" on public.audio_voice_notes;
create policy "audio_voice_notes: members can read" on public.audio_voice_notes
  for select using (public.is_shop_member(shop_id));

drop policy if exists "audio_voice_notes: members can write" on public.audio_voice_notes;
create policy "audio_voice_notes: members can write" on public.audio_voice_notes
  for all using (public.is_shop_member(shop_id))
  with check (public.is_shop_member(shop_id));

drop policy if exists "customer_loyalty_rebates: members can read" on public.customer_loyalty_rebates;
create policy "customer_loyalty_rebates: members can read" on public.customer_loyalty_rebates
  for select using (
    public.is_shop_member(shop_id) or
    customer_id in (select id from public.customers where user_id = auth.uid())
  );

drop policy if exists "customer_loyalty_rebates: authorized staff can write" on public.customer_loyalty_rebates;
create policy "customer_loyalty_rebates: authorized staff can write" on public.customer_loyalty_rebates
  for all using (
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'create_invoice') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'create_receipt')
  )
  with check (
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'create_invoice') or
    public.has_permission(shop_id, 'view_ledger') or
    public.has_permission(shop_id, 'create_receipt')
  );

drop policy if exists "mandi_commodity_rates: members can read" on public.mandi_commodity_rates;
create policy "mandi_commodity_rates: members can read" on public.mandi_commodity_rates
  for select using (public.is_shop_member(shop_id));

drop policy if exists "mandi_commodity_rates: authorized staff can write" on public.mandi_commodity_rates;
create policy "mandi_commodity_rates: authorized staff can write" on public.mandi_commodity_rates
  for all using (
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'manage_products') or
    public.has_permission(shop_id, 'create_invoice')
  )
  with check (
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'manage_products') or
    public.has_permission(shop_id, 'create_invoice')
  );

drop policy if exists "staff_attendance: members can read" on public.staff_attendance;
create policy "staff_attendance: members can read" on public.staff_attendance
  for select using (public.is_shop_member(shop_id));

drop policy if exists "staff_attendance: authorized staff can write" on public.staff_attendance;
create policy "staff_attendance: authorized staff can write" on public.staff_attendance
  for all using (
    public.has_permission(shop_id, 'manage_employees') or
    public.has_permission(shop_id, 'manage_settings')
  )
  with check (
    public.has_permission(shop_id, 'manage_employees') or
    public.has_permission(shop_id, 'manage_settings')
  );

drop policy if exists "staff_payroll: members can read" on public.staff_payroll;
create policy "staff_payroll: members can read" on public.staff_payroll
  for select using (public.is_shop_member(shop_id));

drop policy if exists "staff_payroll: authorized staff can write" on public.staff_payroll;
create policy "staff_payroll: authorized staff can write" on public.staff_payroll
  for all using (
    public.has_permission(shop_id, 'manage_employees') or
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'view_ledger')
  )
  with check (
    public.has_permission(shop_id, 'manage_employees') or
    public.has_permission(shop_id, 'manage_settings') or
    public.has_permission(shop_id, 'view_ledger')
  );

-- ============================================================================
-- 10. STORAGE BUCKETS
-- ============================================================================
insert into storage.buckets (id, name, public)
values
  ('shop-assets', 'shop-assets', true),
  ('product-images', 'product-images', true),
  ('avatars', 'avatars', true),
  ('documents', 'documents', false)
on conflict (id) do nothing;

-- Path convention for every bucket: {shop_id}/{filename} (avatars use
-- {user_id}/{filename} instead, since an avatar isn't shop-owned).
-- storage.foldername(name)[1] is the first path segment.

drop policy if exists "shop-assets: shop members can read" on storage.objects;
create policy "shop-assets: shop members can read"
  on storage.objects for select
  using (bucket_id = 'shop-assets' and public.is_shop_member((storage.foldername(name))[1]::uuid));

drop policy if exists "shop-assets: manage_settings can write" on storage.objects;
create policy "shop-assets: manage_settings can write"
  on storage.objects for insert
  with check (bucket_id = 'shop-assets' and public.has_permission((storage.foldername(name))[1]::uuid, 'manage_settings'));

drop policy if exists "shop-assets: manage_settings can update" on storage.objects;
create policy "shop-assets: manage_settings can update"
  on storage.objects for update
  using (bucket_id = 'shop-assets' and public.has_permission((storage.foldername(name))[1]::uuid, 'manage_settings'));

drop policy if exists "shop-assets: manage_settings can delete" on storage.objects;
create policy "shop-assets: manage_settings can delete"
  on storage.objects for delete
  using (bucket_id = 'shop-assets' and public.has_permission((storage.foldername(name))[1]::uuid, 'manage_settings'));

drop policy if exists "product-images: shop members can read" on storage.objects;
create policy "product-images: shop members can read"
  on storage.objects for select
  using (bucket_id = 'product-images' and public.is_shop_member((storage.foldername(name))[1]::uuid));

drop policy if exists "product-images: manage_products can write" on storage.objects;
create policy "product-images: manage_products can write"
  on storage.objects for insert
  with check (bucket_id = 'product-images' and public.has_permission((storage.foldername(name))[1]::uuid, 'manage_products'));

drop policy if exists "product-images: manage_products can update" on storage.objects;
create policy "product-images: manage_products can update"
  on storage.objects for update
  using (bucket_id = 'product-images' and public.has_permission((storage.foldername(name))[1]::uuid, 'manage_products'));

drop policy if exists "product-images: manage_products can delete" on storage.objects;
create policy "product-images: manage_products can delete"
  on storage.objects for delete
  using (bucket_id = 'product-images' and public.has_permission((storage.foldername(name))[1]::uuid, 'manage_products'));

drop policy if exists "avatars: anyone can read" on storage.objects;
create policy "avatars: anyone can read"
  on storage.objects for select using (bucket_id = 'avatars');

drop policy if exists "avatars: owner can write their own" on storage.objects;
create policy "avatars: owner can write their own"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars: owner can update their own" on storage.objects;
create policy "avatars: owner can update their own"
  on storage.objects for update
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents: shop members can read" on storage.objects;
create policy "documents: shop members can read"
  on storage.objects for select
  using (bucket_id = 'documents' and public.is_shop_member((storage.foldername(name))[1]::uuid));

drop policy if exists "documents: shop members can upload" on storage.objects;
create policy "documents: shop members can upload"
  on storage.objects for insert
  with check (bucket_id = 'documents' and public.is_shop_member((storage.foldername(name))[1]::uuid));

-- ============================================================================
-- Security test checklist (run these manually against two seeded shops):
--  1. Member of SHOP_001 can select SHOP_001 rows                → allow
--  2. Member of SHOP_001 selects SHOP_002 rows                   → empty set
--  3. Member of SHOP_001 tries to insert a row with shop_id =
--     SHOP_002 (simulating a tampered client value)              → denied
--  4. Customer role tries to read the full shop_memberships roster
--     (staff list) → denied, since that policy now requires
--     manage_employees; a customer can still read only their OWN
--     membership row via the separate "read own" policy
--  5. Deactivated membership (status='inactive') fails is_shop_member
--     and has_permission checks immediately, without a new login
-- ============================================================================

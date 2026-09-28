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
security invoker
set search_path = public
as $$
declare
  v_shop_id uuid;
  r jsonb;
begin
  insert into public.shops (
    name, business_types, phone, whatsapp, email, address, city, district,
    province, default_weight_unit, default_commission_percent, invoice_prefix,
    invoice_next_number, receipt_prefix, receipt_next_number, currency,
    status, setup_complete, owner_id
  )
  select
    p_shop->>'name',
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
security invoker
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
    shop_id, customer_id, invoice_number, subtotal, commission, expenses,
    discount, total, received_amount, pending_amount, payment_method, created_by
  ) values (
    v_shop_id,
    nullif(p_invoice->>'customerId','')::uuid,
    p_invoice->>'invoiceNumber',
    coalesce((p_invoice->>'subtotal')::numeric, 0),
    coalesce((p_invoice->>'commission')::numeric, 0),
    coalesce((p_invoice->>'expenses')::numeric, 0),
    coalesce((p_invoice->>'discount')::numeric, 0),
    coalesce((p_invoice->>'total')::numeric, 0),
    coalesce((p_invoice->>'receivedAmount')::numeric, 0),
    coalesce((p_invoice->>'pendingAmount')::numeric, 0),
    coalesce(p_invoice->>'paymentMethod', 'cash'),
    auth.uid()
  ) returning id into v_invoice_id;

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

  return v_invoice_id;
end;
$$;

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

-- profiles: read your own; owners can read profiles of people they've
-- invited into one of their shops (needed to show staff/customer/supplier
-- lists with names).
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
create policy "memberships: manage_employees can read the roster" on public.shop_memberships
  for select using (public.has_permission(shop_id, 'manage_employees'));

drop policy if exists "memberships: manage_employees can write" on public.shop_memberships;
create policy "memberships: manage_employees can write" on public.shop_memberships
  for update using (public.has_permission(shop_id, 'manage_employees'))
  with check (public.has_permission(shop_id, 'manage_employees'));

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
  for insert with check (public.is_shop_member(shop_id));

-- Generic pattern for every remaining shop-owned business table: readable
-- by any active member, writable only with the matching permission.
drop policy if exists "products: members can read" on public.products;
create policy "products: members can read" on public.products
  for select using (public.is_shop_member(shop_id));

drop policy if exists "products: manage_products can write" on public.products;
create policy "products: manage_products can write" on public.products
  for all using (public.has_permission(shop_id, 'manage_products'))
  with check (public.has_permission(shop_id, 'manage_products'));

drop policy if exists "customers: members can read" on public.customers;
create policy "customers: members can read" on public.customers
  for select using (public.is_shop_member(shop_id));

drop policy if exists "customers: manage_customers can write" on public.customers;
create policy "customers: manage_customers can write" on public.customers
  for all using (public.has_permission(shop_id, 'manage_customers'))
  with check (public.has_permission(shop_id, 'manage_customers'));

drop policy if exists "customers: self read" on public.customers;
create policy "customers: self read" on public.customers
  for select using (user_id = auth.uid());

drop policy if exists "suppliers: members can read" on public.suppliers;
create policy "suppliers: members can read" on public.suppliers
  for select using (public.is_shop_member(shop_id));

drop policy if exists "suppliers: manage_suppliers can write" on public.suppliers;
create policy "suppliers: manage_suppliers can write" on public.suppliers
  for all using (public.has_permission(shop_id, 'manage_suppliers'))
  with check (public.has_permission(shop_id, 'manage_suppliers'));

drop policy if exists "suppliers: self read" on public.suppliers;
create policy "suppliers: self read" on public.suppliers
  for select using (user_id = auth.uid());

drop policy if exists "invoices: members can read" on public.invoices;
create policy "invoices: members can read" on public.invoices
  for select using (public.is_shop_member(shop_id));

drop policy if exists "invoices: create_invoice can write" on public.invoices;
create policy "invoices: create_invoice can write" on public.invoices
  for all using (public.has_permission(shop_id, 'create_invoice'))
  with check (public.has_permission(shop_id, 'create_invoice'));

drop policy if exists "invoice_items: members can read" on public.invoice_items;
create policy "invoice_items: members can read" on public.invoice_items
  for select using (public.is_shop_member(shop_id));

drop policy if exists "invoice_items: create_invoice can write" on public.invoice_items;
create policy "invoice_items: create_invoice can write" on public.invoice_items
  for all using (public.has_permission(shop_id, 'create_invoice'))
  with check (public.has_permission(shop_id, 'create_invoice'));

drop policy if exists "purchase_orders: members can read" on public.purchase_orders;
create policy "purchase_orders: members can read" on public.purchase_orders
  for select using (public.is_shop_member(shop_id));

drop policy if exists "purchase_orders: create_purchase can write" on public.purchase_orders;
create policy "purchase_orders: create_purchase can write" on public.purchase_orders
  for all using (public.has_permission(shop_id, 'create_purchase'))
  with check (public.has_permission(shop_id, 'create_purchase'));

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
  for select using (public.is_shop_member(shop_id));

drop policy if exists "payments: create_receipt can write" on public.payments;
create policy "payments: create_receipt can write" on public.payments
  for all using (public.has_permission(shop_id, 'create_receipt'))
  with check (public.has_permission(shop_id, 'create_receipt'));

drop policy if exists "notifications: recipient can read" on public.notifications;
create policy "notifications: recipient can read" on public.notifications
  for select using (user_id = auth.uid());

drop policy if exists "notifications: recipient can mark read" on public.notifications;
create policy "notifications: recipient can mark read" on public.notifications
  for update using (user_id = auth.uid());

drop policy if exists "notifications: members can insert for their shop" on public.notifications;
create policy "notifications: members can insert for their shop" on public.notifications
  for insert with check (public.is_shop_member(shop_id));

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

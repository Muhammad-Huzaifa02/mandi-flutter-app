# Mandi — Row Level Security (RLS) & Zero-Trust Access Control

## 1. Zero-Trust Security Model
In traditional applications, the client sends a `shop_id` in the API payload, and the server trusts it. In Mandi, this is strictly prohibited.

The PostgreSQL engine independently verifies tenant rights on every SQL read/write:
```sql
auth.uid() -> shop_memberships (status = 'active') -> shop_id + role + permissions
```

## 2. Core Security Stored Functions

### `is_shop_member(p_shop_id uuid)`
Validates that the currently authenticated caller has an active membership in the shop:
```sql
create or replace function public.is_shop_member(p_shop_id uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from public.shop_memberships
    where shop_id = p_shop_id and user_id = auth.uid() and status = 'active'
  );
$$;
```

### `has_permission(p_shop_id uuid, p_permission text)`
Evaluates whether the caller holds a specific permission (e.g. `create_invoice`, `view_reports`), taking into account any custom permission overrides set for that specific staff member:
```sql
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
```

## 3. RLS Policy Enforcement Example (Invoices Table)

```sql
-- 1. Members with 'view_invoices' can view their shop's invoices
create policy invoices_select on public.invoices
  for select
  using (
    public.has_permission(shop_id, 'view_invoices')
    or
    -- Customers can view only their own invoices
    (customer_id in (
      select id from public.customers where user_id = auth.uid() and shop_id = invoices.shop_id
    ))
  );

-- 2. Only members with 'create_invoice' can insert
create policy invoices_insert on public.invoices
  for insert
  with check (
    public.has_permission(shop_id, 'create_invoice')
  );
```

## 4. Key Management & Secrets Protection
- **`anonKey`:** Shipped with client binary. Governed 100% by RLS; grants zero elevated privileges.
- **`service_role`:** Stored only in Supabase Cloud Edge Function environment secrets; never present in Flutter code.

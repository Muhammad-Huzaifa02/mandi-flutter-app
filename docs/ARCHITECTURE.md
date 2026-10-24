# Mandi System Architecture & Technical Specifications

This document details the software architecture, state management patterns, database schema design, Row Level Security (RLS) enforcement, and hardware integration specs of the **Mandi Application**.

---

## 1. High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Client                       │
│  ┌────────────────────┐      ┌───────────────────────┐  │
│  │   UI Views & Pages │      │ ChangeNotifier        │  │
│  │  (Glassmorphism)   │ ◄───►│ Providers (Reactive)  │  │
│  └────────────────────┘      └──────────┬────────────┘  │
└─────────────────────────────────────────│───────────────┘
                                          │ Supabase Client / Stream
                                          ▼
┌─────────────────────────────────────────────────────────┐
│                  Supabase Cloud Services                │
│  ┌────────────────────┐      ┌───────────────────────┐  │
│  │ PostgreSQL DB      │      │ Row Level Security    │  │
│  │ (schema.sql)       │ ◄───►│ (RLS Policies)        │  │
│  └────────┬───────────┘      └───────────────────────┘  │
│           │ RPC Functions                               │
│  ┌────────┴───────────┐      ┌───────────────────────┐  │
│  │ PL/pgSQL Stored    │      │ Deno Edge Functions   │  │
│  │ Functions          │      │ (create-staff, etc.)  │  │
│  └────────────────────┘      └───────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Flutter State Management & Provider Hierarchy

The app uses `Provider` and `ChangeNotifierProxyProvider` to achieve reactive data flow bound to the active shop ID:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ChangeNotifierProvider(create: (_) => ConnectivityService()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => ShopContextProvider()),
    ChangeNotifierProxyProvider<ShopContextProvider, InvoiceProvider>(
      create: (_) => InvoiceProvider(),
      update: (_, shopCtx, provider) => provider!..updateShop(shopCtx.currentShopId),
    ),
    // CustomerProvider, SupplierProvider, ProductProvider, EmployeeProvider, ExpenseProvider, PaymentProvider...
  ],
)
```

### Key Providers
- **`AuthProvider`**: Manages Supabase Auth session, user claims, login/logout, and password setup flags.
- **`ShopContextProvider`**: Holds current shop details, user membership role, and evaluates `hasPermission(permissionString)`.
- **Data Providers**: Listen to Supabase realtime streams filtered by `currentShopId` and notify UI widgets upon database changes.

---

## 3. Database Schema Reference (`supabase/schema.sql`)

### 3.1 Tables
- **`shops`**: Shop profile, commission defaults, logo URL, invoice prefix, next invoice number counter.
- **`roles`**: Granular permission arrays per shop.
- **`shop_memberships`**: Links `auth.users` to `shops` with `role_id` and `status` (`active` or `inactive`).
- **`customers`**: Buyer records, contact details, opening balance, and running balance.
- **`suppliers`**: Farmer/supplier records, crop history, and running balance.
- **`products`**: Commodity catalog, Maund weight per unit, pricing, and current stock level in KG.
- **`invoices`**: Sales invoice header records (subtotal, commission, expenses, discount, grand total, pending balance, status).
- **`invoice_items`**: Line items linked to invoices and products (quantity, weight in KG, unit price per Maund).
- **`purchase_orders`**: Farmer crop delivery receipts.
- **`expenses`**: Shop expense records categorized by type.
- **`payments`**: Payment transaction receipts updating party running balances.
- **`audit_logs`**: System audit trail logs.

---

## 4. Database RPC Functions & Security

### 4.1 `create_shop_with_owner`
```sql
create or replace function public.create_shop_with_owner(
  p_shop jsonb,
  p_owner_name text,
  p_owner_phone text,
  p_owner_email text,
  p_default_roles jsonb
) returns uuid
```
Creates shop row, default roles (`owner`, `manager`, `accountant`, `sales_staff`, `inventory_staff`), and owner's `shop_memberships` record in a single atomic transaction.

### 4.2 `create_invoice_with_stock_deduction`
```sql
create or replace function public.create_invoice_with_stock_deduction(
  p_invoice jsonb,
  p_items jsonb
) returns uuid
```
Inserts sales invoice + items and deducts stock using `FOR UPDATE` row locking on products to prevent race conditions during high-volume Mandi trading.

### 4.3 `cancel_invoice_and_restore_stock`
```sql
create or replace function public.cancel_invoice_and_restore_stock(
  p_invoice_id uuid,
  p_shop_id uuid,
  p_actor_id text,
  p_actor_name text,
  p_reason text default ''
) returns void
```
Voids invoice (`status = 'void'`), restores product stock, reverses customer/supplier running balance updates, and writes audit record.

---

## 5. Local Storage & Keys (`SharedPreferences`)

| Key Name | Type | Purpose |
| :--- | :--- | :--- |
| `app_theme_mode` | String | Selected theme mode (`light`, `dark`, `system`) |
| `primary_brand_color` | Int | Selected shop brand primary color |
| `app_font_scale` | Double | Text scaling factor (0.85 to 1.30) |
| `app_language_code` | String | Selected language code (`en` or `ur`) |
| `printer_roll_width` | Double | Thermal paper width (`80.0` or `58.0`) |
| `printer_footer_note` | String | Custom footer text printed on receipts |

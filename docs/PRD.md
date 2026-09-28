# Mandi — Product Requirements Document

## Purpose

Mandi lets any agricultural commission shop owner in Pakistan register
their own shop and run its full day-to-day business — staff, customers,
suppliers, products, inventory, sales, commission, invoicing, expenses,
reporting — inside one multi-tenant app. It is the successor to the
single-shop **Saith Commission Shop** app: same proven business logic
(commission math, mandi-style weight pricing, invoicing), rebuilt from
day one as a real multi-tenant platform rather than retrofitted.

## Users

| Role | Created by | Gets |
|---|---|---|
| Owner | Signs up directly (Create New Shop) | Full access to their one shop |
| Manager / Accountant / Sales Staff / Inventory Staff | Invited by the Owner | Whatever permissions their role (or per-member override) grants |
| Customer | Invited by the Owner, or self-registers | Their own shop-scoped storefront view |
| Supplier | Invited by the Owner | Their own dashboard: purchase orders, ledger, deliveries |

Nobody ever picks a role or searches for a shop. Authentication resolves
straight to **user → shop membership → role → permissions → dashboard**.

## Functional requirements by module

Status key: **Done** (built and working) · **Partial** (schema/backend
ready, UI incomplete or missing) · **Planned** (not started).

| Module | Requirement | Priority | Status |
|---|---|---|---|
| Multi-tenancy | Any number of shops, each with fully isolated data enforced server-side (RLS), not just client-side filtering | Must | Done |
| Onboarding | Welcome → Login/Continue (primary) or Create New Shop (secondary) → registration → 4-step wizard → dashboard | Must | Done |
| Auth | One login for every role, phone or email, no role/shop picker | Must | Done |
| Auth | Forgot Password: phone OTP → new password, with resend countdown, strength meter, error states | Must | Done |
| Staff | Owner invites staff; account is auto-scoped to the owner's current shop; no plain-text password ever shown | Must | Done |
| Staff | Per-member permission overrides, independent of role | Should | Done |
| Staff | Deactivate/reactivate (blocks all shop data access immediately via RLS, no Auth account changes needed) | Must | Done |
| Customers | Owner invites customers; customer self-registration also supported | Must | Partial (Edge Function + schema ready, no Flutter screens yet) |
| Suppliers | First-class role with a dedicated dashboard (purchase orders, deliveries, ledger, outstanding balance) | Must | Partial (Edge Function + schema ready, no Flutter screens yet) |
| Products | Catalog with agricultural units, custom products, min stock level | Must | Planned (schema ready) |
| Inventory | Stock in/out/adjustment/damage/return, each a transaction record; low-stock alerts | Must | Planned (schema ready) |
| Pricing | Mandi-style: price per base weight × quantity × (unit weight ÷ base weight) | Must | Planned (formula specified, no UI) |
| Sales / Commission | Commission = (products total × %) + fixed; subtotal = products + commission + expenses; final = subtotal − discount | Must | Planned (RPC `create_invoice_with_stock_deduction` ready) |
| Invoicing | PDF, print, WhatsApp share; configurable numbering; payment method (Cash/Bank/JazzCash/Easypaisa) | Should | Planned |
| Expenses | Categorized (labor, packing, transport, rent, ...), optionally linked to a transaction | Should | Planned (schema ready) |
| Reports | Sales/purchase/inventory/financial/customer/employee, filterable, exportable | Must | Planned |
| Notifications | Low stock, pending payments, new transactions | Should | Planned (schema ready) |
| Roles editor | Owner customizes a role's permission set or creates a custom role | Should | Planned |

## Non-functional requirements

- **Security**: every shop-scoped table has Row Level Security; a client
  can never gain another shop's data by tampering with a `shop_id`.
- **Scalability**: designed for 1,000+ shops on one shared schema
  (`shop_id` filtering + indexes, not one schema/table set per shop).
- **Localization**: PKR currency, Pakistani phone/CNIC formats, Urdu
  support left open architecturally (not yet built).
- **Usability**: mobile-first, consistent visual identity (see DESIGN.md).

## Out of scope (documented, not committed)

Mandi marketplace, shop-to-shop trading, farmer management, market price
analytics, delivery/transport management, multi-branch shops, platform
administrator console, subscription billing.

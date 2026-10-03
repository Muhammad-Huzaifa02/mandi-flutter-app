# Mandi — Product Requirements Document

## Purpose

Mandi lets any agricultural commission shop owner in Pakistan register
their own shop and run its full day-to-day business — staff, customers,
suppliers, products, inventory, sales, commission, invoicing, expenses,
procurement, reporting, PDF printing, WhatsApp sharing, and multi-language support —
inside one multi-tenant app.

## Users & Role Portals

| Role | Created by | Gets |
|---|---|---|
| Owner / Admin | Signs up directly (Create New Shop) | Full management access to their shop |
| Manager / Accountant / Sales Staff / Inventory Staff | Invited by the Owner | Permission-gated access based on role & overrides |
| Customer | Invited by the Owner, or self-registers | Dedicated Customer Portal (Products, Orders, Invoices, Ledger, Payments) |
| Supplier | Invited by the Owner | Dedicated Supplier Portal (Purchase Orders, Supplied Products, Invoices, Ledger) |

Nobody ever picks a role or searches for a shop. Authentication resolves
straight to **user → shop membership → role → permissions → dashboard**.

## Functional Requirements by Module (All Complete)

| Module | Requirement | Priority | Status |
|---|---|---|---|
| Multi-tenancy | Any number of shops, each with fully isolated data enforced server-side (RLS), not just client-side filtering | Must | Done |
| Onboarding | Welcome → Login/Continue (primary) or Create New Shop (secondary) → registration → 4-step wizard → dashboard | Must | Done |
| Auth | One login for every role, email sign-in, mobile deep-linking (`mandi://auth-callback`), web activation page (`reset_password.html`) | Must | Done |
| Staff | Owner invites staff; account is auto-scoped to current shop; status updates in real time on owner dashboard | Must | Done |
| Staff | Per-member permission overrides, independent of role | Should | Done |
| Staff | Deactivate/reactivate (blocks all shop data access immediately via RLS) | Must | Done |
| Customers | Owner invites customers; dedicated Customer Portal with live ledger balance & A4 PDF statement download | Must | Done |
| Suppliers | First-class role with dedicated Supplier Portal (Purchase Orders, Supplied Produce, Invoices, Ledger) | Must | Done |
| Products | Catalog with agricultural units (40 KG Maund), custom products, min stock level & low-stock alerts | Must | Done |
| Inventory | Stock deduction via row-locking Postgres RPC (`create_invoice_with_stock_deduction`); low-stock badges | Must | Done |
| Pricing Math | Mandi-style: $\text{Manns} = \text{KG} / 40.0$, Total Price = $\text{Manns} \times \text{Price per 40 KG}$ | Must | Done |
| Sales / Consignment | Option A Consignment Sale (*Aawak & Boli*) with net supplier payout & Option B Direct Mandi Purchase | Must | Done |
| Invoicing | A4 PDF receipt generation, printing, WhatsApp text sharing, Email sharing | Should | Done |
| Expenses | Categorized (Labor/Mazdoori, Freight/Kiraya, Rent, Packing, Electricity, Tea/Food, Other) | Should | Done |
| Payments | Customer cash receipts & Supplier payments with automatic running balance updates | Must | Done |
| Procurement | Purchase Orders management (`purchase_orders` table) with status tracking (`received`, `pending`, `cancelled`) | Must | Done |
| Reports | Net Mandi Profit & Loss ($\text{Commission} - \text{Expenses}$), Receivables/Payables, one-tap Excel (`.xlsx`) export | Must | Done |
| Notifications | Connection status bar (`connectivity_plus`) and on-device push alerts (`flutter_local_notifications`) | Should | Done |
| Roles editor | Owner customizes a role's permission set or creates a custom role | Should | Done |
| Audit Trail | Real-time stream of shop actions (member activations, invoices, stock changes) | Should | Done |
| Multi-Language | Bilingual English & Urdu (`اردو`) Mandi terms switcher (*Gandum, Chawal, Mazdoori, Kiraya, Mann, Vasool, Baqi*) | Should | Done |

## Non-functional Requirements

- **Security**: Every shop-scoped table has Row Level Security; strict customer & supplier record isolation.
- **Scalability**: Designed for 1,000+ shops on one shared schema (`shop_id` filtering + composite indexes).
- **Localization**: PKR currency, Pakistani phone/CNIC formats, Urdu (`اردو`) localization.
- **Usability**: Mobile-first, responsive Flutter Web support.

# Mandi — Task Matrix

## Completed Modules

- [x] **Multi-Tenant Foundation**: `Shop`, `ShopMember`, `Role` models, `ShopContextProvider`, Supabase Auth (`supabase_flutter`).
- [x] **Postgres Schema & RLS**: 100% idempotent schema (`supabase/schema.sql`) with `drop policy if exists` and server-side row-level security.
- [x] **Serverless Edge Functions**: `create-staff`, `create-customer`, `create-supplier` deployed on Supabase project `kznubtwfzvqvynqpbyve`.
- [x] **Cross-Platform Account Activation**: Mobile deep-linking (`mandi://auth-callback`) and web activation page (`web/reset_password.html`).
- [x] **Employee (Staff) Management**: List, invite via Edge Function, detail, activate/deactivate, per-member audit log.
- [x] **Customer Management & Portal**: Customer list, invite, ledger balances, and dedicated Customer Portal dashboard.
- [x] **Supplier Management & Portal**: Supplier list, invite, ledger balances, procurement orders, and dedicated Supplier Portal dashboard.
- [x] **Products & Inventory Module**: Mandi 40 KG Maund pricing math calculator ($\text{Manns} = \text{KG} / 40.0$), low stock alert badges.
- [x] **Sales Invoicing & Stock Deduction**: Row-locking Postgres RPC (`create_invoice_with_stock_deduction`) for atomic stock deductions.
- [x] **Consignment Sale & Direct Purchase**: Option A Consignment Sale (*Aawak & Boli*) with net supplier payout calculation & Option B Direct Purchase.
- [x] **Expenses Management**: Categorized overhead logging (Labor/Mazdoori, Freight/Kiraya, Rent, Packing, Electricity, Tea/Food, Other).
- [x] **Payments & Settlements**: Customer cash receipts & Supplier settlement payments with automatic running balance updates.
- [x] **Purchase Orders & Procurement**: Purchase order management (`purchase_orders` table) with status tracking (`received`, `pending`, `cancelled`).
- [x] **Financial Reports & Analytics**: Net Mandi Profit & Loss ($\text{Commission} - \text{Expenses}$), Sales Volume, Receivables vs Payables.
- [x] **Excel / CSV Report Exporting**: One-tap `.xlsx` report export for Invoices, Expenses, and Customer Ledgers using `excel` package.
- [x] **A4 PDF Receipts & Ledger Statements**: Itemized A4 invoice PDFs and customer/supplier ledger statement PDFs (`LedgerPdfGenerator`).
- [x] **WhatsApp Sharing & Reminders**: Formatted WhatsApp invoice text sharing and automated payment balance reminders.
- [x] **Roles & Custom Permissions**: Permission customization per role (Manager, Accountant, Sales Staff, Inventory Staff, Custom).
- [x] **Audit Trail**: Real-time stream of shop actions (member activations, invoices, stock changes).
- [x] **Urdu & English Multi-Language UI**: Bilingual English & Urdu (`اردو`) Mandi terms switcher (*Gandum, Chawal, Mazdoori, Kiraya, Mann, Vasool, Baqi*).
- [x] **Offline Banner & Push Alerts**: Connection status bar (`connectivity_plus`) and on-device push notifications (`flutter_local_notifications`).
- [x] **Strict Customer & Supplier Data Isolation**: RLS policies for invoices, payments, and purchase orders so customers/suppliers strictly read only their own records.
- [x] **Flutter Web Support**: Cross-platform Web compilation (`flutter build web`) and web password setup.

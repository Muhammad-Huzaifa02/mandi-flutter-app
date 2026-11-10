# Mandi — Task Matrix

## Completed Modules

- [x] **Multi-Tenant Foundation**: `Shop`, `ShopMember`, `Role` models, `ShopContextProvider`, Supabase Auth (`supabase_flutter`).
- [x] **Postgres Schema & RLS**: 100% idempotent schema (`supabase/schema.sql`) with `drop policy if exists` and server-side row-level security.
- [x] **Serverless Edge Functions**: `create-staff`, `create-customer`, `create-supplier` deployed on Supabase project `kznubtwfzvqvynqpbyve`.
- [x] **Cross-Platform Account Activation**: Mobile deep-linking (`mandi://auth-callback`) and web activation page (`web/reset_password.html`).
- [x] **3D Liquid Glassmorphism Design System**: iOS-style floating glass containers (`GlassCard` / `GlassContainer`) with frosted backdrop blur, layered 3D shadows, and glossy inputs.
- [x] **Device Image Upload for Shop Logos**: Native device gallery image picker (`image_picker`) and Supabase Storage binary upload (`shop-assets` bucket).
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
- [x] **Hardened Security & Privilege Escalation Prevention**: `check_shop_membership_update()` trigger blocking client tampering of `role_id`, `custom_permissions`, `status`, and `salary`.
- [x] **Atomic Procurement RPC**: `create_purchase_order_with_stock_addition` RPC with row locks (`FOR UPDATE`), stock increments, inventory transactions, and balance updates in a single transaction.
- [x] **DSA Algorithmic Ledger Engine**: `LedgerCalculator` with chronological two-pointer merge ($O((N+M)\log(N+M))$), prefix-sum progressive running balance accumulator ($O(N)$), and binary search range queries ($O(\log N)$).
- [x] **Itemized Khata A4 PDF Statements**: Complete multi-page itemized PDF statement generation with debit/credit breakdown, running balance history, and verification seals.
- [x] **Flutter Web Support**: Cross-platform Web compilation (`flutter build web`) and web password setup.
- [x] **Multi-Shop Context Switcher UI**: Active shop switching modal sheet and AppBar dropdown in `DashboardPage` driven by `ShopContextProvider._availableShops`. Seamlessly re-points all proxy providers across shops without page reloads.
- [x] **Daily Cash Day Book (*Roznamcha / روزنامچہ*)**: Complete physical cash drawer reconciliation engine (`RoznamchaCalculator`), interactive UI (`RoznamchaPage`), and official A4 PDF printable register (`RoznamchaPdfGenerator`). Tracks morning opening cash, daily cash inflows (sales + khata collections), cash outflows (supplier payouts + procurement payments + daily expenses), net cash movement, and expected closing drawer balance.
- [x] **Consignment Lot Tracking (*Dheri / آمد و ڈھیری*) & Auction Boli Sheet**: Lot-wise commission agent consignment arrival tracking with lot number, bags, gross weight in KG & Maunds, vehicle number, farmer assignment, interactive auction bid recording (`RecordBidDialog`), 1-click invoice creation, and landscape A4 Daily Auction Boli Sheet (`BoliSheetPdfGenerator`) + individual lot weighing slips (*ڈھیری پرچہ*).
- [x] **Automated Payment Recovery Messaging & Khata Recovery Hub (*تقاضا سنٹر*)**: Dedicated recovery dashboard (`PaymentRecoveryPage`) aggregating debtor accounts by balance severity, filtering by aging/thresholds (>25k, >50k, >100k, >500k), multi-tone reminder engine (`RecoveryMessagingService`) supporting polite, formal, and urgent notices in Urdu & English with online bank details injection, interactive dispatch modal (`SendReminderDialog`), 1-click WhatsApp/SMS launching, and instant cash receipt shortcuts.
- [x] **Bank Accounts & Cheque Clearance Ledger (*PDC / بینکاری اور چیک رجسٹر*)**: Complete banking operations and post-dated cheque (*PDC*) portfolio manager (`BankLedgerPage`). Configurable commercial accounts (Meezan, HBL, MCB, ABL, UBL, BOP, Raast, JazzCash, EasyPaisa), liquid balance aggregator, comprehensive cheque lifecycle tracking (`in_hand`, `deposited`, `cleared`, `bounced`, `returned`), due today alerts, overdue detection, bounce reason auditing, and printable A4 Landscape Cheque Register (`ChequeRegisterPdfGenerator`).
- [x] **Godown / Cold Storage Stock Allocation & Bardana (Bags/Sacks) Ledger (*گودام، کولڈ سٹوریج اور باردانہ کھاتہ*)**: Comprehensive facility stock and packaging asset management hub (`StorageAndBardanaPage`, `StorageProvider`). Tracks Mandi Godowns (*منڈی گودام*), Commercial Cold Stores (*کولڈ سٹوریج*), and Shop Fronts (*دکان / پھڑ*) with capacity utilization gauges and monthly rent per bag. Manages crop batch inward allocations with Maund math ($KG / 40.0$), days in storage, and real-time accrued rent proration. Full revolving ledger for Bardana packaging (Jute sacks, PP woven plastic, wooden crates, reusable plastic crates) tracking issuance to farmers/buyers, security deposits, returns, damages, and overdue alerts. Includes professional landscape A4 PDF reports (`StorageAndBardanaPdfGenerator`).

## In-Progress & Upcoming ERP Roadmap (Sprint 4)

- [ ] **Weighbridge & Electronic Scale Direct Integration**: Direct digital integration with truck weighbridge gross/tare scales and Bluetooth bench scales.


# Mandi (منڈی) — Agricultural Commission Shop Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%20%7C%20RLS-3ECF8E?logo=supabase)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blue)](#)
[![License](https://img.shields.io/badge/License-Proprietary-red)](#)

A comprehensive, production-ready, multi-tenant Flutter application designed specifically for **Agricultural Commission Shops (آڑھت / Mandi)** and grain trading businesses in Pakistan. It streamilines daily auction sales, weight calculations (**Manns / Maunds / Maund = 40 KG**), farmer/supplier purchase orders, customer Khata ledgers, expenses, thermal receipt printing, and real-time financial reporting.

---

## 📑 Table of Contents
1. [Key Features Overview](#-key-features-overview)
2. [Module Breakdown](#-module-breakdown)
3. [Mandi Unit Calculation Engine](#-mandi-unit-calculation-engine)
4. [Role-Based Access Control (RBAC)](#-role-based-access-control-rbac)
5. [System Architecture](#-system-architecture)
6. [Getting Started & Installation](#-getting-started--installation)
7. [Database Setup & Supabase RPCs](#-database-setup--supabase-rpcs)
8. [Thermal POS & PDF Printing](#-thermal-pos--pdf-printing)
9. [Documentation Hub](#-documentation-hub)

---

## 🌟 Key Features Overview

### 🏪 Multi-Tenant & Multi-Shop Architecture
- **Multi-Shop Management & Active Switcher**: Manage multiple commission shops under a single account with an instant shop switcher bottom sheet that re-points all data providers across shops seamlessly.
- **Onboarding Wizard**: Guided shop setup wizard with logo upload, commission percentage defaults, and invoice prefix configuration.
- **Role Router**: Intelligent `AppRoot` gatekeeper routing owners/managers, accountants (munshis), buyers (customers), and farmers (suppliers) to their custom dedicated dashboards.

### 💰 Daily Cash Day Book (*Roznamcha / روزنامچہ*)
- **Physical Drawer Reconciliation**: Accurate daily cash book reconciling morning opening cash in drawer (*گلہ*), cash sales receipts, customer khata recoveries, supplier disbursements, procurement payments, and daily expenses.
- **Algorithmic Chronological Journal**: $O(M \log M)$ merge sorting of all daily financial streams with $O(M)$ progressive running cash balances.
- **Official A4 PDF Printouts**: Mandi-standard daily cash sheets with complete inflow/outflow tables, reconciliation summary box, and cashier/proprietor signature seals.

### 🌾 Consignment Lot Tracking (*Dheri / آمد و ڈھیری*) & Auction Boli Sheet
- **Crop Consignment Intake**: Real-time arrival registration capturing lot numbers, farmer names, vehicle/trolley numbers, bag counts, and gross weight in KG and Maunds ($40\text{ KG}$).
- **Interactive Auction Bidding**: Dedicated `RecordBidDialog` for recording the winning customer bid (rate per Maund) and calculating auction totals on the fly.
- **Official Mandi Boli Sheet**: Landscape A4 Daily Auction Sheet generation and individual lot weighing slips (*ڈھیری پرچہ*) with printer layout and signature seals.
- **1-Click Sales Invoicing**: Seamless flow to convert winning bids directly into sales invoices with automatic inventory and ledger reconciliation.

### ⚖️ Mandi Unit Conversions & Invoicing
- **Automatic Maund Calculations**: Convert **Kilograms (KG)** to **Manns (من = 40 KG)** automatically.
- **Mandi Commission & Expenses**: Automatic calculation of shop commission %, line item expenses (loading, labor/mazdoori, freight/kraya), and discounts.
- **Thermal Receipt Printing**: Print 80mm standard desktop POS or 58mm mobile Bluetooth receipts directly from the app.
- **A4 PDF & WhatsApp Sharing**: Instant A4 invoice PDF generation and direct WhatsApp/Email sharing with buyers.
- **Invoice Cancellation & Stock Restoration**: Void/Cancel invoices with 1-click database transaction restoring product stock and reversing ledger balances.

### 📖 Khata & Algorithmic Ledger Engine (DSA)
- **Chronological Timeline Merge**: Two-pointer merge algorithm ($O((N+M) \log (N+M))$) consolidating invoices and payments into a unified timeline.
- **Prefix-Sum Running Balances**: Linear-scan ($O(N)$) progressive running balance calculation accurately computing net balances after each debit/credit.
- **Binary Search Date Range Queries**: $O(\log N)$ `lowerBound` binary search for instant date-range statement filtering.
- **Itemized Multi-Page A4 PDF Statements**: Detailed statements (*Khata Parcha*) with complete debit/credit transaction tables and signature verification seals.
- **Customer & Supplier Ledgers**: Real-time tracking of receivables, payables, running balances, opening balances, and payment receipts.

### 📢 Payment Recovery Hub & Automated Reminders (*تقاضا سنٹر*)
- **Debtor Severity Aggregator**: Real-time recovery dashboard filtering debtor customer balances by thresholds (>25k, >50k, >100k, >500k PKR) and aging.
- **Multi-Tone Urdu & English Reminders**: Dynamic message generator supporting **Polite** (*شائستہ*), **Formal** (*رسمی*), and **Urgent** (*فوری نوٹس*) tones with automated bank/Raast account injection.
- **1-Click Dispatch & Receipting**: Instant pre-filled WhatsApp and native SMS dispatch, clipboard copying, phone dialing, and 1-tap "Receive Cash" payment entry.

### 🏦 Bank Accounts & Cheque Clearance Ledger (*PDC / بینکاری اور چیک رجسٹر*)
- **Commercial Bank Accounts Portfolio**: Configure and monitor multiple commercial bank accounts and digital wallets (Meezan Bank, HBL, MCB, ABL, UBL, BOP, Bank Alfalah, Raast, JazzCash, EasyPaisa) with 1-tap IBAN and account number copying.
- **Post-Dated Cheque (PDC) Life-Cycle Tracking**: Track received customer cheques and issued supplier cheques through complete states: **In-Hand (PDC)**, **Deposited in Bank**, **Cleared (Realized)**, **Bounced / Dishonored**, and **Returned**.
- **Real-Time Maturity Alerts**: Proactive notifications and badges for cheques maturing **Today** and **Overdue** in-hand cheques.
- **Bounced Cheque Audit Trail**: Record return memos and reasons (Insufficient Funds, Signature Mismatch, Stopped Payment) with immediate financial alerts.
- **Printable A4 Landscape Cheque Register**: Export itemized cheque books and PDC portfolios with comprehensive summary KPIs to printable PDF.

### 🏭 Godown, Cold Storage & Bardana Ledger (*گودام، کولڈ سٹوریج اور باردانہ کھاتہ*)
- **Multi-Facility Capacity & Utilization**: Monitor on-site Mandi Godowns (*منڈی گودام*), commercial Cold Stores (*کولڈ سٹوریج*), and Shop Front auction platforms (*دکان / پھڑ*) with total bag capacity, current occupancy, and remaining space gauges.
- **Batch Storage & Accrued Rent Proration**: Inward batch allocation linking crops, lots, and farmers with automated Mandi Maund conversion ($KG / 40.0$), storage duration counter, and daily prorated rent calculation.
- **Bardana (Sacks & Crates) Packaging Ledger**: Comprehensive revolving packaging asset ledger tracking traditional **Jute Sacks** (*پٹ سن بوری*), **Woven Plastic (PP) Bags** (*تھیلا*), **Wooden Crates** (*لکڑی کی پیٹی*), and **Plastic Reusable Crates** (*پلاسٹک کریٹ*).
- **Security Deposit & Overdue Return Tracking**: Manage unit security deposit rates, total refundable deposit liabilities, damaged/torn write-offs, and automated overdue return alerts.
- **Landscape A4 PDF Reports**: Export high-resolution printable Godown stock allocation rosters and Bardana ledger statements (`StorageAndBardanaPdfGenerator`).

### 📊 Analytics & Financial Reports
- **Interactive Financial Charts**: Sales vs Mandi Commission line charts using `fl_chart`.
- **Date Range Filters**: Filter reports by **All Time, Today, This Week, This Month, or Custom Date Range**.
- **Financial Exports**: Export complete business summary, sales invoices, and shop expenses to **Excel (.xlsx)** or **PDF**.

### ⚖️ Electronic Weighbridge & Dharam Kanda (*دھرم کنڈا وزن رجسٹر*)
- **2-Stage Gross & Tare Life-Cycle**: Complete workflow capturing **1st Weight (Gross / بھرا وزن)** upon vehicle arrival and **2nd Weight (Tare / خالی وزن)** after unloading ($\text{Net Weight} = \text{Gross} - \text{Tare}$).
- **Automated Katoti & Deductions Engine**: Configurable deductions for moisture content percentage, dirt/trash, and packaging tare ($\text{Final Billable Weight} = \text{Net} - \text{Deductions}$).
- **Mandi Maund Units Math**: Instant auto-conversion of Gross, Tare, Net, and Final weights into Mandi Maunds ($\text{Maunds} = \text{Weight in KG} / 40.0$).
- **Live Digital Scale Streaming & Simulation**: Interactive indicator interface supporting standard electronic scale indicators (Yaohua, Toledo, Avery) with STABLE (`ST`) vs MOTION (`US`) status, auto-capture, and zeroing.
- **Printable Official Kanda Certificate Slips & Registers**: High-resolution printable PDF Kanda Slips and full Daily Weighbridge Registers (`WeighbridgeSlipPdfGenerator`).
- **Direct Bridge to Consignment Lots**: 1-click shortcut to pre-populate incoming Consignment Arrival (*ڈھیری پرچہ*) with certified vehicle number, party, crop, bags, and net weight.

### 🌾 Farmer Advance Crop Loans & Markup Ledger (*زمیندار ایڈوانس اور کھاد بیج کھاتہ*)
- **Multi-Category Pre-Harvest Financing**: Tracks cash loans and essential farming inputs (Fertilizer DAP/Urea, Certified Seed, Pesticide Spray, Diesel Fuel, Machinery) with item quantities, unit rates, and total disbursed value.
- **Mandi Markup / Profit Mathematical Engine**: Supports custom annual interest / markup rates with auto-calculated profit, total payable, and remaining balance based on loan maturity days:
  $$\text{Markup (منافع / سود)} = \text{Principal} \times \left(\frac{\text{Rate}}{100}\right) \times \left(\frac{\text{Days}}{365}\right)$$
  $$\text{Total Payable} = \text{Principal} + \text{Markup}$$
  $$\text{Remaining Balance} = \text{Total Payable} - \text{Recovered Amount}$$
- **Automatic Crop Harvest Auction Recoveries (*کٹائی پر ایڈوانس کی کٹوتی*)**: Interactive recovery modal (`RecordAdvanceRecoveryDialog`) linking loan repayments directly to consignment lot auction proceeds (*ڈھیری نیلامی*) with quick percentage presets (100%, 50%, 25%) or cash repayments.
- **Overdue Risk Monitoring & Portfolio Metrics**: Real-time KPI summary tracking Total Disbursed Capital, Accumulated Markup, Recovered Capital, and Outstanding Exposure with overdue aging flags.
- **Official A4 Verification Statements & Shop Registers**: One-tap PDF export of itemized Farmer Statements (*کھاد بیج و ایڈوانس پرچہ*) with farmer thumbprint / signature lines and comprehensive Shop Portfolio Registers (`FarmerAdvancePdfGenerator`).

### 🔐 Enterprise Security & Audit Logging
- **Row Level Security (RLS)**: Strict database-level isolation ensuring zero cross-tenant data leaks and customer/supplier privacy.
- **Privilege Escalation Wall**: PostgreSQL `BEFORE UPDATE` trigger preventing unauthorized tampering with roles, permissions, status, or salary.
- **Atomic Transactions (RPCs)**: Sealed direct client writes; all sales and crop procurements are executed via atomic `SECURITY DEFINER` RPCs with `FOR UPDATE` product row-locking.
- **Audit Logging**: Comprehensive activity trail recording every user action (invoice created, member updated, invoice voided, role edited).

---

## 📦 Module Breakdown

| Module | Features & Capabilities |
| :--- | :--- |
| **Authentication & Onboarding** | Owner registration, login, phone/email password reset, account activation, shop setup wizard. |
| **Dashboard** | Dynamic role-based dashboard displaying quick-action tiles gated by user permissions. |
| **Invoices** | Create sales invoices, Maund/KG weight calculator, thermal print, PDF generate, WhatsApp share, Void/Cancel invoice. |
| **Consignments & Boli** | Crop consignment arrivals (*Dheri*), bag counts, Maunds weighing, auction bidding sheet (*Boli Register*), weighing slips. |
| **Purchase Orders** | Record incoming crops/goods from farmers/suppliers, stock auto-increment, pending payout tracking. |
| **Customers** | Customer directory, running balance ledgers, customer profile detail, account statement exports. |
| **Suppliers** | Supplier/Farmer directory, purchase history, payout tracking, ledger statement exports. |
| **Products & Stock** | Commodity catalog (Wheat/گندم, Rice/چاول, Maize/مکئی, Cotton/کپاس), current stock tracking, min-stock alerts. |
| **Expenses** | Record daily shop expenses (Labor/مزدوری, Freight/کرایہ, Rent, Electricity, Refreshments), expense categories. |
| **Payments** | Record cash/bank receipts from customers and payouts to suppliers, auto-update running balances. |
| **Payment Recovery (Taqaza)** | Debtor khata severity tracker, aging threshold filters, automated Urdu/English WhatsApp & SMS payment reminders with bank/Raast accounts. |
| **Daily Cash Book (Roznamcha)** | Daily morning drawer opening cash, cash sales, khata recoveries, disbursements, operating expenses, and closing balance with A4 PDF printing. |
| **Bank & Cheques (PDC Ledger)** | Commercial accounts management, post-dated cheque (*PDC*) portfolio, clearing lifecycle, bounced cheque alerts, and A4 printable register. |
| **Godown & Bardana Ledger** | Warehouse/cold store capacity tracking, inward batch rent proration, Jute/Plastic sack revolving ledger, security deposits, and A4 PDF reports. |
| **Weighbridge & Kanda** | Vehicle gross/tare weighment, moisture/trash deductions, live digital scale simulation, certified kanda slips, and 1-click consignment lot bridge. |
| **Farmer Advances & Inputs** | Pre-harvest cash & input (DAP/Urea, seed, spray) financing, markup calculation, harvest auction recoveries, and A4 statements. |
| **Reports** | Executive profit/loss overview, commission earnings, receivables/payables summary, date filters, Excel/PDF export. |
| **Employees & Roles** | Staff roster management, invite new employees, activate/deactivate members, custom permission matrix editor. |
| **Shop Settings** | Edit shop details, upload logo image, set invoice prefix, configure thermal printer paper width & footer note, theme color. |
| **Audit Logs** | Real-time security audit log stream filtering actions by shop and team members. |

---

## ⚖️ Mandi Unit Calculation Engine

In South Asian agricultural markets (Mandi), commodities are bought and sold based on **Manns (Maund = 40 KG)**:

$$\text{Manns (من)} = \frac{\text{Total Weight in KG}}{40.0}$$

$$\text{Line Total (PKR)} = \left(\frac{\text{Weight in KG}}{40.0}\right) \times \text{Unit Price per Mann}$$

$$\text{Grand Total} = \text{Subtotal} + \text{Commission Amount} + \text{Expenses} - \text{Discount}$$

$$\text{Pending Balance} = \text{Grand Total} - \text{Received Amount}$$

---

## 🔐 Role-Based Access Control (RBAC)

The system supports granular permission strings evaluated at runtime and enforced by Supabase RLS:

| Permission String | Description | Assigned Default Roles |
| :--- | :--- | :--- |
| `manage_settings` | Edit shop profile, logo, invoice prefix | Owner |
| `manage_employees` | Invite, update, activate/deactivate staff | Owner, Manager |
| `manage_roles` | Edit role permission matrix | Owner |
| `manage_customers` | Add and edit buyer records | Owner, Manager, Accountant |
| `manage_suppliers` | Add and edit farmer/supplier records | Owner, Manager, Accountant |
| `manage_products` | Manage product catalog and pricing | Owner, Manager, Inventory Staff |
| `create_invoice` | Generate sales invoices and void invoices | Owner, Manager, Sales Staff |
| `create_purchase` | Add purchase orders from suppliers | Owner, Manager, Inventory Staff |
| `manage_expenses` | Record and categorize shop expenses | Owner, Manager, Accountant |
| `create_receipt` | Record customer/supplier payments | Owner, Accountant |
| `view_ledger` | View Khata running balances and statements | Owner, Manager, Accountant |
| `view_reports` | Access analytics and financial exports | Owner, Manager, Accountant |

---

## 📁 System Architecture

```text
mandi-flutter-app/
├── android/                   # Android native project & build configuration
├── docs/                      # Comprehensive technical documentation & guides
│   ├── ARCHITECTURE.md        # Deep architectural design & database spec
│   ├── FEATURES.md            # Complete feature walkthrough
│   ├── SUPABASE_SETUP.md      # Database schema deployment guide
│   └── USER_GUIDE.md          # End-user operational manual
├── lib/
│   ├── core/
│   │   ├── theme/             # AppTheme, ThemeProvider, LocaleProvider
│   │   ├── utils/             # MandiCalculator, ThermalReceiptService, ExcelExportService, InvoicePdfGenerator
│   │   └── widgets/           # GlassCard, GlassContainer, ModuleTile, OfflineBanner
│   ├── data/
│   │   ├── models/            # Customer, Supplier, Product, Invoice, Expense, Payment, Shop, Member, Role
│   │   └── services/          # SupabaseService (PostgreSQL streams & RPC triggers)
│   ├── modules/               # Feature modules (Auth, Customers, Invoices, Reports, Settings, etc.)
│   ├── providers/             # AuthProvider, ShopContextProvider
│   └── routes/                # AppRoot gatekeeper & DashboardRouter
└── supabase/                  # PostgreSQL database schema, Edge functions, & config
    ├── functions/             # Deno Edge Functions (create-staff, create-customer, create-supplier)
    └── schema.sql             # Complete database tables, RLS policies, and RPC functions
```

---

## 🚀 Getting Started & Installation

### Prerequisites
- Flutter SDK `>=3.3.0`
- Android Studio / VS Code with Flutter extension
- Supabase account with a active project

### Step 1: Clone Repository
```bash
git clone https://github.com/your-username/mandi-flutter-app.git
cd mandi-flutter-app
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Configure Supabase Credentials
Configure `lib/supabase_config.dart` or supply credentials via `--dart-define` flags:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-publishable-key
```

---

## 🛢️ Database Setup & Supabase RPCs

1. Open **Supabase Dashboard → SQL Editor**.
2. Paste and run the entire contents of `supabase/schema.sql`.
3. Deploy Edge Functions in `supabase/functions/` using Supabase CLI:
   ```bash
   supabase functions deploy create-staff
   supabase functions deploy create-customer
   supabase functions deploy create-supplier
   ```

### Core RPC Functions
- **`create_shop_with_owner`**: Creates shop, default roles, and owner membership atomically.
- **`create_invoice_with_stock_deduction`**: Inserts invoice + line items and deducts product stock with `FOR UPDATE` row locks.
- **`cancel_invoice_and_restore_stock`**: Voids invoice, restores stock, reverses ledger balance, and writes audit log.

---

## 🖨️ Thermal POS & PDF Printing

### 🧾 Munshi Handheld Mobile Bluetooth & POS Thermal Receipts
- **Multi-Document Thermal Engine**: 1-click printing for all daily field operations:
  1. **Sales Invoices (*سیلز بل*)**: Itemized bags, KG, Maunds, commission, expenses, and pending balance.
  2. **Auction Winning Boli Slips (*بولی پرچہ*)**: Lot #, farmer, winning bidder, winning rate (Rs./Mann), and gross auction value.
  3. **Dharam Kanda Weighbridge Slips (*دھرم کنڈا وزن رسید*)**: Vehicle #, 1st gross, 2nd tare, deductions, and certified final billable weight.
  4. **Cash Khata Payment Receipts (*نقدی وصولی پرچہ*)**: Previous balance, cash received, and remaining ledger balance.
  5. **Farmer Advance Loan Deductions (*ایڈوانس کٹوتی پرچہ*)**: Principal, accrued markup, auction recovery sum, and remaining loan.
  6. **Hardware Test Receipts (*ٹیسٹ پرنٹ*)**: 58mm / 80mm column alignment and line feed verification in Shop Settings.
- **ESC/POS Command Byte Generator (`EscPosCommandBuilder`)**: Raw byte protocol generator with text alignment, bold, double-size, tabular space padding (32-column 58mm mobile roll vs 48-column 80mm desktop roll), and partial/full paper cutting.
- **Realistic Thermal Preview Dialog (`ThermalPrintPreviewDialog`)**: Realistic paper-textured preview with serrated tear bottom border, live 58mm/80mm toggle, copies selector, and instant print layout.

### A4 PDF Reports
- Full A4 invoices via `InvoicePdfGenerator`.
- Daily Auction Boli Sheet & Lot Slips via `BoliSheetPdfGenerator`.
- Certified Kanda Certificates & Daily Weighbridge Registers via `WeighbridgeSlipPdfGenerator`.
- Farmer Pre-Harvest Statements & Portfolio Registers via `FarmerAdvancePdfGenerator`.
- Godown & Bardana Ledger Reports via `StorageAndBardanaPdfGenerator`.
- Cheque Register & Post-Dated Cheque Portfolios via `ChequeRegisterPdfGenerator`.
- Ledger account statements via `LedgerPdfGenerator`.
- Executive financial reports generated via `ReportsPage`.

---

## 📚 Documentation Hub

For further details, refer to the documentation files in `docs/`:
- 📖 [docs/FEATURES.md](file:///C:/Users/seith/StudioProjects/mandi-flutter-app/docs/FEATURES.md) — Comprehensive feature walkthrough.
- 🏗️ [docs/ARCHITECTURE.md](file:///C:/Users/seith/StudioProjects/mandi-flutter-app/docs/ARCHITECTURE.md) — Technical architecture & database schema reference.
- ⚙️ [docs/SUPABASE_SETUP.md](file:///C:/Users/seith/StudioProjects/mandi-flutter-app/docs/SUPABASE_SETUP.md) — Step-by-step database deployment guide.
- 👤 [docs/USER_GUIDE.md](file:///C:/Users/seith/StudioProjects/mandi-flutter-app/docs/USER_GUIDE.md) — End-user operational manual for shop owners and munshis.

---

## 📄 License
This project is proprietary and confidential. All rights reserved.

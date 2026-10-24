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
- **Multi-Shop Management**: Manage one or multiple commission shops under a single account.
- **Onboarding Wizard**: Guided shop setup wizard with logo upload, commission percentage defaults, and invoice prefix configuration.
- **Role Router**: Intelligent `AppRoot` gatekeeper routing owners/managers, accountants (munshis), buyers (customers), and farmers (suppliers) to their custom dedicated dashboards.

### ⚖️ Mandi Unit Conversions & Invoicing
- **Automatic Maund Calculations**: Convert **Kilograms (KG)** to **Manns (من = 40 KG)** automatically.
- **Mandi Commission & Expenses**: Automatic calculation of shop commission %, line item expenses (loading, labor/mazdoori, freight/kraya), and discounts.
- **Thermal Receipt Printing**: Print 80mm standard desktop POS or 58mm mobile Bluetooth receipts directly from the app.
- **A4 PDF & WhatsApp Sharing**: Instant A4 invoice PDF generation and direct WhatsApp/Email sharing with buyers.
- **Invoice Cancellation & Stock Restoration**: Void/Cancel invoices with 1-click database transaction restoring product stock and reversing ledger balances.

### 📖 Khata & Ledger Management
- **Customer (Buyer) Ledgers**: Real-time tracking of receivables, running balances, opening balances, and payment receipts.
- **Supplier (Farmer) Ledgers**: Real-time tracking of payables, purchase receipts, and harvest payouts.
- **Payment Recording**: Support for Cash, Bank Transfer, Cheque, and Online Transfer payments with instant running balance updates.
- **PDF Ledger Statements**: Export detailed customer/supplier account statements to PDF or share via WhatsApp.

### 📊 Analytics & Financial Reports
- **Interactive Financial Charts**: Sales vs Mandi Commission line charts using `fl_chart`.
- **Date Range Filters**: Filter reports by **All Time, Today, This Week, This Month, or Custom Date Range**.
- **Financial Exports**: Export complete business summary, sales invoices, and shop expenses to **Excel (.xlsx)** or **PDF**.

### 🔐 Security & Audit Logging
- **Row Level Security (RLS)**: Strict database-level isolation ensuring zero cross-tenant data leaks.
- **Audit Logging**: Comprehensive activity trail recording every user action (invoice created, member updated, invoice voided, role edited).

---

## 📦 Module Breakdown

| Module | Features & Capabilities |
| :--- | :--- |
| **Authentication & Onboarding** | Owner registration, login, phone/email password reset, account activation, shop setup wizard. |
| **Dashboard** | Dynamic role-based dashboard displaying quick-action tiles gated by user permissions. |
| **Invoices** | Create sales invoices, Maund/KG weight calculator, thermal print, PDF generate, WhatsApp share, Void/Cancel invoice. |
| **Purchase Orders** | Record incoming crops/goods from farmers/suppliers, stock auto-increment, pending payout tracking. |
| **Customers** | Customer directory, running balance ledgers, customer profile detail, account statement exports. |
| **Suppliers** | Supplier/Farmer directory, purchase history, payout tracking, ledger statement exports. |
| **Products & Stock** | Commodity catalog (Wheat/گندم, Rice/چاول, Maize/مکئی, Cotton/کپاس), current stock tracking, min-stock alerts. |
| **Expenses** | Record daily shop expenses (Labor/مزدوری, Freight/کرایہ, Rent, Electricity, Refreshments), expense categories. |
| **Payments** | Record cash/bank receipts from customers and payouts to suppliers, auto-update running balances. |
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

### Thermal Receipts
- Supports **80mm Standard POS** and **58mm Mobile Bluetooth Roll** printers.
- Configure roll paper width and receipt footer note in **Shop Settings**.
- Uses `ThermalReceiptService.printThermalSlip` for direct printing.

### A4 PDF Reports
- Full A4 invoices via `InvoicePdfGenerator`.
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

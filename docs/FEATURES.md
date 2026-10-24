# Mandi App — Feature Walkthrough & Specifications

This document provides a detailed breakdown of every feature, module, screen, workflow, and capability built into the **Mandi Application**.

---

## 1. Authentication & Onboarding Module

### 1.1 Owner Registration & Welcome Page (`WelcomePage`, `RegisterOwnerPage`)
- **Dual Flow**: Allows new users to either "Create a New Mandi Shop" or "Sign In to Existing Account".
- **Shop Owner Registration**: Collects full name, phone number, email, and password. Validates Pakistani phone numbers using `PkPhoneUtils`.
- **Atomic Shop Creation**: Calls `create_shop_with_owner` RPC function to create the shop, default roles, and owner membership in a single transaction.

### 1.2 Account Activation & Password Setup (`AccountActivationPage`, `SetPasswordPage`)
- Staff members created by shop managers receive an invitation.
- First-time login forces temporary password change via `AccountActivationPage`.

### 1.3 Password Recovery (`ForgotPasswordPhonePage`, `ForgotPasswordOtpPage`, `ForgotPasswordNewPasswordPage`)
- Phone-based OTP password recovery workflow allowing users to set a new password securely.

### 1.4 Shop Setup Wizard (`ShopSetupWizard`)
- Step-by-step onboarding wizard for newly created shops:
  - **Step 1**: Basic shop profile (Name, Phone, WhatsApp, City, Address).
  - **Step 2**: Logo upload to Supabase Storage `shop-assets` bucket.
  - **Step 3**: Default commission % and invoice prefix configuration.

---

## 2. Dynamic Role-Based Routing & Gatekeeper (`AppRoot`, `DashboardRouter`)

### 2.1 Multi-Level Gatekeeper (`AppRoot`)
- Evaluates full authentication & shop context state in order:
  1. Auth unresolved → `SplashPage`
  2. Not logged in → `WelcomePage`
  3. Needs password setup → `AccountActivationPage`
  4. Shop context loading → `SplashPage`
  5. Logged in with no active shop → `NoShopPage`
  6. Logged in with active shop → `dashboardForRole(roleId)`

### 2.2 Role-Based Dashboard Navigation
- **Owner / Manager / Accountant / Staff**: Routed to main `DashboardPage` with grid tiles filtered by active permission strings.
- **Customer**: Routed to `CustomerDashboardPage` showing personal purchase history, total payable balance, and download statement actions.
- **Supplier**: Routed to `SupplierDashboardPage` showing harvest deliveries, total receivable payout, and account statement exports.

---

## 3. Sales Invoicing & Mandi Weight Calculations (`CreateInvoicePage`, `InvoiceDetailPage`)

### 3.1 Mandi Maund Weight Calculator (`MandiCalculator`)
- Automatically calculates:
  - Total Bags / Quantity.
  - Total Weight in KG.
  - Equivalent **Manns (من = 40 KG)**: `weightKg / 40.0`.
  - Line Item Total: `(weightKg / 40.0) * unitPricePerMann`.

### 3.2 Invoice Composition
- Select Customer (Buyer) and optional Supplier (Farmer).
- Add multiple commodity line items.
- Line expenses (Labor/Mazdoori, Freight/Krara, Loading/Unloading).
- Shop Commission % auto-calculated based on shop defaults or custom override.
- Discount support and instant Grand Total calculation.

### 3.3 Atomic Stock Deduction (`create_invoice_with_stock_deduction` RPC)
- Deducts commodity stock with `FOR UPDATE` row locks to prevent over-selling during busy Mandi auction hours.
- Auto-updates customer running balance when invoice has a pending balance.
- Triggers local system notification via `NotificationService`.

### 3.4 Invoice Voiding / Cancellation
- Voids an invoice (`status = 'void'`) with 1-click database transaction:
  - Product stock restored to inventory.
  - Customer/supplier running balance reversed.
  - Audit log recorded with reason.
- Displays prominent "THIS INVOICE HAS BEEN VOIDED / CANCELLED" banner.

---

## 4. Purchase Orders & Goods Receiving (`PurchaseOrderListPage`, `AddPurchaseOrderPage`)

- Record incoming crop shipments from farmers/suppliers.
- Auto-increments product stock level upon arrival.
- Updates supplier running balance with pending payout amount.

---

## 5. Khata & Ledger Management

### 5.1 Customer Ledgers (`CustomerListPage`, `CustomerDetailPage`, `CustomerDashboardPage`)
- Customer directory with search and phone quick-call/WhatsApp actions.
- Displays **Opening Balance** and **Running Balance**.
- Complete ledger history showing sales invoices and cash receipts.
- Export account statement to **A4 PDF** (`LedgerPdfGenerator`) or **Excel**.

### 5.2 Supplier / Farmer Ledgers (`SupplierListPage`, `SupplierDetailPage`, `SupplierDashboardPage`)
- Supplier directory with crop delivery history.
- Tracks pending payouts owed by shop to farmer.
- Export supplier account statement to PDF/Excel.

---

## 6. Payments & Cash Receipts (`PaymentListPage`, `AddPaymentPage`)

- Record cash, bank transfer, cheque, or online payment receipts.
- Automatically adjusts party running balance:
  - Customer payment reduces customer running balance (receivable).
  - Supplier payout reduces supplier running balance (payable).

---

## 7. Shop Expenses Tracking (`ExpenseListPage`, `AddExpensePage`)

- Categorize daily commission shop expenses:
  - Labor (Mazdoori / مزدوری)
  - Transport & Freight (Kraya / کرایہ)
  - Rent (Dukan Rent / دکان کا کرایہ)
  - Electricity & Bills
  - Tea & Refreshments (Chai / چائے)
  - Packing & Bags
  - Other
- Deducted directly from commission earnings in Profit & Loss reports.

---

## 8. Analytics & Financial Reports (`ReportsPage`)

### 8.1 Executive Metrics
- **Net Mandi Profit**: $\text{Commission Earned} - \text{Shop Expenses}$.
- **Gross Sales Volume**: Total subtotal of all sales invoices.
- **Receivables vs Payables**: Money owed to shop by buyers vs money owed by shop to farmers.

### 8.2 Interactive Chart
- Interactive sales vs commission trend line chart (`fl_chart`).

### 8.3 Period Filtering & Exports
- Period Filters: **All Time, Today, This Week, This Month, Custom Range**.
- **Excel Export**: Export complete summary, invoices, and expenses tabs to `.xlsx` using `ExcelExportService`.
- **PDF Export**: Generate formatted executive financial report PDF.

---

## 9. Thermal POS & PDF Printing Services

### 9.1 Thermal POS Receipts (`ThermalReceiptService`)
- Support for **80mm Standard Desktop POS** and **58mm Mobile Bluetooth Roll** paper.
- Configurable paper width and footer note saved in `SharedPreferences`.

### 9.2 PDF Generators (`InvoicePdfGenerator`, `LedgerPdfGenerator`)
- Formatted A4 invoices with shop logo, item breakdown, and signature lines.
- Detailed ledger account statements formatted for printing or sharing.

---

## 10. Staff, Roles & Permissions Matrix (`EmployeeListPage`, `RolesListPage`, `EditRolePage`)

- Roster management: Invite employees via Deno Edge Functions (`create-staff`).
- Toggle active/inactive status to instantly grant or revoke shop access.
- Role editor: Customize granular permission checkboxes per role.

---

## 11. Shop Settings & Customization (`ShopSettingsPage`)

- Edit shop profile (Name, Phone, WhatsApp, City, Address).
- Upload shop logo image to Supabase Storage.
- Set default commission % and invoice prefix.
- Configure thermal printer roll paper width and footer note.
- Customize brand theme color and text font scaling.
- Toggle app language between **English** and **Urdu (اردو)**.

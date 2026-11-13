# Mandi — Software Requirements Specification (SRS)

## 1. Introduction
This Software Requirements Specification (SRS) details the complete functional, non-functional, security, and interface specifications for the Mandi Multi-Tenant AgTech ERP platform.

## 2. Overall Description
### 2.1 Product Perspective
Mandi operates as a multi-tenant cloud-connected and offline-capable ERP that replaces manual paper-based *Bahi Khata* (بہی کھاتہ), *Roznamcha* (روزنامچہ), and manual gate registers in grain markets across Pakistan.

### 2.2 User Classes & Roles
1. **Commission Shop Owner (آڑھتی / مالک):** Full system access, P&L reports, partner profit distribution, employee wage reviews, and permission assignments.
2. **Head Clerk / Munshi (ہیڈ منشی):** Live auction floor bidding, consignment lot creation, lot slips, and gate pass approvals.
3. **Accountant / Cashier (اکاؤنٹنٹ / کیشیئر):** Invoice creation, cash receipt vouchers, bank reconciliation, and cheque tracking.
4. **Weighbridge Incharge (کانٹا انچارج):** Vehicle gross weight, tare weight entry, and net Maunds calculation.
5. **Farmer / Zamindar (زمیندار):** Read-only personal passbook access, crop offering creation, and payment verification.
6. **Buyer / Customer (خریدار / بیوپاری):** Invoice review, outstanding dues tracking, and dispatch gate passes.

## 3. Functional Requirements
### 3.1 Authentication & Multi-Tenancy (AUTH)
- **REQ-AUTH-01:** System must authenticate users via E.164 phone number OTP or email/password.
- **REQ-AUTH-02:** When an account belongs to multiple Mandi shops, the system must allow switching active context via `ShopContextProvider`.
- **REQ-AUTH-03:** All database queries must be partitioned by `shop_id` with Row Level Security (RLS) enforcement.

### 3.2 Live Auction Floor (AUC)
- **REQ-AUC-01:** System must record bids in Pakistani Rupees per Maund (PKR / من).
- **REQ-AUC-02:** Bidding floor must support gavel countdowns (1 = *Ek*, 2 = *Do*, 3 = *Teen - Sold!*).
- **REQ-AUC-03:** Winner lot allocation must auto-generate a sales invoice and adjust consignment lot status.

### 3.3 Weighbridge & Kanda (WGH)
- **REQ-WGH-01:** System must record vehicle license plate, commodity, gross weight (بھرا وزن), and empty tare weight (خالی وزن).
- **REQ-WGH-02:** System must compute exact net weight in KG and automatically convert to Maunds using $1\text{ Maund} = 40.0\text{ KG}$.
- **REQ-WGH-03:** Direct thermal ESC/POS Kanda ticket printing must be supported.

### 3.4 Invoicing & Ledgers (INV)
- **REQ-INV-01:** System must auto-calculate commission percentage, labor (*Palladari*), and statutory market committee fees.
- **REQ-INV-02:** Generating an invoice must automatically update customer receivables and farmer payables via atomic database triggers.
- **REQ-INV-03:** Daily Roznamcha cash register must enforce double-entry equality ($\sum\text{Debits} == \sum\text{Credits}$).

## 4. Non-Functional Requirements
- **PERF-01:** Dashboard load latency must not exceed 250ms on 4G networks.
- **PERF-02:** UI rendering must maintain a consistent 60/120 FPS on entry-level Android devices using `LiquidCrystalBackground` performance budgeting.
- **SEC-01:** All client requests must use public anonymous keys; service-role keys must never be shipped in the client binary.
- **USAB-01:** System must support 100% pure English and 100% pure Urdu without mixed language text in a single interface.
- **COMP-01:** Offline sync engine must cache pending records locally and auto-merge without data loss upon network reconnection.

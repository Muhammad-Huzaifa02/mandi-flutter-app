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

### 🖨️ Munshi Mobile Bluetooth Thermal Printer (ESC/POS 58mm & 80mm) (*منشی تھرمل پرنٹر اور فوری پرچہ جات*)
- **Native ESC/POS Byte Builder**: Low-level ESC/POS command stream generator (`EscPosCommandBuilder`) supporting 58mm (32 columns) and 80mm (48 columns) paper rolls, bold/double-height typography, aligned table rows, dashed dividers, and auto paper cut commands.
- **6-Document Printing Suite (`ThermalReceiptService`)**: Instant 1-click receipts formatted with serrated tear preview dialog (`ThermalPrintPreviewDialog`) for:
  1. **Sales Invoices**: Itemized sales slips with weight in Maunds & KG, rate, commission, expenses, and buyer balances.
  2. **Boli / Dheri Winning Slips (*بولی پرچہ*)**: Lot arrivals, vehicle numbers, bag counts, and winning buyer bids.
  3. **Weighbridge Kanda Slips (*دھرم کنڈا رسید*)**: Gross, Tare, and certified Net billable weights.
  4. **Cash Khata Payment Receipts (*وصولی پرچہ*)**: Instant payment voucher with previous and remaining ledger balances.
  5. **Farmer Advance Loan Deductions (*ایڈوانس کٹوتی پرچہ*)**: Harvest auction recovery receipts.
  6. **Hardware Test Slips (*ٹیسٹ پرنٹ*)**: Alignment and print-head diagnostic pattern.

### 🌐 Multi-Currency & Cross-Border Mandi Trade (*پاک افغان و پاک ایران سرحدی تجارت اور کرنسی کھاتہ*)
- **Regional Import Transit Corridors**: Dedicated international trade hub (`CrossBorderPage`, `CrossBorderProvider`) managing fruit and vegetable cargo originating from **Afghanistan** 🇦🇫, **Iran** 🇮🇷, and Central Asia (Pomegranates/انار, Grapes/انگور, Apples/سیب, Dates/کھجور, Melons/خربوزہ).
- **Major Border Checkpoints**: Built-in routing and clearance tracking across **Torkham** (*طورخم*), **Chaman** (*چمن*), **Taftan** (*تفتان*), **Gabd-Rimdan** (*گبد ریمدان*), and **Khunjerab** (*خنجراب*).
- **Dual-Currency Contract Valuation**: Multi-currency engine converting foreign trade currencies (**USD $**, **AFN ؋**, **IRR ﷼**) into base Pakistani Rupee (PKR) at custom negotiated exchange rates.
- **Comprehensive Landed Cost Economics**: Aggregates base cargo cost with customs import tariffs (Customs GD #), cross-border freight carriage, clearing agent port fees, and cold chain/tolls:
  $$\text{Base PKR} = \text{Foreign Contract Amount} \times \text{Exchange Rate}$$
  $$\text{Total Border Surcharges} = \text{Customs Duty} + \text{Border Freight} + \text{Clearing Charges} + \text{Other}$$
  $$\text{Total Mandi Landed Cost} = \text{Base PKR} + \text{Total Border Surcharges}$$
  $$\text{Cost Per Maund (40 KG)} = \frac{\text{Total Landed Cost}}{\text{Gross Weight in KG} / 40.0}$$
- **Foreign Supplier Settlement Ledger**: Monitors payments to foreign exporters, remaining foreign currency debt, and PKR liability exposure with interactive payment recording.
- **1-Click Consignment Lot Bridge**: Instantly generates an auction consignment lot (*آمد و ڈھیری*) from arrived cross-border cargo with pre-filled vehicle, weight, and bag numbers.
- **Official Printable Manifests & Registers**: High-resolution A4 Single Cargo Manifest & Customs Statements and Landscape A4 Border Transit Registers (`CrossBorderPdfGenerator`).

### 📱 Automated SMS Gateway & Transactional Alerts Engine (*خودکار ایس ایم ایس گیٹ وے اور تصدیقی پیغامات*)
- **Multi-Provider Telecom Integrations**: Comprehensive SMS dispatch infrastructure (`SmsGatewayPage`, `SmsProvider`, `SmsGatewayService`) integrating **Twilio Cloud REST API**, Pakistani Branded Telco Shortcodes, and Generic HTTP Webhook APIs (Jazz, Telenor, Zong, Infobip) alongside an offline local Mock Simulator.
- **GSM-7 & Unicode Character Segmentation**: Built-in character and multi-part segment calculator ($160/153$ chars for standard GSM-7 vs $70/67$ chars for Urdu/Arabic Unicode) preventing unexpected billing surprises.
- **Automated Event Triggers**: Configurable background triggers for Sales Invoices (grand total & pending balance), Cash/Bank Receipts (amount & updated running balance), Auction Boli Winning Bids (lot #, rate/Mann, bags), Weighbridge Kanda Slips (gross, tare, net KG & Maunds), and Farmer Advance Deductions.
- **Delivery Receipts & Audit Trail**: Real-time delivery status monitoring (`sent`, `delivered`, `failed`, `pending`) with telecom message IDs, error reason capturing, and 1-tap retry dispatch.
- **Integrated Khata Recovery Dispatch**: Direct "Gateway SMS" dispatch button built into the Payment Recovery Hub (`PaymentRecoveryPage`, `SendReminderDialog`).

### 🏢 Multi-Shop Consolidated Balance Sheet & Inter-Shop Stock Transfer (*بین المانڈی مشترکہ گوشوارہ و اسٹاک منتقلی*)
- **Multi-Branch Enterprise Aggregation**: High-level consolidated financial overview (`MultiShopHubPage`, `MultiShopProvider`, `ConsolidatedBalanceSheet`) synthesizing real-time data across all branches owned by the Mandi merchant group:
  - **Total Enterprise Turnover & Sales Volume** (*مجموعی مال بکری*)
  - **Net Operating Profit & Commission Pool** (*خالص کمیشن منافع*)
  - **Total Customer Receivables & Supplier Payables Exposure** (*بقایا جات گاہک و زمیندار*)
  - **Enterprise Stock Assets & Net Network Equity** (*مجموعی اثاثہ جات اور خالص ایکویٹی*)
- **Inter-Shop Stock Transfer Engine**: Secure inventory relocation workflow between branches (`inter_shop_transfers` table) tracking commodity, package count, weight in KG, and Mandi Maunds ($\text{KG} / 40.0$).
- **Transit Freight & Landed Cost Economics**: Computes total delivered cost including inter-city truck carriage ($\text{Delivered Cost} = \text{Stock Value} + \text{Transit Freight}$) and effective landed cost per Maund at the receiving branch.
- **Consignment Transit Lifecycle**: Manages status progression (`in_transit`, `received`, `cancelled`) with vehicle number, driver phone, dispatch timestamps, and receiving branch 1-click receipt confirmation.
- **Landscape A4 PDF Reports & Transit Gate Passes**: 1-click PDF generation for:
  1. **Consolidated Multi-Branch Balance Sheet**: Professional Landscape A4 report with group KPI banner, individual branch comparison table, and executive signature blocks.
  2. **Inter-Shop Stock Transfer Gate Pass & Delivery Challan**: Official A4 transit gate pass (`ConsolidatedBalanceSheetPdfGenerator`) with source and destination details, carrier info, commodity quantities, and verification seals.

### 🎙️ Munshi Offline Audio-Voice Note & Ledger Dictation (*منشی صوتی نوٹس اور آواز سے کھاتہ اندراج*)
- **Voice Recording Engine**: Audio note architecture with live duration timer, waveform state indicator, and local/cloud storage linking (`AudioNoteProvider`, `AudioVoiceNote`).
- **Smart Mandi Dictation Parser (`VoiceDictationParser`)**: Automatically extracts party honorifics (*چوہدری، ملک، حاجی، میاں، سیٹھ*), numeric monetary figures (e.g. 20 ہزار، 1 لاکھ، Rs 50,000), crop Maunds ($KG / 40.0$), bag counts, and suspected business intent (cash receipt vs auction boli).
- **Entity Attachment**: Attach voice recordings directly to Sales Invoices, Consignment Lots (*ڈھیری*), Customer Khata entries, or Dharam Kanda weighbridge tickets.
- **Voice Notes Hub (`VoiceNotesHubPage`)**: Searchable repository to review unposted audio memos, mark as processed, archive, or delete.

### 🌟 Customer Loyalty, Volume Rebate & Seasonal Brokerage Incentives (*گاہک رعایت، والیم بونس اور سالانہ انعامات*)
- **Seasonal Volume Tier Milestones**: Define and track trading turnover milestones:
  - **Standard**: `<1,000` Maunds (0.5% default incentive)
  - **Silver (سلور)**: `1,000 - 4,999` Maunds (1.0% default incentive)
  - **Gold (گولڈ)**: `5,000 - 9,999` Maunds (2.0% default incentive)
  - **Platinum (پلاٹینم)**: `10,000+` Maunds (3.0% default incentive)
- **Automatic Credit Note Issuance & Khata Deduction**: Generates unique credit notes (`CRN-YYYY-XXXX`) and automatically deducts the approved rebate amount from the buyer's running debit balance.
- **Printable A4 Credit Note Voucher (`LoyaltyRebatePdfGenerator`)**: High-resolution official Credit Note with trading turnover base, incentive rate, net credit amount, and merchant seal blocks.

### 📈 Mandi Price Intelligence & Daily Rate Board Broadcast (*منڈی روزانہ ریٹ لسٹ اور براڈکاسٹ*)
- **Daily Commodity Rate Board (`MandiRateBoardPage`, `MandiRateProvider`)**: Live commodity index tracking daily minimum, maximum, and modal transaction rates per Maund (40 KG) and per KG ($Modal / 40.0$) across key commodities (Wheat/گندم, Rice Super Kernel, Basmati 1121, Cotton/پھٹی, Corn/مکئی, Potato/آلو, Onion/پیاز).
- **Automated Trend & Price Change Engine**: Real-time trend calculation (`MandiCommodityRate.computeTrendMetrics`) determining price delta and percentage change ($\Delta \text{ PKR}$ and $\% \text{ change}$) classifying trends into **Bullish ▲ (*تیزی*)**, **Bearish ▼ (*مندی*)**, or **Stable ▬ (*مستحکم*)**.
- **Mandi Arrivals (Aawak / آمد)**: Daily arrival volume tracking in Mandi Maunds with quality grading (Grade A, Grade B, Grade C).
- **Multi-Channel Text Broadcast Engine**: One-tap formatted broadcast generator (`generateBroadcastMessage`) for instant WhatsApp and SMS dispatch to farmer grower groups, commission buyers, and transporters with date, rates, and market trend symbols.
- **Official A4 Morning Rate Sheet PDF (`MandiRateBoardPdfGenerator`)**: Printable morning notice board bulletin with shop header, rate matrix, trend badges, and market committee stamp areas.

### 👥 Munshi Staff Attendance & Payroll Ledger (*عملہ حاضری، اوور ٹائم اور تنخواہ کھاتہ*)
- **Daily Staff Attendance Register (`StaffPayrollPage`, `StaffPayrollProvider`)**: Real-time biometric / manual staff attendance tracking for shop employees with presence status (**Present / حاضر**, **Absent / غیر حاضر**, **Half Day / نصف دن**, **Leave / رخصت**) and one-tap "Mark All Present" shortcut.
- **Overtime Tracking**: Hours-based overtime recording with automated $1.5\times$ hourly rate allowance computation ($\text{Hourly Rate} = (\text{Base} / 30) / 8$).
- **Mathematical Payroll Calculation Engine (`StaffPayrollVoucher.computePayrollBreakdown`)**:
  - Daily wage proration based on standard 30-day month ($\text{Daily} = \text{Base} / 30$).
  - Absenteeism deduction: $(\text{Days Absent} \times \text{Daily Wage}) + (\text{Half Days} \times 0.5 \times \text{Daily Wage})$.
  - Advance salary loan recoveries & seasonal bonus incentives.
  - Net wage formula:
    $$\text{Net Payable} = \text{Base} + \text{Overtime Allowance} + \text{Bonus} - \text{Absentee Deduction} - \text{Advance Deduction}$$
- **Disbursement Lifecycle & Multi-Method Payouts**: Status progression (`draft`, `approved`, `paid`) with support for **Cash**, **Bank Transfer**, or **Cheque** disbursement vouchers.
- **A4 Printable Salary Pay Slips & Registers (`StaffPayrollPdfGenerator`)**: High-resolution individual Staff Salary Pay Slip vouchers with itemized earnings & deductions, alongside Landscape A4 Monthly Wage Disbursement Registers.

### 🚚 Fuel & Vehicle Fleet Logistics Ledger (*گاڑیوں کا تیل، کرایہ اور ٹرانسپورٹ کھاتہ*)
- **Transport Fleet & Carrier Registry (`FleetLogisticsPage`, `FleetProvider`)**: Centralized vehicle fleet asset register supporting multiple cargo carrier types:
  - **Tractor Trolley (*ٹریکٹر ٹرالی*)**: Rural farm-to-mandi hauler (approx 200–350 Maunds).
  - **Mazda Truck 6-Wheeler (*مزدا 6 وہیلر*)**: Inter-city grain transport (approx 400–600 Maunds).
  - **Shehzore Pickup (*شہزور ڈالہ*)**: Rapid regional delivery (approx 150–250 Maunds).
  - **Pickup Dala (*پک اپ ڈالہ*) & Rickshaw Loader (*لوڈر رکشہ*)**: Local mandi distribution.
  - **10-Wheeler Heavy Trailer (*ٹرالر 10 وہیلر*)**: Long-haul port and cross-country transit (approx 800–1200 Maunds).
  - Categorized by ownership: **Shop Owned (*ذاتی گاڑی*)**, **Contracted Carrier (*کنٹریکٹ*)**, and **Rental (*کرایہ*)**.
- **Freight Trip Dispatching & Bilty Engine (`NewTripChallanDialog`, `FleetTrip`)**: Comprehensive cargo transport dispatch system:
  - Origin, destination, party/consignee, commodity, bags, weight in KG and auto Mandi Maunds ($\text{KG} / 40.0$).
  - Freight billing with agreed gross freight and driver cash advance tracking.
  - Real-time operating expense budget (diesel, toll plaza / chungi, and misc transit costs).
  - Real-time financial equations:
    $$\text{Operating Expenses} = \text{Diesel Expense} + \text{Toll / Tax} + \text{Other Expenses}$$
    $$\text{Net Trip Profit} = \text{Agreed Freight} - \text{Operating Expenses}$$
    $$\text{Balance Freight Payable} = \text{Agreed Freight} - \text{Driver Advance}$$
- **Fuel, Lubricants & Maintenance Expense Logging (`LogFuelExpenseDialog`, `FleetFuelLog`)**:
  - Itemized receipt recording for **Diesel**, **Petrol**, **CNG**, **Engine Oil & Filters**, **Tires & Punctures**, and **Workshop Repairs**.
  - Liters, pump/vendor name, rate per liter, voucher number, and odometer mileage tracking with automatic vehicle odometer sync.
  - Optional linking directly to in-transit freight trips.
- **Official A4 Printable Bilties & Vehicle P&L Ledgers (`FleetLogisticsPdfGenerator`)**:
  - **Official A4 Portrait Trip Bilty / Delivery Challan**: Dual-language formal transport bilty with consignor, carrier, cargo weights, billing terms, advance paid, and driver/merchant signature seals.
  - **Landscape A4 Vehicle Profit & Loss Ledger**: Comprehensive vehicle register detailing all trips, gross freight revenue, total fuel liters & costs, net operational profit, and fleet profit margins.

### 🔬 Cold Chain Moisture & Commodity Quality Inspection Lab (*جنس نمی، لیب کوالٹی گریڈنگ اور کولڈ چین لاگ*)
- **Grain Moisture Meter & Refraction Lab Inspection (`QualityLabPage`, `QualityProvider`, `QualityInspection`)**: Dedicated testing hub for arriving grain lots (Wheat/گندم, Basmati Rice/چاول, Corn/مکئی, Sunflower/سورج مکھی, Canola/کینولا, Cotton/پھٹی) with sample weights (e.g. 500g), moisture % detection, and visual refraction analysis.
- **Automated Mathematical Katoti / Deduction Engine (`QualityInspection.computeDeductions`)**:
  - **Excess Moisture Deduction**: $\text{Excess Moisture} = \max(0.0, \text{Moisture \\%} - \text{Base Moisture \\%})$.
  - **Refraction Impurities**: Foreign matter/dirt (1:1 deduction), broken grain ($0.5:1$ ratio), and damaged/discolored grain ($0.75:1$ ratio).
  - **Net Certified Weight**:
    $$\text{Total Katoti \\%} = \text{Excess Moisture} + \text{Foreign Matter} + (0.5 \times \text{Broken}) + (0.75 \times \text{Damaged})$$
    $$\text{Deduction KG} = \text{Gross Weight KG} \times \left(\frac{\text{Total Katoti \\%}}{100.0}\right)$$
    $$\text{Net Weight KG} = \text{Gross KG} - \text{Deduction KG}, \quad \text{Net Maunds} = \frac{\text{Net KG}}{40.0}$$
- **Quality Grading Standards**: Automated classification into **Grade A (Super / Premium)**, **Grade B (Standard FAQ / اوسط)**, **Grade C (High Moisture / کٹوتی)**, or **Rejected / Unfit (*مسترد شدہ*)** based on threshold cutoffs.
- **HACCP Cold Storage Temperature & Humidity Audit Register (`ColdChainLog`)**: Chamber environmental monitoring with safe temperature bands $[MinT, MaxT]$, auto status classification (**Optimal**, **Warning**, **Critical**), BLE sensor device tracking, and corrective action logging.
- **Official A4 Printable Certificates & Logs (`QualityInspectionPdfGenerator`)**:
  - **Official A4 Portrait Certificate of Analysis / Moisture Katoti Slip**: Detailed lab certificate with sample metrics, deduction breakdown table, net certified Maunds, and tri-party signature blocks (Inspector, Transporter, Commission Agent).
  - **Landscape A4 Cold Room Temperature Audit Register**: Multi-chamber environmental audit log sheet with alert badges, device IDs, and remediation history.

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
| **Thermal Printer Engine** | Raw ESC/POS bytecode generator, 58mm/80mm roll formatting, simulated tear preview, 6-document receipt suite (Invoices, Boli slips, Kanda tickets, Cash Khata vouchers, Advance deductions). |
| **Cross-Border Mandi Trade** | Pak-Afghan & Pak-Iran transit fruit/vegetable cargo tracking, dual-currency valuation (USD/AFN/IRR to PKR), border checkpoints (Torkham, Chaman, Taftan), customs tariffs & freight landed cost, supplier debt settlement, A4 cargo manifest & register. |
| **SMS Gateway & Alerts** | Multi-provider telecom integration (Twilio, Pakistani Telco, HTTP webhook, Mock), GSM-7/Unicode part calculator, automatic event-driven dispatch triggers (invoices, receipts, boli, weighbridge), delivery audit logs, and direct recovery hub sending. |
| **Multi-Shop & Transfers** | Multi-branch consolidated balance sheet, enterprise equity aggregation, inter-shop consignment stock transfers with Maund math, transit freight, and printable gate pass delivery challans. |
| **Munshi Voice Notes** | Verbal voice recording, Mandi keyword parser (party names, amounts, maunds, bags), entity attachment (invoices, boli, khata), and audio memo hub. |
| **Customer Loyalty & Rebates** | Seasonal turnover targets, tiered volume rebates (Standard, Silver, Gold, Platinum), automated credit note issuance to running khata, and printable A4 vouchers. |
| **Mandi Price Intelligence** | Daily commodity rate index, min/max/modal pricing per Maund and KG ($Modal / 40.0$), trend indicators (Bullish/Bearish/Stable), arrivals volume, WhatsApp & SMS broadcast engine, printable A4 morning bulletin. |
| **Staff Attendance & Payroll** | Daily staff attendance register (Present/Absent/Half-Day/Leave), overtime proration, mathematical net wage deductions engine, voucher approval & disbursement, printable A4 pay slips and registers. |
| **Fleet & Logistics** | Vehicle fleet asset register, freight trip bilty dispatching, fuel/diesel expense logging, carrier P&L registers, printable A4 transport bilty challans. |
| **Quality Lab & Cold Chain** | Moisture testing (% detection), refraction deduction math, certified grade assignment (Super, FAQ, Substandard), HACCP cold room temperature & humidity logs, printable A4 Certificate of Analysis. |
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

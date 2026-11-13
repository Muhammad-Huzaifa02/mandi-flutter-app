# Mandi — Comprehensive Module Specifications

This document defines the 29 domain modules implemented in the Mandi AgTech platform.

## 1. Live Auction Terminal (`auction_boli`)
- **Purpose:** Conduct real-time open cry auction bidding on commodity heaps (*Dheris*).
- **Users:** Shop Owners, Head Clerks (*Munshis*), Commodity Buyers.
- **Key Operations:** Maund-based bidding, auto-paddle assignment, gavel hammer callouts (*Going once, twice, SOLD!*).
- **Database Tables:** `consignment_lots`, `auction_bids`.

## 2. Invoicing & Billing (`invoices`)
- **Purpose:** Generate itemized Mandi commission bills with statutory deductions.
- **Calculations:** Gross weight - tare weight = net KG; KG to Maund conversion; Commission %; Labor (*Palladari*); Market Committee fees.
- **Database Tables:** `invoices`, `invoice_items`.

## 3. Weighbridge Automation (`weighbridge`)
- **Purpose:** Electronic Kanda gross and tare vehicle weighing.
- **Hardware Integration:** 58mm/80mm thermal ESC/POS Kanda ticket printing.
- **Database Tables:** `weighbridge_tickets`.

## 4. Farmer Passbook & Advances (`farmer_passbook`, `advances`)
- **Purpose:** Digital passbook ledger showing crop deliveries and pre-harvest loan recovery.
- **Security:** RLS policies allow farmers read-only access strictly to their own rows via `auth.uid()`.
- **Database Tables:** `farmers`, `farmer_advances`, `ledger_entries`.

## 5. Storage, Bardana & 2D Grid (`storage`, `warehouse_grid`)
- **Purpose:** Tracking physical jute/plastic bags and visual spatial bay allocation.
- **Database Tables:** `storage_locations`, `storage_allocations`, `bardana_records`.

## 6. Daily Roznamcha & Ledgers (`reports`, `banking`)
- **Purpose:** Double-entry ledger calculation, daily cash in hand, bank reconciliation, and cheque book clearing.
- **Database Tables:** `ledger_entries`, `bank_accounts`, `cheques`.

# Mandi — Software QA Strategy & Test Execution Matrix (Phase 7)

## 1. QA Objectives
Ensure 100% mathematical accuracy on agricultural calculations (Maunds, weights, commissions, Palladari), verify zero-trust multi-tenant isolation, validate thermal printing and hardware fallbacks, and guarantee offline reliability.

## 2. Test Execution Coverage & Results

| Test ID | Module | Scenario Tested | Validation Target | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TC-01** | `core/utils` | Maund to KG conversion (`MandiCalculator`) | 1 Maund = 40.0 KG, exact fractionals | **PASSED** |
| **TC-02** | `core/utils` | Pakistani Mobile (`PkPhone`) normalization | Converts `0300...` to `+92300...`, rejects bad lengths | **PASSED** |
| **TC-03** | `core/utils` | CNIC Masking (`PkCnic`) | Masks 13 digits: `35202-*******-1` | **PASSED** |
| **TC-04** | `invoices` | Sales Invoice math with Commission & Palladari | Subtotal + Commission + Labor - Discount == Total | **PASSED** |
| **TC-05** | `auction_boli` | Live Boli Heap bidding transitions | Arrived -> Auctioning -> Sold -> Invoiced | **PASSED** |
| **TC-06** | `weighbridge` | Dharam Kanda Gross - Tare math | Gross KG - Tare KG = Net Maunds | **PASSED** |
| **TC-07** | `reports` | Roznamcha Daily Ledger double-entry | Sum(Debits) == Sum(Credits) checksum balance | **PASSED** |
| **TC-08** | `banking` | Cheque lifecycle & clearance tracking | Issued -> Deposited -> Cleared / Bounced | **PASSED** |
| **TC-09** | `storage` | Jute / Plastic Bardana bag tracking | Issued, returned, deposit balance | **PASSED** |
| **TC-10** | `advances` | Farmer seasonal advance recovery | Auto-deduction from invoice proceeds | **PASSED** |
| **TC-11** | `hardware` | ESC/POS Bluetooth raw command bytes | Init `0x1B, 0x40`, cut `0x1D, 0x56` | **PASSED** |
| **TC-12** | `security` | Biometric local_auth hardware state | Prompt configuration & settings toggle | **PASSED** |
| **TC-13** | `comms` | Telco SMS payload formatters | Jazz, Zong, Telenor, Twilio formatters | **PASSED** |
| **TC-14** | `backup` | Cloud backup verification checksum report | Entity counts & ledger integrity checks | **PASSED** |

## 3. Automation Summary
- **Total Test Suites:** 27 test files
- **Total Passing Automated Tests:** 227 tests
- **Static Code Analysis (`flutter analyze`):** 0 issues found (0 warnings, 0 errors).

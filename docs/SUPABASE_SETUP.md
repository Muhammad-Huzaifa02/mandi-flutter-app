# Supabase Database Deployment & Setup Guide

This guide walks you through setting up a fresh Supabase project for the **Mandi Application**.

---

## 1. Prerequisites
- Supabase account ([supabase.com](https://supabase.com))
- Supabase CLI installed (`npm install -g supabase`)

---

## 2. Deploy PostgreSQL Database Schema

1. Log into your Supabase Dashboard and navigate to **SQL Editor**.
2. Create a new query, paste the complete contents of `supabase/schema.sql`, and click **Run**.
3. Verify that all tables, functions, triggers, and Row Level Security policies are created:
   - Tables: `shops`, `roles`, `shop_memberships`, `customers`, `suppliers`, `products`, `invoices`, `invoice_items`, `expenses`, `payments`, `audit_logs`.
   - RPCs: `create_shop_with_owner`, `create_invoice_with_stock_deduction`, `cancel_invoice_and_restore_stock`.

---

## 3. Storage Buckets Setup

The schema script automatically creates public and private storage buckets:
- `shop-assets` (Public) — Shop logos and brand graphics.
- `product-images` (Public) — Product/commodity thumbnails.
- `avatars` (Public) — Profile pictures.
- `documents` (Private) — Invoice PDFs and ledger exports.

Verify bucket access policies under **Storage → Policies** in the Supabase Dashboard.

---

## 4. Deploy Deno Edge Functions

Staff account creation requires service-role privileges managed via Supabase Edge Functions:

```bash
# Login to Supabase CLI
supabase login

# Link your local project
supabase link --project-ref your-project-ref

# Deploy Edge Functions
supabase functions deploy create-staff
supabase functions deploy create-customer
supabase functions deploy create-supplier
```

---

## 5. Flutter App Configuration

Copy your Supabase project URL and Anonymous API Key from **Project Settings → API** and configure `lib/supabase_config.dart` or supply `--dart-define` parameters:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-publishable-key
```

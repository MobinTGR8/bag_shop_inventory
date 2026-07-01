# Bag Shop Inventory

Flutter + Supabase inventory management system tailored for bag shops.

## What this app covers

- Products: bag-specific fields (type, material, size, barcode)
- Inventory: warehouse stock, batches, movements, alerts
- Sales / POS: sales orders, split payments, and returns
- Purchases: suppliers, purchase orders, and receiving
- Reports: sales, stock, profit, valuation, and supplier performance

## Admin panel & staff management

This project includes an Admin Panel route and a safe staff onboarding approach:

- **Admins (Owner/Manager)**: access `/admin` and can create **invite codes** for staff.
- **Staff**: can register using an invite code and is linked to the company automatically.

Why invite codes? A mobile/Flutter client must **never** embed Supabase service-role keys.
Invite codes let staff join without privileged server access.

The admin panel also includes a **Seed demo catalog** action that creates a starter set of bag products, categories, brands, and inventory rows for the current company so you can exercise the app immediately after sign-in.

Operational tools are also built into the app for production support:

- **Backend Health**: checks Supabase connectivity, schema presence, and RLS-friendly reads.
- **Sync Queue**: shows queued offline actions and lets you retry or clear them.
- **Bulk Data Tools**: import/export CSV for products, suppliers, and customers.

## Supabase setup

1. Create a Supabase project.
2. Run the SQL schema in the root `sql` file in the Supabase SQL editor.
3. Ensure Row Level Security policies are enabled (the schema contains starter policies).

## Environment

- `SUPABASE_URL` and `SUPABASE_ANON_KEY` are read from `.env` at runtime.
- Keep secrets out of git history; the app is designed to run with a public anon key only.
- If you prefer, the same values can be supplied with `--dart-define` in CI or scripted runs.

## Local setup

1. Create `.env` (or copy from `.env.example`) and set:
	- `SUPABASE_URL`
	- `SUPABASE_ANON_KEY`
2. Install deps: `flutter pub get`
3. Run: `flutter run`

Tip: for CI/Web you can also pass config via `--dart-define`:
`flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

## Routes

- `/login` / `/register`
- `/` dashboard
- `/admin` admin panel (Owner/Manager only)
- `/admin/data-tools` bulk CSV import/export
- `/admin/staff` staff management (invite codes + staff list)
- `/admin/audit-log` stock movement audit log
- `/customers` customer list and edit flow
- `/purchases/suppliers` supplier list and edit flow
- `/purchases/:id` purchase details
- `/purchases/:id/receive` purchase receive flow
- `/inventory/low-stock` low stock alerts
- `/inventory/adjust` stock adjustment
- `/inventory/transfer` stock transfer
- `/inventory/stock-take` stock take
- `/sales` sales list
- `/sales/:id` sale details with invoice print/share
- `/sales/:id/return` sale return flow
- `/reports` reports hub
- `/reports/sales` sales report
- `/reports/stock` stock report
- `/reports/profit` profit report
- `/reports/valuation` inventory valuation report
- `/reports/suppliers` supplier performance report
- `/debug/backend-health` backend schema and RLS checks
- `/debug/sync-queue` offline outbox queue and retry tools
- `/debug/supabase` live Supabase read test

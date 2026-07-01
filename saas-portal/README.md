# Bag Shop Inventory — SaaS Admin Portal

A **separate web application** that adds SaaS capabilities (billing, plan management, super-admin) to your existing Flutter app. **No Flutter code changes needed.**

---

## Architecture Overview

```
┌─────────────────────────┐     ┌──────────────────────────────┐
│   Flutter Mobile App     │     │   SaaS Web Portal            │
│   (Untouched)            │     │   (Next.js 14)               │
│                          │     │                              │
│   - Regular shop use     │     │   /admin     → Super admin   │
│   - Reads/writes data    │     │   /settings  → Plan/billing  │
│     through Supabase     │     │   /api/*     → Webhooks      │
│   - Errors shown when    │     │                              │
│     plan limits hit      │     │                              │
└──────────┬───────────────┘     └──────────────┬───────────────┘
           │                                    │
           │         ┌──────────────────┐        │
           └────────►│   Supabase DB     │◄───────┘
                     │   (Same Project)  │
                     │                   │
                     │   companies:      │
                     │   - plan          │
                     │   - max_staff     │
                     │   - max_products  │
                     │   - sub_status    │
                     │                   │
                     │   super_admins:   │
                     │   - user_id       │
                     │                   │
                     │   DB Triggers:    │
                     │   - Check limits  │
                     └──────────────────┘
```

### How It Works (Without Touching Flutter)

1. **Shop Owner** uses the Flutter app as usual
2. When they hit a plan limit (e.g., 50 products on Free), the **database trigger** rejects the insert
3. The Flutter app shows the error: `"Product limit reached for your plan"`
4. The shop owner visits the **Web Portal** (`/settings`) to upgrade
5. **You** use the **Super Admin panel** (`/admin`) to manage all tenants
6. The web portal updates the `companies.plan` field, which raises the limits
7. The Flutter app now allows more products — **no update needed**

---

## Tech Stack

| Layer | Technology | Why |
|---|---|---|
| **Framework** | **Next.js 14** (App Router) | Industry standard, best Supabase integration, huge ecosystem |
| **UI** | Tailwind CSS + shadcn/ui | Pre-built admin components, fast development |
| **Database** | Supabase (PostgreSQL) | Same DB as your Flutter app |
| **Auth** | Supabase Auth | Same auth system as Flutter app |
| **Payments** | Dodo Payments (recommended) | Supports bKash, Nagad, cards; subscription management; webhooks |
| **Deployment** | Vercel | Free tier, push-to-deploy, environment variables |

---

## Project Structure

```
saas-portal/
├── README.md                        # This file
├── sql/
│   └── migration_001_saas_columns.sql  # Run this in Supabase SQL Editor
├── docs/
│   └── payment-integration.md       # Payment gateway setup guide
│
├── src/
│   ├── app/
│   │   ├── layout.tsx               # Root layout with Supabase auth
│   │   ├── page.tsx                 # Landing / redirect
│   │   ├── login/
│   │   │   └── page.tsx             # Login page
│   │   ├── admin/
│   │   │   ├── page.tsx             # Super admin dashboard
│   │   │   ├── companies/
│   │   │   │   └── [id]/
│   │   │   │       └── page.tsx     # Single company detail + plan mgmt
│   │   │   └── analytics/
│   │   │       └── page.tsx         # Usage analytics across tenants
│   │   └── settings/
│   │       └── page.tsx             # Shop owner's plan/billing page
│   │
│   ├── components/
│   │   ├── ui/                      # shadcn/ui components
│   │   ├── admin/
│   │   │   ├── CompanyTable.tsx     # Table listing all companies
│   │   │   ├── CompanyCard.tsx      # Company detail card
│   │   │   ├── PlanBadge.tsx        # Free/Basic/Pro badge
│   │   │   └── UsageBar.tsx         # Staff/product usage bar
│   │   └── settings/
│   │       ├── CurrentPlan.tsx      # Shows current plan details
│   │       ├── PlanSelector.tsx     # Upgrade/downgrade UI
│   │       └── BillingHistory.tsx   # Past invoices
│   │
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts            # Supabase browser client
│   │   │   └── admin.ts             # Supabase admin client (service_role)
│   │   ├── payments/
│   │   │   └── client.ts            # Dodo Payments client
│   │   └── utils.ts                 # Helpers
│   │
│   ├── app/api/
│   │   ├── checkout/route.ts        # Create Dodo checkout session
│   │   └── webhooks/dodo/route.ts   # Handle subscription events
│   │
│   └── types/
│       └── index.ts                 # TypeScript types
│
├── .env.local.example               # Environment variables template
├── next.config.js
├── tailwind.config.js
├── package.json
└── tsconfig.json
```

---

## Plans & Pricing (Suggested)

| Feature | Free | Basic | Pro | Enterprise |
|---|---|---|---|---|
| **Price** | Tk 0 | Tk 500/mo | Tk 1,500/mo | Custom |
| **Staff users** | 2 | 5 | 15 | Unlimited |
| **Products** | 50 | 500 | 5,000 | Unlimited |
| **Warehouses** | 1 | 3 | 10 | Unlimited |
| **Reports** | Basic | Standard | Advanced | Custom |
| **Support** | — | Email | Priority | Dedicated |

---

## Setup Steps

### Step 1: Database Migration

Open your Supabase SQL Editor and run:
```
saas-portal/sql/migration_001_saas_columns.sql
```

This adds the plan columns, limit triggers, and super_admin table without changing any existing data.

### Step 2: Create the Web App

```bash
npx create-next-app@latest saas-portal --typescript --tailwind --app
cd saas-portal
npm install @supabase/supabase-js @supabase/ssr
npm install shadcn-ui
npx shadcn-ui@latest init
```

### Step 3: Configure Environment

Copy `.env.local.example` to `.env.local` and add:
- `NEXT_PUBLIC_SUPABASE_URL` (same as your Flutter app)
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` (same as your Flutter app)
- `SUPABASE_SERVICE_ROLE_KEY` (from Supabase Dashboard → Settings → API)
- `DODO_API_KEY` (from Dodo Payments dashboard)

### Step 4: Make Yourself a Super Admin

Run in Supabase SQL Editor:
```sql
INSERT INTO super_admins (user_id)
VALUES ('your-auth-user-id-here');
```

### Step 5: Deploy

Push to GitHub → Connect to Vercel → Deploy

---

## Payment Integration

### Recommended: Dodo Payments

[Dodo Payments](https://dodopayments.com) is the best fit for Bangladesh because:
- ✅ Supports **bKash** and **Nagad**
- ✅ Supports **credit/debit cards** (Visa, Mastercard)
- ✅ **Subscription management** built-in (recurring billing)
- ✅ **Webhook** support for subscription events
- ✅ **Merchant of Record** — handles tax compliance
- ✅ API-based, easy to integrate

### Setup Flow

1. Create a Dodo Payments account
2. Create plans in Dodo dashboard (Free, Basic, Pro)
3. When a shop owner upgrades, redirect them to Dodo checkout
4. Dodo sends a `subscription.active` webhook
5. Your web portal catches the webhook and updates `companies.plan`
6. The Flutter app respects the new limits via DB triggers

---

## Development Phases

### Phase 1: Foundation (1-2 days)
- [ ] Run SQL migration
- [ ] Create Next.js app with Supabase auth
- [ ] Build Super Admin login
- [ ] Build companies list table

### Phase 2: Plan Management (2-3 days)
- [ ] Company detail page with plan controls
- [ ] Plan badge and usage bars
- [ ] Manual plan upgrade/downgrade in admin

### Phase 3: Shop Owner Portal (2-3 days)
- [ ] `/settings` page showing current plan
- [ ] Plan comparison/upgrade UI
- [ ] "Contact us to upgrade" flow

### Phase 4: Billing (3-5 days)
- [ ] Integrate Dodo Payments
- [ ] Create subscription checkout flow
- [ ] Webhook handler for subscription events
- [ ] Automated plan updates

### Phase 5: Analytics (2-3 days)
- [ ] Usage tracking per company
- [ ] Revenue dashboard
- [ ] MRR/ARR metrics

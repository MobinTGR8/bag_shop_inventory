-- ============================================================================
-- Migration 001: SaaS Columns & Plan Enforcement
-- Run this in your Supabase SQL Editor. Safe to run on existing data.
-- ============================================================================

-- 1. ADD SAAS COLUMNS TO COMPANIES TABLE ------------------------------------
-- These are the foundation of all SaaS functionality.
-- Your Flutter app ignores unknown columns, so this won't break anything.

ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS plan TEXT NOT NULL DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS subscription_status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS max_staff INTEGER NOT NULL DEFAULT 3,
  ADD COLUMN IF NOT EXISTS max_products INTEGER NOT NULL DEFAULT 50,
  ADD COLUMN IF NOT EXISTS max_warehouses INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS dodo_customer_id TEXT;

COMMENT ON COLUMN companies.plan IS 'free, basic, pro, enterprise';
COMMENT ON COLUMN companies.subscription_status IS 'active, trial, expired, cancelled, past_due';
COMMENT ON COLUMN companies.max_staff IS 'Maximum number of staff users allowed';
COMMENT ON COLUMN companies.max_products IS 'Maximum number of products allowed';
COMMENT ON COLUMN companies.max_warehouses IS 'Maximum number of warehouses allowed';


-- 2. UPDATE DEFAULT LIMITS BASED ON PLAN (run once for existing companies) ---

UPDATE companies
SET
  max_staff = 5,
  max_products = 100,
  max_warehouses = 3
WHERE plan = 'basic';

UPDATE companies
SET
  max_staff = 15,
  max_products = 5000,
  max_warehouses = 10
WHERE plan = 'pro';

UPDATE companies
SET
  max_staff = 999999,
  max_products = 999999,
  max_warehouses = 999999
WHERE plan = 'enterprise';


-- 3. CREATE SUPER_ADMINS TABLE ----------------------------------------------
-- Users listed here can access the SaaS admin web portal.

CREATE TABLE IF NOT EXISTS super_admins (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Allow super_admins to SELECT their own row (needed by AuthProvider)
ALTER TABLE super_admins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Super admins can read own row" ON super_admins;
CREATE POLICY "Super admins can read own row"
  ON super_admins FOR SELECT
  USING (auth.uid() = user_id);


-- 4. PLAN LIMIT TRIGGER FUNCTIONS -------------------------------------------
-- These triggers enforce limits at the database level.
-- The Flutter app does NOT need to check limits — the DB rejects violations,
-- and Flutter shows the error message. Zero app changes.

-- 4a. Staff limit check

CREATE OR REPLACE FUNCTION check_staff_limit()
RETURNS TRIGGER AS $$
DECLARE
  limit_val INTEGER;
  current_count INTEGER;
BEGIN
  SELECT max_staff INTO limit_val FROM companies WHERE id = NEW.company_id;
  SELECT COUNT(*) INTO current_count FROM staff WHERE company_id = NEW.company_id;

  IF current_count >= limit_val THEN
    RAISE EXCEPTION 'Staff limit reached for your % plan. Upgrade to add more staff.',
      (SELECT plan FROM companies WHERE id = NEW.company_id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_staff_limit ON staff;
CREATE TRIGGER enforce_staff_limit
  BEFORE INSERT ON staff
  FOR EACH ROW
  EXECUTE FUNCTION check_staff_limit();


-- 4b. Product limit check

CREATE OR REPLACE FUNCTION check_product_limit()
RETURNS TRIGGER AS $$
DECLARE
  limit_val INTEGER;
  current_count INTEGER;
BEGIN
  SELECT max_products INTO limit_val FROM companies WHERE id = NEW.company_id;
  SELECT COUNT(*) INTO current_count FROM products WHERE company_id = NEW.company_id;

  IF current_count >= limit_val THEN
    RAISE EXCEPTION 'Product limit reached for your % plan. Upgrade to add more products.',
      (SELECT plan FROM companies WHERE id = NEW.company_id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_product_limit ON products;
CREATE TRIGGER enforce_product_limit
  BEFORE INSERT ON products
  FOR EACH ROW
  EXECUTE FUNCTION check_product_limit();


-- 4c. Warehouse limit check

CREATE OR REPLACE FUNCTION check_warehouse_limit()
RETURNS TRIGGER AS $$
DECLARE
  limit_val INTEGER;
  current_count INTEGER;
BEGIN
  SELECT max_warehouses INTO limit_val FROM companies WHERE id = NEW.company_id;
  SELECT COUNT(*) INTO current_count FROM warehouses WHERE company_id = NEW.company_id;

  IF current_count >= limit_val THEN
    RAISE EXCEPTION 'Warehouse limit reached for your % plan. Upgrade to add more warehouses.',
      (SELECT plan FROM companies WHERE id = NEW.company_id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_warehouse_limit ON warehouses;
CREATE TRIGGER enforce_warehouse_limit
  BEFORE INSERT ON warehouses
  FOR EACH ROW
  EXECUTE FUNCTION check_warehouse_limit();


-- 5. RLS POLICY FOR SUPER ADMINS -------------------------------------------
-- Super admins can read all company data (for the admin panel).

-- Allow super_admins to SELECT from companies
DROP POLICY IF EXISTS "Super admins can view all companies" ON companies;
CREATE POLICY "Super admins can view all companies"
  ON companies FOR SELECT
  USING (
    auth.uid() IN (SELECT user_id FROM super_admins)
  );

-- Allow super_admins to UPDATE companies (for plan management)
DROP POLICY IF EXISTS "Super admins can update any company" ON companies;
CREATE POLICY "Super admins can update any company"
  ON companies FOR UPDATE
  USING (
    auth.uid() IN (SELECT user_id FROM super_admins)
  )
  WITH CHECK (
    auth.uid() IN (SELECT user_id FROM super_admins)
  );

-- Note: The web portal's super admin panel fetches data via Next.js API routes
-- (src/app/api/admin/*) that use the service_role key, bypassing RLS entirely.
-- The RLS policies on companies above are a fallback for direct queries, but
-- the primary data flow goes through API routes for security and completeness.
-- The super_admins table is used for application-level authorization (checking
-- if a user is allowed to access the admin panel).


-- 6. HELPER VIEW: TENANT USAGE ---------------------------------------------

CREATE OR REPLACE VIEW tenant_usage AS
SELECT
  c.id AS company_id,
  c.shop_name,
  c.plan,
  c.subscription_status,
  c.created_at,
  COALESCE(staff_counts.cnt, 0) AS staff_count,
  COALESCE(product_counts.cnt, 0) AS product_count,
  COALESCE(warehouse_counts.cnt, 0) AS warehouse_count,
  c.max_staff,
  c.max_products,
  c.max_warehouses
FROM companies c
LEFT JOIN (
  SELECT company_id, COUNT(*) AS cnt FROM staff GROUP BY company_id
) staff_counts ON staff_counts.company_id = c.id
LEFT JOIN (
  SELECT company_id, COUNT(*) AS cnt FROM products GROUP BY company_id
) product_counts ON product_counts.company_id = c.id
LEFT JOIN (
  SELECT company_id, COUNT(*) AS cnt FROM warehouses GROUP BY company_id
) warehouse_counts ON warehouse_counts.company_id = c.id;


-- 7. VERIFICATION QUERIES (run these to confirm the migration worked) -------

-- Check that new columns exist
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'companies' AND column_name IN ('plan','subscription_status','max_staff','max_products','max_warehouses');

-- Check that triggers exist
-- SELECT trigger_name, event_manipulation FROM information_schema.triggers
-- WHERE event_object_table IN ('staff', 'products', 'warehouses');

-- Check all tenants and their limits
-- SELECT shop_name, plan, subscription_status, max_staff, max_products FROM companies;

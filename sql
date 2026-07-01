-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create companies table
CREATE TABLE IF NOT EXISTS companies (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  shop_name VARCHAR(255),
  address TEXT,
  phone VARCHAR(50),
  email VARCHAR(255),
  logo_url TEXT,
  currency VARCHAR(10) DEFAULT '₹',
  tax_rate DECIMAL(5,2) DEFAULT 0,
  owner_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Bag Categories specific to bag shop
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  color VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Brands table for bags
CREATE TABLE IF NOT EXISTS brands (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  logo_url TEXT,
  website VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Products table with bag-specific fields
CREATE TABLE IF NOT EXISTS products (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  sku VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- Bag specific fields
  category_id UUID REFERENCES categories(id),
  brand_id UUID REFERENCES brands(id),
  bag_type VARCHAR(50), -- Backpack, Handbag, Tote, Wallet, etc.
  material VARCHAR(100), -- Leather, Canvas, Nylon, etc.
  color VARCHAR(50),
  size VARCHAR(50), -- Small, Medium, Large
  dimensions VARCHAR(100), -- L x W x H
  weight_grams DECIMAL(8,2),
  
  -- Inventory fields
  barcode VARCHAR(100),
  qr_code TEXT,
  unit_cost DECIMAL(12,2) NOT NULL,
  selling_price DECIMAL(12,2) NOT NULL,
  wholesale_price DECIMAL(12,2),
  
  -- Stock control
  min_stock INTEGER DEFAULT 5,
  max_stock INTEGER,
  reorder_point INTEGER,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  has_warranty BOOLEAN DEFAULT false,
  warranty_months INTEGER DEFAULT 0,
  
  -- Media
  image_urls TEXT[], -- Array of image URLs
  video_url TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Warehouses/Storage locations
CREATE TABLE IF NOT EXISTS warehouses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) DEFAULT 'SHOWROOM', -- SHOWROOM, STORAGE, STORE
  location VARCHAR(500),
  manager VARCHAR(255),
  phone VARCHAR(50),
  is_default BOOLEAN DEFAULT false,
  capacity INTEGER, -- Number of bags capacity
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Inventory tracking with batch/lot for bags
CREATE TABLE IF NOT EXISTS inventory (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  warehouse_id UUID REFERENCES warehouses(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 0,
  reserved_quantity INTEGER DEFAULT 0,
  available_quantity INTEGER GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
  
  -- Batch info for bags
  batch_number VARCHAR(100),
  manufacturing_date DATE,
  expiry_date DATE, -- For bags with perishable materials
  
  -- Quality info
  condition VARCHAR(50) DEFAULT 'NEW', -- NEW, DISPLAY, DAMAGED
  notes TEXT,
  
  last_counted TIMESTAMP WITH TIME ZONE,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  
  UNIQUE(product_id, warehouse_id, batch_number)
);

-- Suppliers for bags
CREATE TABLE IF NOT EXISTS suppliers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) DEFAULT 'WHOLESALER', -- MANUFACTURER, WHOLESALER, IMPORTER
  contact_person VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  payment_terms VARCHAR(100),
  rating INTEGER DEFAULT 5,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Purchase Orders
CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  supplier_id UUID REFERENCES suppliers(id),
  po_number VARCHAR(100) UNIQUE NOT NULL,
  status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, ORDERED, RECEIVED, CANCELLED
  order_date DATE DEFAULT CURRENT_DATE,
  expected_delivery DATE,
  actual_delivery DATE,
  
  -- Financials
  subtotal DECIMAL(12,2) DEFAULT 0,
  tax_amount DECIMAL(12,2) DEFAULT 0,
  shipping_cost DECIMAL(12,2) DEFAULT 0,
  discount_amount DECIMAL(12,2) DEFAULT 0,
  total_amount DECIMAL(12,2) DEFAULT 0,
  
  -- Shipping
  shipping_method VARCHAR(100),
  tracking_number VARCHAR(100),
  
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Purchase Order Items
CREATE TABLE IF NOT EXISTS purchase_order_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  purchase_order_id UUID REFERENCES purchase_orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  quantity INTEGER NOT NULL,
  unit_cost DECIMAL(12,2),
  warehouse_id UUID REFERENCES warehouses(id),
  batch_number VARCHAR(100),
  received_quantity INTEGER DEFAULT 0,
  notes TEXT
);

-- Customers
CREATE TABLE IF NOT EXISTS customers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  customer_type VARCHAR(50) DEFAULT 'RETAIL', -- RETAIL, WHOLESALE, CORPORATE
  tax_number VARCHAR(100),
  credit_limit DECIMAL(12,2) DEFAULT 0,
  outstanding_balance DECIMAL(12,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Sales Orders
CREATE TABLE IF NOT EXISTS sales_orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id),
  invoice_number VARCHAR(100) UNIQUE NOT NULL,
  status VARCHAR(50) DEFAULT 'PENDING', -- QUOTATION, CONFIRMED, PACKED, SHIPPED, DELIVERED, CANCELLED
  
  -- Sale info
  sale_date DATE DEFAULT CURRENT_DATE,
  due_date DATE,
  
  -- Financials
  subtotal DECIMAL(12,2) DEFAULT 0,
  tax_amount DECIMAL(12,2) DEFAULT 0,
  discount_amount DECIMAL(12,2) DEFAULT 0,
  shipping_charge DECIMAL(12,2) DEFAULT 0,
  total_amount DECIMAL(12,2) DEFAULT 0,
  amount_paid DECIMAL(12,2) DEFAULT 0,
  balance_due DECIMAL(12,2) GENERATED ALWAYS AS (total_amount - amount_paid) STORED,
  
  -- Payment
  payment_method VARCHAR(50),
  payment_status VARCHAR(50) DEFAULT 'PENDING',
  payment_split JSONB,
  
  -- Shipping
  shipping_address TEXT,
  shipping_method VARCHAR(100),
  tracking_number VARCHAR(100),
  
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Sales Order Items
CREATE TABLE IF NOT EXISTS sales_order_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  sales_order_id UUID REFERENCES sales_orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(12,2),
  discount_percent DECIMAL(5,2) DEFAULT 0,
  line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price * (1 - discount_percent/100)) STORED,
  warehouse_id UUID REFERENCES warehouses(id),
  notes TEXT
);

-- Stock Movements (Audit Trail)
CREATE TABLE IF NOT EXISTS stock_movements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  warehouse_id UUID REFERENCES warehouses(id),
  
  movement_type VARCHAR(50) NOT NULL CHECK (
    movement_type IN ('PURCHASE', 'SALE', 'RETURN', 'ADJUSTMENT', 'TRANSFER', 'DAMAGE', 'SAMPLE')
  ),
  
  quantity_change INTEGER NOT NULL,
  quantity_before INTEGER NOT NULL,
  quantity_after INTEGER GENERATED ALWAYS AS (quantity_before + quantity_change) STORED,
  
  reference_type VARCHAR(50), -- PURCHASE_ORDER, SALES_ORDER, MANUAL_ADJUSTMENT
  reference_id UUID,
  
  batch_number VARCHAR(100),
  notes TEXT,
  
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Stock Transfers between warehouses
CREATE TABLE IF NOT EXISTS stock_transfers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  transfer_number VARCHAR(100) UNIQUE NOT NULL,
  
  from_warehouse_id UUID REFERENCES warehouses(id),
  to_warehouse_id UUID REFERENCES warehouses(id),
  
  status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, IN_TRANSIT, COMPLETED, CANCELLED
  transfer_date DATE DEFAULT CURRENT_DATE,
  expected_completion DATE,
  actual_completion DATE,
  
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Stock Transfer Items
CREATE TABLE IF NOT EXISTS stock_transfer_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  stock_transfer_id UUID REFERENCES stock_transfers(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  quantity INTEGER NOT NULL,
  batch_number VARCHAR(100),
  status VARCHAR(50) DEFAULT 'PENDING',
  notes TEXT
);

-- Low Stock Alerts
CREATE TABLE IF NOT EXISTS stock_alerts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  warehouse_id UUID REFERENCES warehouses(id),
  alert_type VARCHAR(50) CHECK (alert_type IN ('LOW_STOCK', 'OUT_OF_STOCK', 'EXPIRING', 'OVER_STOCK')),
  current_quantity INTEGER,
  threshold_quantity INTEGER,
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Staff/Users with roles
CREATE TABLE IF NOT EXISTS staff (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  role VARCHAR(50) DEFAULT 'STAFF', -- OWNER, MANAGER, STAFF, ACCOUNTANT
  permissions TEXT[], -- Array of permissions
  is_active BOOLEAN DEFAULT true,
  joined_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Staff invite codes (safe staff onboarding without service-role key)
CREATE TABLE IF NOT EXISTS staff_invites (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  invite_code VARCHAR(64) UNIQUE NOT NULL,
  role VARCHAR(50) DEFAULT 'STAFF',
  permissions TEXT[],
  expires_at TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  used_at TIMESTAMP WITH TIME ZONE,
  used_by UUID REFERENCES auth.users(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_products_company ON products(company_id);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand_id);
CREATE INDEX IF NOT EXISTS idx_inventory_product ON inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_warehouse ON inventory(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_date ON stock_movements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_orders_date ON sales_orders(sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_date ON purchase_orders(order_date DESC);

-- Create storage bucket for bag images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('bag-images', 'bag-images', true)
ON CONFLICT (id) DO NOTHING;

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers to tables with updated_at
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at 
    BEFORE UPDATE ON products 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sales_orders_updated_at ON sales_orders;
CREATE TRIGGER update_sales_orders_updated_at 
    BEFORE UPDATE ON sales_orders 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to generate invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invoice_number IS NULL THEN
        NEW.invoice_number := 'INV-' || 
            TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' ||
            LPAD(NEW.id::text, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS set_invoice_number ON sales_orders;
CREATE TRIGGER set_invoice_number
    BEFORE INSERT ON sales_orders
    FOR EACH ROW EXECUTE FUNCTION generate_invoice_number();

-- Create function to update inventory on stock movement
CREATE OR REPLACE FUNCTION update_inventory_on_movement()
RETURNS TRIGGER AS $$
BEGIN
    -- Update inventory quantity
    UPDATE inventory 
    SET quantity = quantity + NEW.quantity_change,
        last_updated = TIMEZONE('utc', NOW())
    WHERE product_id = NEW.product_id 
      AND warehouse_id = NEW.warehouse_id
      AND (batch_number = NEW.batch_number OR (batch_number IS NULL AND NEW.batch_number IS NULL));
    
    -- If no row exists, insert one
    IF NOT FOUND THEN
        INSERT INTO inventory (product_id, warehouse_id, quantity, batch_number)
        VALUES (NEW.product_id, NEW.warehouse_id, NEW.quantity_change, NEW.batch_number);
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS inventory_update_trigger ON stock_movements;
CREATE TRIGGER inventory_update_trigger
    AFTER INSERT ON stock_movements
    FOR EACH ROW EXECUTE FUNCTION update_inventory_on_movement();

-- Enable Row Level Security
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_invites ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
DROP POLICY IF EXISTS "Users can only access their company data" ON products;
CREATE POLICY "Users can only access their company data"
    ON products FOR ALL
    USING (company_id IN (
        SELECT id FROM companies WHERE owner_id = auth.uid()
        UNION
        SELECT company_id FROM staff WHERE user_id = auth.uid()
    ));

-- Inventory policies (inventory has no company_id; filter through warehouses)
DROP POLICY IF EXISTS "Users can access company inventory" ON inventory;
CREATE POLICY "Users can access company inventory"
  ON inventory FOR ALL
  USING (warehouse_id IN (
    SELECT w.id FROM warehouses w
    WHERE w.company_id IN (
      SELECT id FROM companies WHERE owner_id = auth.uid()
      UNION
      SELECT company_id FROM staff WHERE user_id = auth.uid()
    )
  ));

-- Sales orders policies
DROP POLICY IF EXISTS "Users can access company sales orders" ON sales_orders;
CREATE POLICY "Users can access company sales orders"
  ON sales_orders FOR ALL
  USING (company_id IN (
    SELECT id FROM companies WHERE owner_id = auth.uid()
    UNION
    SELECT company_id FROM staff WHERE user_id = auth.uid()
  ));

-- Sales order items policies (items have no company_id)
DROP POLICY IF EXISTS "Users can access company sales order items" ON sales_order_items;
CREATE POLICY "Users can access company sales order items"
  ON sales_order_items FOR ALL
  USING (sales_order_id IN (
    SELECT so.id FROM sales_orders so
    WHERE so.company_id IN (
      SELECT id FROM companies WHERE owner_id = auth.uid()
      UNION
      SELECT company_id FROM staff WHERE user_id = auth.uid()
    )
  ));

-- Purchase orders policies
DROP POLICY IF EXISTS "Users can access company purchase orders" ON purchase_orders;
CREATE POLICY "Users can access company purchase orders"
  ON purchase_orders FOR ALL
  USING (company_id IN (
    SELECT id FROM companies WHERE owner_id = auth.uid()
    UNION
    SELECT company_id FROM staff WHERE user_id = auth.uid()
  ));

-- Purchase order items policies (items have no company_id)
DROP POLICY IF EXISTS "Users can access company purchase order items" ON purchase_order_items;
CREATE POLICY "Users can access company purchase order items"
  ON purchase_order_items FOR ALL
  USING (purchase_order_id IN (
    SELECT po.id FROM purchase_orders po
    WHERE po.company_id IN (
      SELECT id FROM companies WHERE owner_id = auth.uid()
      UNION
      SELECT company_id FROM staff WHERE user_id = auth.uid()
    )
  ));

-- Stock movements policies
DROP POLICY IF EXISTS "Users can access company stock movements" ON stock_movements;
CREATE POLICY "Users can access company stock movements"
  ON stock_movements FOR ALL
  USING (company_id IN (
    SELECT id FROM companies WHERE owner_id = auth.uid()
    UNION
    SELECT company_id FROM staff WHERE user_id = auth.uid()
  ));

-- Staff table policies
-- IMPORTANT: Avoid querying the same table inside its own policy (causes
-- "infinite recursion detected in policy" errors).
DROP POLICY IF EXISTS "Staff can read company staff" ON staff;
DROP POLICY IF EXISTS "Admins can manage staff" ON staff;

-- Staff can always read their own staff row.
CREATE POLICY "Staff can read own staff row"
  ON staff FOR SELECT
  USING (user_id = auth.uid());

-- Company owner can manage all staff rows in their company.
CREATE POLICY "Owner can manage staff"
  ON staff FOR ALL
  USING (company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid()))
  WITH CHECK (company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid()));

-- Staff invites policies (admins only)
DROP POLICY IF EXISTS "Admins can manage staff invites" ON staff_invites;

-- Keep invites management owner-only to keep policies simple and safe.
CREATE POLICY "Owner can manage staff invites"
  ON staff_invites FOR ALL
  USING (company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid()))
  WITH CHECK (company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid()));

-- Insert default bag categories
INSERT INTO categories (name, description, icon, color)
SELECT v.name, v.description, v.icon, v.color
FROM (
  VALUES
    ('Backpacks', 'School, travel, and laptop backpacks', 'backpack', '#4CAF50'),
    ('Handbags', 'Ladies handbags and purses', 'handbag', '#FF9800'),
    ('Tote Bags', 'Large carry bags', 'shopping', '#2196F3'),
    ('Wallets', 'Leather wallets and card holders', 'wallet', '#9C27B0'),
    ('Luggage', 'Suitcases and travel bags', 'luggage', '#FF5722'),
    ('Messenger Bags', 'Cross-body and shoulder bags', 'bag_personal', '#795548'),
    ('Duffle Bags', 'Sports and gym bags', 'sports', '#00BCD4'),
    ('Clutches', 'Evening and party clutches', 'diamond', '#E91E63')
) AS v(name, description, icon, color)
WHERE NOT EXISTS (
  SELECT 1
  FROM categories c
  WHERE c.name = v.name
    AND c.company_id IS NULL
);

-- Create view for low stock products
CREATE OR REPLACE VIEW low_stock_products AS
SELECT 
    p.id,
    p.sku,
    p.name,
    p.min_stock,
    SUM(i.available_quantity) as current_stock,
    ARRAY_AGG(w.name) as warehouses
FROM products p
JOIN inventory i ON p.id = i.product_id
JOIN warehouses w ON i.warehouse_id = w.id
WHERE p.is_active = true
GROUP BY p.id, p.sku, p.name, p.min_stock
HAVING SUM(i.available_quantity) <= p.min_stock;
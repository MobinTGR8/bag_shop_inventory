export interface Company {
  id: string;
  name: string;
  shop_name: string;
  address?: string;
  phone?: string;
  email?: string;
  logo_url?: string;
  owner_id: string;
  created_at: string;

  // SaaS columns (added by migration)
  plan: 'free' | 'basic' | 'pro' | 'enterprise';
  subscription_status: 'active' | 'trial' | 'expired' | 'cancelled' | 'past_due';
  trial_ends_at?: string;
  max_staff: number;
  max_products: number;
  max_warehouses: number;
  dodo_customer_id?: string;
}

export interface TenantUsage {
  company_id: string;
  shop_name: string;
  plan: string;
  subscription_status: string;
  created_at: string;
  staff_count: number;
  product_count: number;
  warehouse_count: number;
  max_staff: number;
  max_products: number;
  max_warehouses: number;
}

export interface StaffMember {
  id: string;
  company_id: string;
  user_id: string;
  name: string;
  email: string;
  role: string;
  is_active: boolean;
}

export interface Product {
  id: string;
  company_id: string;
  name: string;
  sku: string;
  is_active: boolean;
}

export interface PlanConfig {
  key: 'free' | 'basic' | 'pro' | 'enterprise';
  label: string;
  price: string;
  max_staff: number;
  max_products: number;
  max_warehouses: number;
  color: string;
  description: string;
}

export const PLANS: PlanConfig[] = [
  {
    key: 'free',
    label: 'Free',
    price: 'Tk 0',
    max_staff: 3,
    max_products: 50,
    max_warehouses: 1,
    color: 'bg-gray-100 text-gray-800',
    description: 'For small shops just getting started',
  },
  {
    key: 'basic',
    label: 'Basic',
    price: 'Tk 500/mo',
    max_staff: 5,
    max_products: 500,
    max_warehouses: 3,
    color: 'bg-blue-100 text-blue-800',
    description: 'For growing bag shops',
  },
  {
    key: 'pro',
    label: 'Pro',
    price: 'Tk 1,500/mo',
    max_staff: 15,
    max_products: 5000,
    max_warehouses: 10,
    color: 'bg-purple-100 text-purple-800',
    description: 'For established businesses',
  },
  {
    key: 'enterprise',
    label: 'Enterprise',
    price: 'Custom',
    max_staff: 999999,
    max_products: 999999,
    max_warehouses: 999999,
    color: 'bg-amber-100 text-amber-800',
    description: 'For chains and large operations',
  },
];

export function getPlanConfig(plan: string): PlanConfig {
  return PLANS.find((p) => p.key === plan) ?? PLANS[0];
}

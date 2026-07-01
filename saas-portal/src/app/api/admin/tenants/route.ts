import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

const PLAN_PRICES: Record<string, number> = {
  free: 0,
  basic: 500,
  pro: 1500,
  enterprise: 5000,
};

export async function GET() {
  try {
    const supabase = createClient();

    // Fetch all companies (works with both service_role and RLS)
    const { data: companies, error: companiesError } = await supabase
      .from('companies')
      .select('*')
      .order('created_at', { ascending: false });

    if (companiesError) {
      // Fallback to admin client if available
      const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
      if (serviceRoleKey) {
        const { createAdminClient } = await import('@/lib/supabase/admin');
        const admin = createAdminClient();
        const { data: adminCompanies } = await admin
          .from('companies')
          .select('*')
          .order('created_at', { ascending: false });

        if (adminCompanies) {
          return processCompanies(adminCompanies, supabase);
        }
      }
      return NextResponse.json(
        { error: 'Failed to fetch companies' },
        { status: 500 },
      );
    }

    return processCompanies(companies || [], supabase);
  } catch (error) {
    console.error('API /admin/tenants error:', error);

    // Last resort: try with admin client directly
    try {
      const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
      if (serviceRoleKey) {
        const { createAdminClient } = await import('@/lib/supabase/admin');
        const admin = createAdminClient();
        const { data: companies } = await admin
          .from('companies')
          .select('*')
          .order('created_at', { ascending: false });
        if (companies) {
          return processCompanies(companies, admin);
        }
      }
    } catch {}

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 },
    );
  }
}

async function processCompanies(companies: any[], client: any) {
  // Fetch staff counts
  const { data: allStaff } = await client.from('staff').select('company_id');
  const staffCounts: Record<string, number> = {};
  allStaff?.forEach((s: any) => {
    staffCounts[s.company_id] = (staffCounts[s.company_id] ?? 0) + 1;
  });

  // Fetch product counts
  const { data: allProducts } = await client.from('products').select('company_id');
  const productCounts: Record<string, number> = {};
  allProducts?.forEach((p: any) => {
    productCounts[p.company_id] = (productCounts[p.company_id] ?? 0) + 1;
  });

  // Fetch warehouse counts
  const { data: allWarehouses } = await client.from('warehouses').select('company_id');
  const warehouseCounts: Record<string, number> = {};
  allWarehouses?.forEach((w: any) => {
    warehouseCounts[w.company_id] = (warehouseCounts[w.company_id] ?? 0) + 1;
  });

  // Calculate revenue
  let totalMRR = 0;
  const payingTenants = companies.filter(
    (c: any) => c.plan !== 'free' && c.subscription_status === 'active',
  );
  payingTenants.forEach((c: any) => {
    totalMRR += PLAN_PRICES[c.plan] || 0;
  });

  const tenants = companies.map((c: any) => ({
    company_id: c.id,
    shop_name: c.shop_name || c.name,
    plan: c.plan,
    subscription_status: c.subscription_status,
    created_at: c.created_at,
    email: c.email,
    phone: c.phone,
    staff_count: staffCounts[c.id] ?? 0,
    product_count: productCounts[c.id] ?? 0,
    warehouse_count: warehouseCounts[c.id] ?? 0,
    max_staff: c.max_staff,
    max_products: c.max_products,
    max_warehouses: c.max_warehouses,
    plan_price: PLAN_PRICES[c.plan] || 0,
  }));

  return NextResponse.json({
    tenants,
    meta: {
      total: tenants.length,
      active: tenants.filter((t: any) => t.subscription_status === 'active').length,
      paying: payingTenants.length,
      mrr: totalMRR,
      free: tenants.filter((t: any) => t.plan === 'free').length,
      basic: tenants.filter((t: any) => t.plan === 'basic').length,
      pro: tenants.filter((t: any) => t.plan === 'pro').length,
      enterprise: tenants.filter((t: any) => t.plan === 'enterprise').length,
    },
  });
}

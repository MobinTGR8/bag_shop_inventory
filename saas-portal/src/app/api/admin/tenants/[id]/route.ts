import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

// GET /api/admin/tenants/[id] — Fetch single company with usage
export async function GET(
  _request: NextRequest,
  { params }: { params: { id: string } },
) {
  try {
    const supabase = createAdminClient();

    const { data: company, error } = await supabase
      .from('companies')
      .select('*')
      .eq('id', params.id)
      .single();

    if (error || !company) {
      return NextResponse.json(
        { error: 'Company not found' },
        { status: 404 },
      );
    }

    // Get staff count
    const { data: staffRows } = await supabase
      .from('staff')
      .select('id')
      .eq('company_id', params.id);

    // Get product count
    const { data: productRows } = await supabase
      .from('products')
      .select('id')
      .eq('company_id', params.id);

    // Get warehouse count
    const { data: warehouseRows } = await supabase
      .from('warehouses')
      .select('id')
      .eq('company_id', params.id);

    const usage = {
      staff_count: staffRows?.length ?? 0,
      product_count: productRows?.length ?? 0,
      warehouse_count: warehouseRows?.length ?? 0,
    };

    return NextResponse.json({ company, usage });
  } catch (error) {
    console.error('API /admin/tenants/[id] GET error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 },
    );
  }
}

// PATCH /api/admin/tenants/[id] — Update company plan, status, etc.
export async function PATCH(
  request: NextRequest,
  { params }: { params: { id: string } },
) {
  try {
    const body = await request.json();
    const supabase = createAdminClient();

    // Only allow updating specific fields
    const allowedFields = [
      'plan',
      'subscription_status',
      'max_staff',
      'max_products',
      'max_warehouses',
    ];
    const updates: Record<string, any> = {};
    for (const field of allowedFields) {
      if (body[field] !== undefined) {
        updates[field] = body[field];
      }
    }

    if (Object.keys(updates).length === 0) {
      return NextResponse.json(
        { error: 'No valid fields to update' },
        { status: 400 },
      );
    }

    const { data, error } = await supabase
      .from('companies')
      .update(updates)
      .eq('id', params.id)
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ company: data });
  } catch (error) {
    console.error('API /admin/tenants/[id] PATCH error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 },
    );
  }
}

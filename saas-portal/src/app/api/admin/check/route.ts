import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ isSuperAdmin: false });
    }

    // Check if SUPABASE_SERVICE_ROLE_KEY is configured
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!serviceRoleKey) {
      // Fallback: query super_admins directly using the anon key + RLS
      // This requires the RLS policy we added: "Users can read own super_admin row"
      const { data } = await supabase
        .from('super_admins')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();

      return NextResponse.json({
        isSuperAdmin: data !== null,
        userId: user.id,
        mode: 'rls',
      });
    }

    // Use admin client (service_role) when available
    const { createAdminClient } = await import('@/lib/supabase/admin');
    const admin = createAdminClient();
    const { data } = await admin
      .from('super_admins')
      .select('user_id')
      .eq('user_id', user.id)
      .maybeSingle();

    return NextResponse.json({
      isSuperAdmin: data !== null,
      userId: user.id,
      mode: 'service_role',
    });
  } catch (error) {
    console.error('API /admin/check error:', error);
    return NextResponse.json({ isSuperAdmin: false });
  }
}

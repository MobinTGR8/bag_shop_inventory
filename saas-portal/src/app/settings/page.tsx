'use client';

import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useAuth } from '@/components/AuthProvider';
import { useRouter } from 'next/navigation';
import { PlanBadge } from '@/components/admin/PlanBadge';
import { UsageBar } from '@/components/admin/UsageBar';
import { SimulatedPayment } from '@/components/SimulatedPayment';
import { PLANS, type Company, type TenantUsage } from '@/types';

export default function SettingsPage() {
  const { user, isLoading: authLoading, signOut } = useAuth();
  const router = useRouter();
  const [company, setCompany] = useState<Company | null>(null);
  const [usage, setUsage] = useState<TenantUsage | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [showPayment, setShowPayment] = useState(false);
  const [upgradingPlan, setUpgradingPlan] = useState<string | null>(null);

  useEffect(() => {
    if (!authLoading && !user) {
      router.push('/login');
      return;
    }
    if (user) loadMyCompany();
  }, [user, authLoading]);

  async function loadMyCompany() {
    setIsLoading(true);
    const supabase = createClient();
    const { data: userData } = await supabase
      .from('staff')
      .select('company_id')
      .eq('user_id', user!.id)
      .maybeSingle();
    const { data: ownerCompany } = await supabase
      .from('companies')
      .select('id')
      .eq('owner_id', user!.id)
      .maybeSingle();
    const companyId = userData?.company_id ?? ownerCompany?.id;

    if (companyId) {
      const { data: companyData } = await supabase
        .from('companies')
        .select('*')
        .eq('id', companyId)
        .single();
      if (companyData) setCompany(companyData as Company);
      const { data: usageData } = await supabase
        .from('tenant_usage')
        .select('*')
        .eq('company_id', companyId)
        .maybeSingle();
      if (usageData) setUsage(usageData as TenantUsage);
    }
    setIsLoading(false);
  }

  if (authLoading || isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-surface-50">
        <div className="flex flex-col items-center gap-3">
          <div className="relative">
            <div className="h-10 w-10 animate-spin rounded-full border-[3px] border-primary-100 border-t-primary-600" />
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="h-3 w-3 rounded-full bg-gradient-to-br from-primary-500 to-primary-700" />
            </div>
          </div>
          <p className="text-sm text-surface-400 animate-pulse">
            Loading your account...
          </p>
        </div>
      </div>
    );
  }

  if (!company) {
    return (
      <div className="flex h-screen items-center justify-center bg-surface-50">
        <div className="text-center animate-fade-in">
          <div className="text-6xl mb-6">🏪</div>
          <h2 className="text-xl font-bold text-surface-900">
            No company found
          </h2>
          <p className="mt-2 text-sm text-surface-400 max-w-sm mx-auto">
            Use the Flutter app to register your shop first. Once registered,
            your company details will appear here.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface-50">
      {/* Header */}
      <header className="sticky top-0 z-30 border-b border-surface-200/60 bg-white/90 backdrop-blur-xl backdrop-safe">
        <div className="mx-auto flex h-16 max-w-5xl items-center justify-between px-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 shadow-lg shadow-primary-500/20">
              <span className="text-sm font-bold text-white">BS</span>
            </div>
            <div>
              <span className="font-semibold text-surface-900">
                {company.shop_name}
              </span>
              <p className="text-[10px] text-surface-400">
                Plan:{' '}
                {company.plan?.charAt(0).toUpperCase() +
                  company.plan?.slice(1)}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <span className="hidden sm:block text-sm text-surface-400">
              {user?.email}
            </span>
            <button
              onClick={signOut}
              className="flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-sm text-surface-500 transition-all hover:bg-red-50 hover:text-red-600 active:bg-red-100"
              title="Sign out"
            >
              <svg
                className="h-4 w-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
                />
              </svg>
              <span className="hidden sm:inline">Sign Out</span>
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-5xl space-y-8 px-4 py-8">
        {/* Current Plan Card */}
        <div className="hero-card animate-fade-in-up">
          <div className="absolute -top-10 -right-10 h-48 w-48 rounded-full bg-white/5 blur-3xl" />
          <div className="absolute -bottom-10 -left-10 h-48 w-48 rounded-full bg-primary-500/10 blur-3xl" />

          <div className="relative">
            <div className="flex items-start justify-between">
              <div>
                <div className="flex items-center gap-2 text-sm font-medium text-primary-200/80">
                  <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                  Current Plan
                </div>
                <div className="mt-3 flex items-center gap-3">
                  <PlanBadge plan={company.plan} size="md" />
                  <span
                    className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${
                      company.subscription_status === 'active'
                        ? 'bg-emerald-500/20 text-emerald-300'
                        : company.subscription_status === 'trial'
                          ? 'bg-blue-500/20 text-blue-300'
                          : 'bg-red-500/20 text-red-300'
                    }`}
                  >
                    <span
                      className={`h-1.5 w-1.5 rounded-full ${
                        company.subscription_status === 'active'
                          ? 'bg-emerald-400'
                          : 'bg-red-400'
                      }`}
                    />
                    {company.subscription_status}
                  </span>
                </div>
              </div>
            </div>

            <div className="mt-6 grid grid-cols-1 gap-5 sm:grid-cols-3">
              <UsageBar
                current={usage?.staff_count ?? 0}
                max={company.max_staff}
                label="Staff Users"
              />
              <UsageBar
                current={usage?.product_count ?? 0}
                max={company.max_products}
                label="Products"
              />
              <UsageBar
                current={usage?.warehouse_count ?? 0}
                max={company.max_warehouses}
                label="Warehouses"
              />
            </div>
          </div>
        </div>

        {/* Available Plans */}
        <div
          className="space-y-6 animate-fade-in-up"
          style={{ animationDelay: '0.2s' }}
        >
          <div className="section-header">
            <div>
              <h2 className="section-title">Upgrade Your Plan</h2>
              <p className="section-description">
                Choose a plan that fits your business needs
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
            {PLANS.filter((p) => p.key !== 'free').map((plan, i) => {
              const isCurrent = company.plan === plan.key;
              return (
                <div
                  key={plan.key}
                  className={`relative overflow-hidden rounded-2xl border-2 p-6 transition-all duration-300 animate-fade-in-up ${
                    isCurrent
                      ? 'border-primary-500 bg-primary-50/50 shadow-lg shadow-primary-500/10 ring-1 ring-primary-500/20'
                      : 'border-surface-200 bg-white hover:border-primary-300 hover:shadow-xl hover:shadow-primary-500/5 hover:-translate-y-1'
                  }`}
                  style={{ animationDelay: `${0.3 + i * 0.1}s` }}
                >
                  {/* Badge */}
                  {isCurrent && (
                    <div className="absolute top-0 right-0 rounded-bl-xl bg-primary-500 px-3 py-1">
                      <span className="text-[10px] font-bold text-white uppercase tracking-wider">
                        Active
                      </span>
                    </div>
                  )}
                  {plan.key === 'pro' && !isCurrent && (
                    <div className="absolute top-0 right-0 rounded-bl-xl bg-gradient-to-r from-amber-500 to-orange-500 px-3 py-1">
                      <span className="text-[10px] font-bold text-white uppercase tracking-wider">
                        Popular
                      </span>
                    </div>
                  )}

                  {/* Plan icon */}
                  <div className="mb-4 flex items-center gap-3">
                    <div
                      className={`flex h-12 w-12 items-center justify-center rounded-xl text-xl ${
                        isCurrent
                          ? 'bg-primary-100'
                          : 'bg-gradient-to-br from-surface-50 to-surface-100'
                      }`}
                    >
                      {plan.key === 'basic' ? '🥈' : plan.key === 'pro' ? '🥇' : '🏆'}
                    </div>
                    <div>
                      <PlanBadge plan={plan.key} size="md" />
                    </div>
                  </div>

                  <div className="text-3xl font-bold text-surface-900">
                    {plan.price}
                  </div>
                  <p className="mt-1 text-sm text-surface-400">
                    {plan.description}
                  </p>

                  <ul className="mt-6 space-y-3">
                    <li className="flex items-center gap-3 text-sm text-surface-600">
                      <span
                        className={`flex h-6 w-6 items-center justify-center rounded-full text-xs ${
                          isCurrent
                            ? 'bg-primary-100 text-primary-700'
                            : 'bg-surface-100 text-surface-500'
                        }`}
                      >
                        👤
                      </span>
                      {plan.max_staff === 999999
                        ? 'Unlimited'
                        : `Up to ${plan.max_staff}`}{' '}
                      staff users
                    </li>
                    <li className="flex items-center gap-3 text-sm text-surface-600">
                      <span
                        className={`flex h-6 w-6 items-center justify-center rounded-full text-xs ${
                          isCurrent
                            ? 'bg-primary-100 text-primary-700'
                            : 'bg-surface-100 text-surface-500'
                        }`}
                      >
                        📦
                      </span>
                      {plan.max_products === 999999
                        ? 'Unlimited'
                        : `Up to ${plan.max_products}`}{' '}
                      products
                    </li>
                    <li className="flex items-center gap-3 text-sm text-surface-600">
                      <span
                        className={`flex h-6 w-6 items-center justify-center rounded-full text-xs ${
                          isCurrent
                            ? 'bg-primary-100 text-primary-700'
                            : 'bg-surface-100 text-surface-500'
                        }`}
                      >
                        🏭
                      </span>
                      {plan.max_warehouses === 999999
                        ? 'Unlimited'
                        : `Up to ${plan.max_warehouses}`}{' '}
                      warehouses
                    </li>
                  </ul>

                  {isCurrent ? (
                    <div className="mt-6 w-full rounded-xl bg-gradient-to-r from-primary-50 to-primary-100/50 py-3 text-center text-sm font-medium text-primary-600">
                      <span className="flex items-center justify-center gap-1.5">
                        <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                        Current Plan
                      </span>
                    </div>
                  ) : (
                    <button
                      onClick={() => {
                        setUpgradingPlan(plan.key);
                        setShowPayment(true);
                      }}
                      className="btn-primary w-full mt-6"
                    >
                      Upgrade to {plan.label}
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Payment History */}
        <div
          className="stat-card animate-fade-in-up"
          style={{ animationDelay: '0.5s' }}
        >
          <div className="flex items-start gap-4">
            <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-primary-100 to-purple-100 shadow-sm">
              <span className="text-xl">💳</span>
            </div>
            <div className="flex-1">
              <h2 className="section-title">Payment History</h2>
              <p className="section-description">
                Your past payments and invoices
              </p>
              <div className="mt-6 flex flex-col items-center justify-center rounded-2xl bg-gradient-to-br from-surface-50 to-primary-50/30 p-10 border border-surface-100">
                <div className="text-5xl mb-4 opacity-50">📄</div>
                <p className="text-sm text-surface-400 text-center max-w-xs">
                  Payment history will appear here after your first upgrade.
                </p>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Payment Modal */}
      {showPayment && company && upgradingPlan && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-fade-in">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl animate-scale-in max-h-[90vh] overflow-y-auto custom-scrollbar">
            <SimulatedPayment
              companyId={company.id}
              currentPlan={company.plan}
              onComplete={() => {
                setShowPayment(false);
                setUpgradingPlan(null);
                loadMyCompany();
              }}
              onClose={() => {
                setShowPayment(false);
                setUpgradingPlan(null);
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
}

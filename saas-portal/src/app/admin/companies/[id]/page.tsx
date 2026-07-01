'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { PlanBadge } from '@/components/admin/PlanBadge';
import { UsageBar } from '@/components/admin/UsageBar';
import { formatDate } from '@/lib/utils';
import { PLANS, type Company } from '@/types';
import toast from 'react-hot-toast';

interface Usage {
  staff_count: number;
  product_count: number;
  warehouse_count: number;
}

export default function CompanyDetailPage() {
  const params = useParams();
  const router = useRouter();
  const [company, setCompany] = useState<Company | null>(null);
  const [usage, setUsage] = useState<Usage | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isUpdating, setIsUpdating] = useState(false);

  useEffect(() => {
    loadCompany();
  }, [params.id]);

  async function loadCompany() {
    setIsLoading(true);
    try {
      const res = await fetch(`/api/admin/tenants/${params.id}`);
      const json = await res.json();
      if (json.company) setCompany(json.company as Company);
      if (json.usage) setUsage(json.usage as Usage);
    } catch {
      toast.error('Failed to load company details');
    }
    setIsLoading(false);
  }

  async function updatePlan(newPlan: string) {
    if (!company) return;
    setIsUpdating(true);
    const planConfig = PLANS.find((p) => p.key === newPlan)!;
    try {
      const res = await fetch(`/api/admin/tenants/${company.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          plan: newPlan,
          max_staff: planConfig.max_staff,
          max_products: planConfig.max_products,
          max_warehouses: planConfig.max_warehouses,
          subscription_status: 'active',
        }),
      });
      const json = await res.json();
      if (json.company) {
        toast.success(`Plan updated to ${planConfig.label}`);
        loadCompany();
      } else if (json.error)
        toast.error('Failed to update plan: ' + json.error);
    } catch {
      toast.error('Network error');
    }
    setIsUpdating(false);
  }

  async function toggleSubscriptionStatus() {
    if (!company) return;
    setIsUpdating(true);
    const newStatus =
      company.subscription_status === 'active' ? 'cancelled' : 'active';
    try {
      const res = await fetch(`/api/admin/tenants/${company.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ subscription_status: newStatus }),
      });
      const json = await res.json();
      if (json.company) {
        toast.success(
          newStatus === 'active'
            ? 'Subscription activated'
            : 'Subscription cancelled',
        );
        loadCompany();
      } else toast.error('Failed to update status');
    } catch {
      toast.error('Network error');
    }
    setIsUpdating(false);
  }

  if (isLoading) {
    return (
      <div className="page-container">
        <div className="h-6 w-32 skeleton mb-4" />
        <div className="h-8 w-64 skeleton mb-2" />
        <div className="h-4 w-48 skeleton" />
        <div className="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-3">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="h-52 rounded-2xl skeleton" />
          ))}
        </div>
        <div className="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-44 rounded-2xl skeleton" />
          ))}
        </div>
      </div>
    );
  }

  if (!company) {
    return (
      <div className="flex h-96 items-center justify-center">
        <div className="text-center animate-fade-in">
          <div className="empty-state-icon mx-auto">🔍</div>
          <h2 className="empty-state-title">Company not found</h2>
          <button
            onClick={() => router.push('/admin')}
            className="mt-4 btn-primary"
          >
            Back to dashboard
          </button>
        </div>
      </div>
    );
  }

  const getBadgeClass = (status: string) => {
    switch (status) {
      case 'active':
        return 'badge-active';
      case 'trial':
        return 'badge-trial';
      case 'cancelled':
        return 'badge-cancelled';
      case 'past_due':
        return 'badge-past-due';
      default:
        return 'badge-expired';
    }
  };

  return (
    <div className="page-container space-y-8">
      {/* Header */}
      <div className="animate-fade-in-up">
        <button
          onClick={() => router.push('/admin')}
          className="mb-4 flex items-center gap-1.5 text-sm text-surface-400 transition hover:text-surface-600 group"
        >
          <svg
            className="h-4 w-4 transition group-hover:-translate-x-0.5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M15 19l-7-7 7-7"
            />
          </svg>
          Back to Dashboard
        </button>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-4">
            <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-100 to-primary-50 text-2xl font-bold text-primary-700 shadow-sm">
              {(company.shop_name || company.name || '?')[0].toUpperCase()}
            </div>
            <div>
              <h1 className="text-2xl font-bold text-surface-900">
                {company.shop_name || company.name}
              </h1>
              <p className="mt-1 text-sm text-surface-400">
                Joined {formatDate(company.created_at)}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <PlanBadge plan={company.plan} size="md" />
            <span className={getBadgeClass(company.subscription_status)}>
              <span
                className={`h-1.5 w-1.5 rounded-full ${
                  company.subscription_status === 'active'
                    ? 'bg-emerald-500'
                    : company.subscription_status === 'trial'
                      ? 'bg-blue-500'
                      : 'bg-surface-400'
                }`}
              />
              {company.subscription_status}
            </span>
          </div>
        </div>
      </div>

      {/* Info Cards Grid */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Company Info */}
        <div
          className="stat-card animate-fade-in-up"
          style={{ animationDelay: '0.1s' }}
        >
          <h3 className="mb-5 stat-label">Company Info</h3>
          <div className="space-y-2.5 text-sm">
            <div className="data-row">
              <span className="data-label">Name</span>
              <span className="data-value">{company.name}</span>
            </div>
            {company.phone && (
              <div className="data-row">
                <span className="data-label">Phone</span>
                <span className="text-surface-900">{company.phone}</span>
              </div>
            )}
            {company.email && (
              <div className="data-row">
                <span className="data-label">Email</span>
                <span className="text-surface-900 truncate max-w-[200px]">
                  {company.email}
                </span>
              </div>
            )}
            <div className="data-row">
              <span className="data-label">Status</span>
              <span className={getBadgeClass(company.subscription_status)}>
                {company.subscription_status}
              </span>
            </div>
            {company.max_staff === 999999 && (
              <div className="data-row">
                <span className="data-label">Limits</span>
                <span className="text-surface-500 text-xs">Unlimited</span>
              </div>
            )}
          </div>
        </div>

        {/* Usage */}
        <div
          className="stat-card animate-fade-in-up"
          style={{ animationDelay: '0.15s' }}
        >
          <h3 className="mb-5 stat-label">Usage Overview</h3>
          <div className="space-y-5">
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

        {/* Actions */}
        <div
          className="stat-card animate-fade-in-up"
          style={{ animationDelay: '0.2s' }}
        >
          <h3 className="mb-5 stat-label">Actions</h3>
          <div className="space-y-4">
            <button
              onClick={toggleSubscriptionStatus}
              disabled={isUpdating}
              className={`w-full rounded-xl px-4 py-3 text-sm font-medium transition-all duration-200 disabled:opacity-50 ${
                company.subscription_status === 'active'
                  ? 'border border-red-200 text-red-600 hover:bg-red-50 hover:border-red-300 active:bg-red-100'
                  : 'border border-emerald-200 text-emerald-600 hover:bg-emerald-50 hover:border-emerald-300 active:bg-emerald-100'
              }`}
            >
              {isUpdating
                ? 'Updating...'
                : company.subscription_status === 'active'
                  ? 'Cancel Subscription'
                  : 'Reactivate Subscription'}
            </button>
            <div className="rounded-xl bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 p-4">
              <div className="flex items-start gap-3">
                <span className="text-lg shrink-0">💡</span>
                <p className="text-xs text-amber-800 leading-relaxed">
                  <strong>Tip:</strong> Changing the plan limits will take
                  effect immediately. The Flutter app enforces these limits via
                  database triggers.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Plan Management */}
      <div
        className="stat-card animate-fade-in-up"
        style={{ animationDelay: '0.25s' }}
      >
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="section-title">Change Plan</h2>
            <p className="section-description">Select a new plan for this company</p>
          </div>
          {isUpdating && (
            <span className="text-sm text-primary-600 font-medium animate-pulse">
              Updating...
            </span>
          )}
        </div>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {PLANS.map((plan, i) => {
            const isCurrent = company.plan === plan.key;
            return (
              <button
                key={plan.key}
                onClick={() => updatePlan(plan.key)}
                disabled={isCurrent || isUpdating}
                className={`relative overflow-hidden rounded-2xl border-2 p-5 text-left transition-all duration-300 animate-fade-in-up disabled:cursor-not-allowed ${
                  isCurrent
                    ? 'border-primary-500 bg-primary-50/50 shadow-lg shadow-primary-500/10 ring-1 ring-primary-500/20'
                    : 'border-surface-200 bg-white hover:border-primary-300 hover:shadow-lg hover:-translate-y-1'
                }`}
                style={{ animationDelay: `${0.3 + i * 0.1}s` }}
              >
                {/* Active badge */}
                {isCurrent && (
                  <div className="absolute top-0 right-0 rounded-bl-xl bg-primary-500 px-3 py-1">
                    <span className="text-[10px] font-bold text-white uppercase tracking-wider">
                      Active
                    </span>
                  </div>
                )}

                {/* Popular badge */}
                {plan.key === 'pro' && !isCurrent && (
                  <div className="absolute top-0 right-0 rounded-bl-xl bg-gradient-to-r from-amber-500 to-orange-500 px-3 py-1">
                    <span className="text-[10px] font-bold text-white uppercase tracking-wider">
                      Popular
                    </span>
                  </div>
                )}

                <div className="mb-3">
                  <PlanBadge plan={plan.key} />
                </div>
                <div className="text-xl font-bold text-surface-900">
                  {plan.price}
                </div>
                <p className="mt-1 text-xs text-surface-400">
                  {plan.description}
                </p>

                <div className="mt-4 space-y-2 border-t border-surface-100 pt-4">
                  <div className="flex items-center gap-2 text-xs text-surface-600">
                    <span className="text-surface-400 shrink-0">👤</span>
                    {plan.max_staff === 999999 ? '∞' : plan.max_staff} staff
                  </div>
                  <div className="flex items-center gap-2 text-xs text-surface-600">
                    <span className="text-surface-400 shrink-0">📦</span>
                    {plan.max_products === 999999
                      ? '∞'
                      : plan.max_products}{' '}
                    products
                  </div>
                  <div className="flex items-center gap-2 text-xs text-surface-600">
                    <span className="text-surface-400 shrink-0">🏭</span>
                    {plan.max_warehouses === 999999
                      ? '∞'
                      : plan.max_warehouses}{' '}
                    warehouses
                  </div>
                </div>

                {!isCurrent && (
                  <div className="mt-4 w-full rounded-xl bg-gradient-to-r from-primary-500 to-primary-600 py-2.5 text-center text-xs font-semibold text-white shadow-sm transition hover:shadow-md">
                    {isUpdating ? (
                      <span className="flex items-center justify-center gap-1.5">
                        <svg className="h-3 w-3 animate-spin" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                        </svg>
                        Updating...
                      </span>
                    ) : (
                      'Select Plan'
                    )}
                  </div>
                )}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

'use client';

import type { TenantUsage } from '@/types';
import { PlanBadge } from './PlanBadge';
import { UsageBar } from './UsageBar';
import { useRouter } from 'next/navigation';
import { formatDate } from '@/lib/utils';

interface CompanyTableProps {
  tenants: TenantUsage[];
}

export function CompanyTable({ tenants }: CompanyTableProps) {
  const router = useRouter();

  if (tenants.length === 0) {
    return (
      <div className="empty-state">
        <div className="empty-state-icon">🏪</div>
        <h3 className="empty-state-title">No tenants yet</h3>
        <p className="empty-state-description">
          Companies will appear here once shop owners register via the Flutter
          app
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {tenants.map((tenant, i) => (
        <div
          key={tenant.company_id}
          onClick={() => router.push(`/admin/companies/${tenant.company_id}`)}
          className="group cursor-pointer rounded-2xl border border-surface-200/60 bg-white p-5 shadow-sm transition-all duration-200 hover:shadow-lg hover:border-primary-200 hover:-translate-y-0.5 animate-fade-in-up"
          style={{ animationDelay: `${i * 0.04}s` }}
        >
          {/* Mobile layout */}
          <div className="flex flex-col gap-4 lg:hidden">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3 min-w-0">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-primary-100 to-primary-50 text-sm font-bold text-primary-700">
                  {(tenant.shop_name || 'U')[0].toUpperCase()}
                </div>
                <div className="min-w-0">
                  <p className="font-semibold text-surface-900 truncate">
                    {tenant.shop_name || 'Unnamed Shop'}
                  </p>
                  <p className="text-xs text-surface-400">
                    {formatDate(tenant.created_at)}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                <PlanBadge plan={tenant.plan} size="sm" />
                <svg
                  className="h-4 w-4 text-surface-300 transition group-hover:translate-x-0.5 group-hover:text-primary-500"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 5l7 7-7 7"
                  />
                </svg>
              </div>
            </div>
            <div className="flex items-center gap-4 text-xs text-surface-400">
              <span className="flex items-center gap-1">
                <span
                  className={`h-1.5 w-1.5 rounded-full ${
                    tenant.subscription_status === 'active'
                      ? 'bg-emerald-500'
                      : tenant.subscription_status === 'trial'
                        ? 'bg-blue-500'
                        : 'bg-red-500'
                  }`}
                />
                {tenant.subscription_status}
              </span>
              <span>
                👤 {tenant.staff_count}/
                {tenant.max_staff === 999999
                  ? '∞'
                  : tenant.max_staff}
              </span>
              <span>
                📦 {tenant.product_count}/
                {tenant.max_products === 999999
                  ? '∞'
                  : tenant.max_products}
              </span>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <UsageBar
                current={tenant.staff_count}
                max={tenant.max_staff}
                label="Staff"
              />
              <UsageBar
                current={tenant.product_count}
                max={tenant.max_products}
                label="Products"
              />
            </div>
          </div>

          {/* Desktop layout */}
          <div className="hidden items-center gap-6 lg:flex">
            <div className="flex items-center gap-4 flex-1 min-w-0">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-primary-100 to-primary-50 text-sm font-bold text-primary-700">
                {(tenant.shop_name || 'U')[0].toUpperCase()}
              </div>
              <div className="min-w-0">
                <p className="font-semibold text-surface-900 truncate">
                  {tenant.shop_name || 'Unnamed Shop'}
                </p>
                <p className="text-xs text-surface-400">
                  {formatDate(tenant.created_at)}
                </p>
              </div>
            </div>

            <div className="w-20 shrink-0">
              <PlanBadge plan={tenant.plan} size="sm" />
            </div>

            <div className="w-24 shrink-0">
              <span
                className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${
                  tenant.subscription_status === 'active'
                    ? 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-600/20'
                    : tenant.subscription_status === 'trial'
                      ? 'bg-blue-50 text-blue-700 ring-1 ring-blue-600/20'
                      : 'bg-red-50 text-red-700 ring-1 ring-red-600/20'
                }`}
              >
                <span
                  className={`h-1.5 w-1.5 rounded-full ${
                    tenant.subscription_status === 'active'
                      ? 'bg-emerald-500'
                      : 'bg-red-500'
                  }`}
                />
                {tenant.subscription_status}
              </span>
            </div>

            <div className="w-44">
              <UsageBar
                current={tenant.staff_count}
                max={tenant.max_staff}
                label="Staff"
              />
            </div>

            <div className="w-44">
              <UsageBar
                current={tenant.product_count}
                max={tenant.max_products}
                label="Products"
              />
            </div>

            <svg
              className="h-5 w-5 shrink-0 text-surface-300 transition group-hover:translate-x-1 group-hover:text-primary-500"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 5l7 7-7 7"
              />
            </svg>
          </div>
        </div>
      ))}
    </div>
  );
}

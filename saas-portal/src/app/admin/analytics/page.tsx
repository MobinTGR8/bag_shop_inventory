'use client';

import { useEffect, useState } from 'react';

interface SimpleStats {
  total: number;
  active: number;
  free: number;
  basic: number;
  pro: number;
  enterprise: number;
  staffCount: number;
  productCount: number;
  revenue: number;
}

function SkeletonRow() {
  return (
    <div className="flex items-center gap-4 rounded-xl border border-surface-200/60 bg-white p-5">
      <div className="h-10 w-10 skeleton rounded-lg shrink-0" />
      <div className="flex-1 space-y-2">
        <div className="h-4 w-48 skeleton" />
        <div className="h-3 w-full skeleton" />
      </div>
    </div>
  );
}

export default function AnalyticsPage() {
  const [stats, setStats] = useState<SimpleStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  async function loadStats() {
    setIsLoading(true);
    try {
      const res = await fetch('/api/admin/tenants');
      const json = await res.json();

      if (json.tenants) {
        const tenants = json.tenants;
        const total = tenants.length;
        const active = tenants.filter(
          (t: any) =>
            t.subscription_status === 'active' ||
            t.subscription_status === 'trial',
        ).length;
        const free = tenants.filter((t: any) => t.plan === 'free').length;
        const basic = tenants.filter((t: any) => t.plan === 'basic').length;
        const pro = tenants.filter((t: any) => t.plan === 'pro').length;
        const enterprise = tenants.filter(
          (t: any) => t.plan === 'enterprise',
        ).length;
        const staffCount = tenants.reduce(
          (s: number, t: any) => s + t.staff_count,
          0,
        );
        const productCount = tenants.reduce(
          (s: number, t: any) => s + t.product_count,
          0,
        );
        const revenue = basic * 500 + pro * 1500 + enterprise * 5000;
        setStats({
          total,
          active,
          free,
          basic,
          pro,
          enterprise,
          staffCount,
          productCount,
          revenue,
        });
      }
    } catch (err) {
      console.error('Failed to load analytics:', err);
    }
    setIsLoading(false);
  }

  if (isLoading || !stats) {
    return (
      <div className="page-container">
        <div className="space-y-2 animate-fade-in-up">
          <div className="h-8 w-48 skeleton" />
          <div className="h-4 w-72 skeleton" />
        </div>
        <div className="mt-6 h-40 rounded-2xl skeleton" />
        <div className="mt-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
          {[...Array(4)].map((_, i) => (
            <SkeletonRow key={i} />
          ))}
        </div>
        <div className="mt-6 space-y-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="skeleton-card">
              <div className="h-4 w-48 skeleton mb-2" />
              <div className="h-3 skeleton rounded-full" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="page-container">
      {/* Header */}
      <div className="animate-fade-in-up">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="page-title">Analytics</h1>
            <p className="page-subtitle">
              Revenue and usage overview across all tenants
            </p>
          </div>
          <button
            onClick={loadStats}
            disabled={isLoading}
            className="btn-secondary"
          >
            <svg
              className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            Refresh
          </button>
        </div>
      </div>

      {/* Revenue Card */}
      <div className="hero-card animate-fade-in-up mt-8">
        {/* Decorative blobs */}
        <div className="absolute -top-10 -right-10 h-48 w-48 rounded-full bg-white/5 blur-3xl" />
        <div className="absolute -bottom-10 -left-10 h-48 w-48 rounded-full bg-primary-500/10 blur-3xl" />
        <div className="absolute top-1/2 left-1/3 h-32 w-32 rounded-full bg-purple-500/10 blur-3xl" />

        <div className="relative">
          <div className="flex items-center gap-2 text-sm font-medium text-primary-200/80">
            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
            </svg>
            Estimated Monthly Revenue
          </div>
          <div className="mt-3 flex items-baseline gap-4">
            <span className="text-5xl font-bold text-white">
              Tk {stats.revenue.toLocaleString()}
            </span>
            <span className="rounded-full bg-emerald-500/20 px-3 py-1 text-sm font-medium text-emerald-300">
              {stats.active} active
            </span>
          </div>
          <div className="mt-6 flex flex-wrap gap-2">
            <span className="pill-white">
              {stats.basic} Basic × Tk 500
            </span>
            <span className="pill-white">
              {stats.pro} Pro × Tk 1,500
            </span>
            <span className="pill-white">
              {stats.enterprise} Enterprise × Tk 5,000
            </span>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4 mt-8">
        {(
          [
            {
              label: 'Total Companies',
              value: stats.total,
              icon: '🏪',
              delay: '0.15s',
              gradient: 'from-blue-500 to-blue-600',
            },
            {
              label: 'Active',
              value: `${stats.active}/${stats.total}`,
              icon: '✅',
              delay: '0.2s',
              gradient: 'from-emerald-500 to-emerald-600',
            },
            {
              label: 'Total Staff',
              value: stats.staffCount,
              icon: '👤',
              delay: '0.25s',
              gradient: 'from-amber-500 to-orange-600',
            },
            {
              label: 'Total Products',
              value: stats.productCount.toLocaleString(),
              icon: '📦',
              delay: '0.3s',
              gradient: 'from-rose-500 to-pink-600',
            },
          ] as const
        ).map((item) => (
          <div
            key={item.label}
            className="stat-card animate-fade-in-up"
            style={{ animationDelay: item.delay }}
          >
            <div className="flex items-center justify-between">
              <p className="stat-label">{item.label}</p>
              <div
                className={`flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br ${item.gradient} shadow-lg`}
              >
                <span className="text-base">{item.icon}</span>
              </div>
            </div>
            <p className="mt-3 text-2xl font-bold text-surface-900">
              {item.value}
            </p>
          </div>
        ))}
      </div>

      {/* Plan Breakdown */}
      <div className="stat-card mt-8 animate-fade-in-up" style={{ animationDelay: '0.35s' }}>
        <h2 className="section-title mb-6">Plan Distribution</h2>
        <div className="space-y-6">
          {(
            [
              {
                label: 'Free',
                count: stats.free,
                percent: (stats.free / stats.total) * 100,
                barColor: 'from-surface-300 to-surface-400',
                dotColor: 'bg-surface-400',
              },
              {
                label: 'Basic',
                count: stats.basic,
                percent: (stats.basic / stats.total) * 100,
                barColor: 'from-blue-400 to-blue-600',
                dotColor: 'bg-blue-500',
              },
              {
                label: 'Pro',
                count: stats.pro,
                percent: (stats.pro / stats.total) * 100,
                barColor: 'from-purple-400 to-purple-600',
                dotColor: 'bg-purple-500',
              },
              {
                label: 'Enterprise',
                count: stats.enterprise,
                percent: (stats.enterprise / stats.total) * 100,
                barColor: 'from-amber-400 to-amber-600',
                dotColor: 'bg-amber-500',
              },
            ] as const
          ).map((plan, i) => (
            <div
              key={plan.label}
              className="animate-fade-in-up"
              style={{ animationDelay: `${0.4 + i * 0.1}s` }}
            >
              <div className="mb-2 flex items-center justify-between text-sm">
                <div className="flex items-center gap-2">
                  <span className={`h-2.5 w-2.5 rounded-full ${plan.dotColor}`} />
                  <span className="font-medium text-surface-700">
                    {plan.label}
                  </span>
                </div>
                <span className="text-surface-400">
                  {plan.count} tenant{plan.count !== 1 ? 's' : ''} (
                  {plan.percent.toFixed(1)}%)
                </span>
              </div>
              <div className="progress-bar">
                <div
                  className={`progress-bar-fill bg-gradient-to-r ${plan.barColor}`}
                  style={{
                    width: `${plan.percent}%`,
                    transitionDelay: `${0.4 + i * 0.1}s`,
                  }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Conversion Insight */}
      <div className="insight-card-info mt-8 animate-fade-in-up" style={{ animationDelay: '0.5s' }}>
        <div className="flex items-start gap-4">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-primary-100 text-xl">
            💡
          </div>
          <div>
            <h3 className="font-semibold text-surface-900">
              Conversion Insight
            </h3>
            <p className="mt-1 text-sm text-surface-500 leading-relaxed">
              {stats.free > 0
                ? `${stats.free} tenant${stats.free !== 1 ? 's' : ''} (${((stats.free / stats.total) * 100).toFixed(0)}%) ${stats.free === 1 ? 'is' : 'are'} on the Free plan. Consider running a promotion to convert them to Basic (Tk 500/mo) for additional revenue.`
                : 'All tenants are on paid plans. Excellent work! 🎉'}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

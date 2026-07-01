'use client';

import { useEffect, useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { PlanBadge } from '@/components/admin/PlanBadge';
import { UsageBar } from '@/components/admin/UsageBar';
import type { TenantUsage } from '@/types';

interface DashboardMeta {
  total: number;
  active: number;
  paying: number;
  mrr: number;
  free: number;
  basic: number;
  pro: number;
  enterprise: number;
}

export default function AdminDashboard() {
  const router = useRouter();
  const [tenants, setTenants] = useState<TenantUsage[]>([]);
  const [meta, setMeta] = useState<DashboardMeta | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [planFilter, setPlanFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  useEffect(() => {
    loadTenants();
  }, []);

  async function loadTenants() {
    setIsLoading(true);
    try {
      const res = await fetch('/api/admin/tenants');
      const json = await res.json();
      if (json.tenants) setTenants(json.tenants);
      if (json.meta) setMeta(json.meta);
    } catch (err) {
      console.error('Failed to load tenants:', err);
    }
    setIsLoading(false);
  }

  const filteredTenants = useMemo(() => {
    return tenants.filter((t) => {
      const matchesSearch =
        searchQuery === '' ||
        (t.shop_name || '').toLowerCase().includes(searchQuery.toLowerCase());
      const matchesPlan = planFilter === 'all' || t.plan === planFilter;
      const matchesStatus =
        statusFilter === 'all' || t.subscription_status === statusFilter;
      return matchesSearch && matchesPlan && matchesStatus;
    });
  }, [tenants, searchQuery, planFilter, statusFilter]);

  const recentActivity = useMemo(() => {
    return [...tenants]
      .sort(
        (a, b) =>
          new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
      )
      .slice(0, 3);
  }, [tenants]);

  const planCounts = {
    free: tenants.filter((t) => t.plan === 'free').length,
    basic: tenants.filter((t) => t.plan === 'basic').length,
    pro: tenants.filter((t) => t.plan === 'pro').length,
    enterprise: tenants.filter((t) => t.plan === 'enterprise').length,
  };

  const totalTenants = meta?.total ?? tenants.length;
  const activeTenants = meta?.active ?? tenants.filter(
    (t) => t.subscription_status === 'active' || t.subscription_status === 'trial',
  ).length;
  const totalStaff = tenants.reduce((sum, t) => sum + t.staff_count, 0);
  const totalProducts = tenants.reduce((sum, t) => sum + t.product_count, 0);
  const mrr = meta?.mrr ?? 0;
  const payingTenants = meta?.paying ?? 0;

  const getFilteredCount = () => {
    if (!searchQuery && planFilter === 'all' && statusFilter === 'all') return null;
    return filteredTenants.length;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-emerald-500';
      case 'trial': return 'bg-blue-500';
      default: return 'bg-surface-300';
    }
  };

  // ── Loading State ──
  if (isLoading) {
    return (
      <div className="flex flex-col h-full p-6 gap-4 animate-fade-in">
        <div className="flex items-center gap-4">
          <div className="h-7 w-36 skeleton" />
          <div className="flex-1 max-w-xs ml-auto">
            <div className="h-8 skeleton rounded-xl" />
          </div>
        </div>
        <div className="grid grid-cols-5 gap-3">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="rounded-xl border border-surface-200/60 bg-white p-4 shadow-sm">
              <div className="h-3 w-16 skeleton mb-2" />
              <div className="h-6 w-20 skeleton" />
            </div>
          ))}
        </div>
        <div className="grid grid-cols-3 gap-4 flex-1 min-h-0">
          <div className="col-span-2 rounded-xl border border-surface-200/60 bg-white p-4 shadow-sm space-y-2">
            {[...Array(7)].map((_, i) => (
              <div key={i} className="flex items-center gap-3 p-2.5">
                <div className="h-8 w-8 skeleton rounded-lg shrink-0" />
                <div className="flex-1 space-y-1.5">
                  <div className="h-3.5 w-36 skeleton" />
                  <div className="h-2.5 w-24 skeleton" />
                </div>
                <div className="h-5 w-14 skeleton rounded-full" />
              </div>
            ))}
          </div>
          <div className="rounded-xl border border-surface-200/60 bg-white p-4 shadow-sm space-y-3">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="space-y-1.5">
                <div className="h-3 w-24 skeleton" />
                <div className="h-2 skeleton rounded-full" />
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // ── Empty State ──
  if (tenants.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-6 animate-fade-in">
        <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-surface-50 text-3xl mb-4">
          🏪
        </div>
        <h2 className="text-lg font-display font-semibold text-surface-900">No tenants yet</h2>
        <p className="mt-1 text-sm text-surface-400 text-center max-w-sm">
          Companies will appear here once shop owners register via the Flutter app.
        </p>
      </div>
    );
  }

  // ── Main Dashboard ──
  return (
    <div className="flex flex-col h-full p-5 gap-3 animate-fade-in font-sans">
      {/* ─────────── ROW 1: Header + Search + Filters ─────────── */}
      <div className="flex items-center gap-2 sm:gap-3 shrink-0 flex-wrap">
        <div className="flex items-center gap-2.5">
          <h1 className="text-lg font-display font-bold text-surface-900 tracking-tight">Dashboard</h1>
          <span className="text-[11px] text-surface-400 bg-surface-100 px-2 py-0.5 rounded-full font-medium">
            {totalTenants} tenants
          </span>
        </div>

        {/* Search (compact) */}
        <div className="relative flex-1 min-w-[120px] max-w-xs ml-auto order-last sm:order-none w-full sm:w-auto">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-surface-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            type="text"
            placeholder="Search..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-lg border border-surface-200 bg-white pl-9 pr-3 py-1.5 text-xs text-surface-900 placeholder-surface-400 shadow-sm transition-all duration-200 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
          />
        </div>

        {/* Filters */}
        <select
          value={planFilter}
          onChange={(e) => setPlanFilter(e.target.value)}
          className="rounded-lg border border-surface-200 bg-white px-2.5 py-1.5 text-xs text-surface-600 shadow-sm transition-all duration-200 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-500/20 appearance-none bg-no-repeat pr-7"
          style={{ backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E")`, backgroundPosition: 'right 8px center' }}
        >
          <option value="all">All Plans</option>
          <option value="free">Free</option>
          <option value="basic">Basic</option>
          <option value="pro">Pro</option>
          <option value="enterprise">Enterprise</option>
        </select>

        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="rounded-lg border border-surface-200 bg-white px-2.5 py-1.5 text-xs text-surface-600 shadow-sm transition-all duration-200 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-500/20 appearance-none bg-no-repeat pr-7"
          style={{ backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E")`, backgroundPosition: 'right 8px center' }}
        >
          <option value="all">All Status</option>
          <option value="active">Active</option>
          <option value="trial">Trial</option>
          <option value="cancelled">Cancelled</option>
          <option value="expired">Expired</option>
        </select>

        <button
          onClick={loadTenants}
          title="Refresh"
          className="flex items-center justify-center h-7 w-7 rounded-lg border border-surface-200 bg-white text-surface-400 transition-all duration-200 hover:bg-surface-50 hover:text-surface-600 active:bg-surface-100"
        >
          <svg className={`h-3.5 w-3.5 ${isLoading ? 'animate-spin' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        </button>
      </div>

      {/* ─────────── ROW 2: Compact Stat Cards ─────────── */}
      <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-5 gap-2 sm:gap-3 shrink-0">
        {[
          { label: 'Tenants', value: totalTenants, icon: '🏪', gradient: 'from-blue-500 to-blue-600' },
          { label: 'Active', value: activeTenants, sub: `/${totalTenants}`, icon: '✅', gradient: 'from-emerald-500 to-emerald-600' },
          { label: 'MRR', value: `Tk${mrr.toLocaleString()}`, sub: `${payingTenants} paying`, icon: '💰', gradient: 'from-purple-500 to-purple-600' },
          { label: 'Staff', value: totalStaff, icon: '👤', gradient: 'from-amber-500 to-orange-600' },
          { label: 'Products', value: totalProducts.toLocaleString(), icon: '📦', gradient: 'from-rose-500 to-pink-600' },
        ].map((stat, i) => (
          <div
            key={stat.label}
            className="rounded-xl border border-surface-200/60 bg-white p-3.5 shadow-sm transition-all duration-200 hover:shadow-md hover:-translate-y-0.5 animate-fade-in"
            style={{ animationDelay: `${i * 0.05}s` }}
          >
            <div className="flex items-center justify-between">
              <div className="min-w-0">
                <p className="text-[10px] font-semibold uppercase tracking-widest text-surface-400">{stat.label}</p>
                <p className="mt-1 text-lg font-bold tracking-tight text-surface-900 font-display">
                  {stat.value}
                  {stat.sub && <span className="text-xs text-surface-300 font-normal ml-0.5">{stat.sub}</span>}
                </p>
              </div>
              <div className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br ${stat.gradient} shadow-sm ml-2`}>
                <span className="text-sm">{stat.icon}</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* ─────────── ROW 3: Main Content (flexible, fills remaining height) ─────────── */}
      <div className="flex flex-col xl:flex-row gap-3 xl:gap-4 flex-1 min-h-0">
        {/* ── Left: Tenants Table ── */}
        <div className="flex flex-col flex-1 min-w-0 rounded-xl border border-surface-200/60 bg-white shadow-sm">
          {/* Table Header */}
          <div className="flex items-center justify-between px-4 py-2.5 border-b border-surface-100 shrink-0">
            <h2 className="text-xs font-display font-semibold text-surface-800">
              {getFilteredCount() !== null ? `Results (${getFilteredCount()})` : 'All Tenants'}
            </h2>
            <div className="flex items-center gap-2">
              {(getFilteredCount() !== null || planFilter !== 'all' || statusFilter !== 'all') && (
                <button
                  onClick={() => { setSearchQuery(''); setPlanFilter('all'); setStatusFilter('all'); }}
                  className="text-[10px] text-primary-600 hover:text-primary-700 font-medium transition-colors"
                >
                  Clear
                </button>
              )}
              <span className="text-[10px] text-surface-400">
                {filteredTenants.length}/{tenants.length}
              </span>
            </div>
          </div>

          {/* Table Body (scrollable) */}
          {filteredTenants.length === 0 ? (
            <div className="flex flex-col items-center justify-center flex-1 p-6">
              <span className="text-2xl mb-2">🔍</span>
              <p className="text-xs text-surface-500 font-medium">No results found</p>
              <p className="text-[10px] text-surface-400 mt-0.5">Try adjusting your search or filters</p>
            </div>
          ) : (
            <div className="flex-1 overflow-y-auto custom-scrollbar divide-y divide-surface-50">
              {filteredTenants.map((tenant, i) => (
                <button
                  key={tenant.company_id}
                  onClick={() => router.push(`/admin/companies/${tenant.company_id}`)}
                  className="flex w-full items-center gap-3 px-4 py-2.5 text-left transition-all duration-150 hover:bg-primary-50/40 hover:pl-5 group"
                >
                  <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-primary-100 to-primary-50 text-[10px] font-bold text-primary-700">
                    {(tenant.shop_name || 'U')[0].toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0 flex items-center gap-3">
                    <div className="min-w-0 flex-1">
                      <p className="text-xs font-semibold text-surface-900 truncate leading-tight">
                        {tenant.shop_name || 'Unnamed Shop'}
                      </p>
                      <p className="text-[10px] text-surface-400 mt-0.5">
                        {new Date(tenant.created_at).toLocaleDateString('en-BD', { month: 'short', day: 'numeric' })}
                      </p>
                    </div>
                    <span className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-medium ${
                      tenant.subscription_status === 'active'
                        ? 'bg-emerald-50 text-emerald-700'
                        : tenant.subscription_status === 'trial'
                          ? 'bg-blue-50 text-blue-700'
                          : 'bg-surface-100 text-surface-500'
                    }`}>
                      <span className={`h-1 w-1 rounded-full ${getStatusColor(tenant.subscription_status)}`} />
                      {tenant.subscription_status}
                    </span>
                    <PlanBadge plan={tenant.plan} size="sm" showIcon={false} />
                  </div>
                  <svg className="h-3.5 w-3.5 shrink-0 text-surface-300 opacity-0 group-hover:opacity-100 transition-all" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </button>
              ))}
            </div>
          )}

          {/* Table Footer */}
          {filteredTenants.length > 0 && (
            <div className="px-4 py-2 border-t border-surface-100 shrink-0 flex items-center justify-between">
              <span className="text-[10px] text-surface-400">
                Showing {filteredTenants.length} of {tenants.length} companies
              </span>
              <div className="flex items-center gap-2 text-[10px] text-surface-400">
                <span className="flex items-center gap-1">
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" /> Active: {tenants.filter(t => t.subscription_status === 'active').length}
                </span>
                <span className="flex items-center gap-1">
                  <span className="h-1.5 w-1.5 rounded-full bg-surface-300" /> Inactive: {tenants.filter(t => t.subscription_status !== 'active').length}
                </span>
              </div>
            </div>
          )}
        </div>

        {/* ── Right: Sidebar Widgets ── */}
        <div className="grid grid-cols-2 sm:grid-cols-4 xl:grid-cols-1 gap-3 xl:w-72 shrink-0">
          {/* Plan Distribution */}
          <div className="rounded-xl border border-surface-200/60 bg-white p-4 shadow-sm shrink-0">
            <h3 className="text-[10px] font-semibold uppercase tracking-widest text-surface-400 mb-3 font-display">Plan Distribution</h3>
            <div className="flex h-2 overflow-hidden rounded-full bg-surface-100 mb-3">
              {([
                { key: 'free', count: planCounts.free, color: 'bg-surface-300' },
                { key: 'basic', count: planCounts.basic, color: 'bg-blue-500' },
                { key: 'pro', count: planCounts.pro, color: 'bg-purple-500' },
                { key: 'enterprise', count: planCounts.enterprise, color: 'bg-amber-500' },
              ] as const).map(({ key, count, color }) =>
                count > 0 ? <div key={key} className={`${color} transition-all duration-1000`} style={{ width: `${(count / totalTenants) * 100}%` }} /> : null
              )}
            </div>
            <div className="grid grid-cols-2 gap-x-3 gap-y-1">
              {(['free', 'basic', 'pro', 'enterprise'] as const).map((plan) => {
                const count = planCounts[plan];
                if (count === 0) return null;
                return (
                  <div key={plan} className="flex items-center justify-between text-[10px]">
                    <PlanBadge plan={plan} size="sm" />
                    <span className="font-medium text-surface-500 ml-1">{count} ({Math.round((count / totalTenants) * 100)}%)</span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Revenue */}
          {mrr > 0 && (
            <div className="rounded-xl border border-surface-200/60 bg-white p-4 shadow-sm shrink-0">
              <h3 className="text-[10px] font-semibold uppercase tracking-widest text-surface-400 mb-2.5 font-display">Revenue</h3>
              <div className="flex items-baseline gap-1.5 mb-2.5">
                <span className="text-xl font-bold text-surface-900 font-display tracking-tight">Tk {mrr.toLocaleString()}</span>
                <span className="text-[10px] text-surface-400">MRR</span>
              </div>
              <div className="space-y-1.5">
                {[
                  { label: 'Basic', count: meta?.basic ?? 0, price: 500, dot: 'bg-blue-500' },
                  { label: 'Pro', count: meta?.pro ?? 0, price: 1500, dot: 'bg-purple-500' },
                  { label: 'Enterprise', count: meta?.enterprise ?? 0, price: 5000, dot: 'bg-amber-500' },
                ].map((item) => {
                  if (item.count === 0) return null;
                  return (
                    <div key={item.label} className="flex items-center justify-between text-[10px]">
                      <div className="flex items-center gap-1.5">
                        <span className={`h-1.5 w-1.5 rounded-full ${item.dot}`} />
                        <span className="text-surface-500">{item.label} × {item.count}</span>
                      </div>
                      <span className="font-semibold text-surface-700">Tk {(item.count * item.price).toLocaleString()}</span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Recent Activity */}
          {recentActivity.length > 0 && (
            <div className="rounded-xl border border-surface-200/60 bg-white p-4 shadow-sm shrink-0">
              <h3 className="text-[10px] font-semibold uppercase tracking-widest text-surface-400 mb-2.5 font-display">New Signups</h3>
              <div className="space-y-1">
                {recentActivity.map((tenant) => (
                  <button
                    key={tenant.company_id}
                    onClick={() => router.push(`/admin/companies/${tenant.company_id}`)}
                    className="flex w-full items-center gap-2.5 rounded-lg p-2 transition-all hover:bg-surface-50 text-left"
                  >
                    <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-gradient-to-br from-primary-100 to-primary-50 text-[9px] font-bold text-primary-700">
                      {(tenant.shop_name || '?')[0]}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-[11px] font-medium text-surface-900 truncate leading-tight">
                        {tenant.shop_name || 'Unnamed'}
                      </p>
                      <p className="text-[9px] text-surface-400">
                        {new Date(tenant.created_at).toLocaleDateString('en-BD', { month: 'short', day: 'numeric' })}
                      </p>
                    </div>
                    <PlanBadge plan={tenant.plan} size="sm" />
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Quick Actions */}
          <div className="rounded-xl border border-surface-200/60 bg-white p-4 shadow-sm shrink-0">
            <h3 className="text-[10px] font-semibold uppercase tracking-widest text-surface-400 mb-2.5 font-display">Quick Actions</h3>
            <div className="flex flex-wrap gap-1.5">
              <button
                onClick={() => { setSearchQuery(''); setPlanFilter('free'); setStatusFilter('all'); }}
                className="flex items-center gap-1 rounded-lg border border-surface-200 bg-white px-2.5 py-1.5 text-[10px] font-medium text-surface-600 transition-all hover:border-amber-200 hover:bg-amber-50 hover:text-amber-700"
              >
                🆓 Free
              </button>
              <button
                onClick={() => { setSearchQuery(''); setPlanFilter('all'); setStatusFilter('cancelled'); }}
                className="flex items-center gap-1 rounded-lg border border-surface-200 bg-white px-2.5 py-1.5 text-[10px] font-medium text-surface-600 transition-all hover:border-red-200 hover:bg-red-50 hover:text-red-700"
              >
                🚫 Cancelled
              </button>
              <button
                onClick={() => {
                  const csv = [['Shop Name','Plan','Status','Staff','Products','Joined'], ...tenants.map((t) => [t.shop_name, t.plan, t.subscription_status, String(t.staff_count), String(t.product_count), new Date(t.created_at).toISOString().split('T')[0]])].map((row) => row.join(',')).join('\n');
                  const blob = new Blob([csv], { type: 'text/csv' });
                  const url = URL.createObjectURL(blob);
                  const a = document.createElement('a');
                  a.href = url;
                  a.download = `tenants-${new Date().toISOString().split('T')[0]}.csv`;
                  a.click();
                  URL.revokeObjectURL(url);
                }}
                className="flex items-center gap-1 rounded-lg border border-surface-200 bg-white px-2.5 py-1.5 text-[10px] font-medium text-surface-600 transition-all hover:border-emerald-200 hover:bg-emerald-50 hover:text-emerald-700"
              >
                📥 CSV
              </button>
              <button
                onClick={loadTenants}
                className="flex items-center gap-1 rounded-lg border border-surface-200 bg-white px-2.5 py-1.5 text-[10px] font-medium text-surface-600 transition-all hover:border-primary-200 hover:bg-primary-50 hover:text-primary-700"
              >
                ↻ Sync
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

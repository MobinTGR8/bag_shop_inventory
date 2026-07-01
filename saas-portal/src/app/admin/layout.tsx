'use client';

import { useAuth } from '@/components/AuthProvider';
import { useRouter, usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import Link from 'next/link';

const navItems = [
  {
    label: 'Dashboard',
    href: '/admin',
    icon: (
      <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
      </svg>
    ),
  },
  {
    label: 'Analytics',
    href: '/admin/analytics',
    icon: (
      <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
      </svg>
    ),
  },
];

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user, isLoading, isSuperAdmin, signOut } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    if (!isLoading && (!user || !isSuperAdmin)) {
      router.push('/login');
    }
  }, [user, isLoading, isSuperAdmin, router]);

  // Get current page name
  const currentPage =
    navItems.find((item) => pathname === item.href)?.label || 'Loading...';

  if (isLoading || !user || !isSuperAdmin) {
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
            Loading dashboard...
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen overflow-hidden bg-surface-50">
      {/* Mobile Overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden animate-fade-in"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 flex w-72 flex-col border-r border-surface-200/60 bg-white shadow-xl shadow-black/5 transition-transform duration-300 ease-in-out lg:static lg:translate-x-0 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Logo */}
        <div className="flex h-16 shrink-0 items-center gap-3 border-b border-surface-100 px-6">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 shadow-lg shadow-primary-500/20">
            <span className="text-sm font-bold text-white">BS</span>
          </div>
          <div>
            <span className="font-semibold text-surface-900">SaaS Admin</span>
            <p className="text-[10px] text-surface-400">Bag Shop Inventory</p>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4 custom-scrollbar">
          <p className="mb-2 px-3 text-[11px] font-semibold uppercase tracking-widest text-surface-400">
            Main Menu
          </p>
          {navItems.map((item, index) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setSidebarOpen(false)}
                className={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition-all duration-200 animate-fade-in-up ${
                  isActive
                    ? 'bg-gradient-to-r from-primary-50 to-primary-100/50 text-primary-700 shadow-sm'
                    : 'text-surface-600 hover:bg-surface-50 hover:text-surface-900'
                }`}
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                <span
                  className={
                    isActive ? 'text-primary-600' : 'text-surface-400'
                  }
                >
                  {item.icon}
                </span>
                <span className="flex-1">{item.label}</span>
                {isActive && (
                  <span className="h-2 w-2 rounded-full bg-primary-500 animate-pulse" />
                )}
              </Link>
            );
          })}
        </nav>

        {/* User Footer */}
        <div className="shrink-0 border-t border-surface-100 p-4">
          <div className="flex items-center gap-3 rounded-xl bg-gradient-to-r from-surface-50 to-primary-50/30 p-3">
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-primary-400 to-primary-600 text-xs font-bold text-white shadow-sm">
              {user.email?.[0].toUpperCase() || 'U'}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium text-surface-900">
                {user.email?.split('@')[0] || 'User'}
              </p>
              <p className="truncate text-xs text-surface-400">
                {user.email}
              </p>
            </div>
          </div>
          <button
            onClick={signOut}
            className="mt-2 flex w-full items-center gap-2 rounded-xl px-3 py-2.5 text-sm text-surface-500 transition-all hover:bg-red-50 hover:text-red-600"
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
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex flex-1 flex-col overflow-hidden">
        {/* Top Navbar (mobile) */}
        <header className="sticky top-0 z-30 flex h-16 shrink-0 items-center gap-4 border-b border-surface-200/60 bg-white/90 backdrop-blur-xl backdrop-safe px-4 lg:px-8">
          <button
            onClick={() => setSidebarOpen(true)}
            className="flex h-10 w-10 items-center justify-center rounded-xl text-surface-500 transition hover:bg-surface-100 active:bg-surface-200 lg:hidden"
            aria-label="Open sidebar"
          >
            <svg
              className="h-5 w-5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 6h16M4 12h16M4 18h16"
              />
            </svg>
          </button>

          {/* Breadcrumb */}
          <nav className="flex items-center gap-2 text-sm" aria-label="Breadcrumb">
            <span className="text-surface-400">Admin</span>
            <svg
              className="h-3 w-3 text-surface-300"
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
            <span className="font-medium text-surface-900">{currentPage}</span>
          </nav>

          <div className="ml-auto flex items-center gap-4">
            {/* Status indicator */}
            <div className="flex items-center gap-2 rounded-full bg-surface-100 px-3.5 py-1.5 text-xs font-medium text-surface-500">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />
                <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-500" />
              </span>
              Online
            </div>

            {/* Avatar (desktop) */}
            <div className="hidden sm:flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-primary-400 to-primary-600 text-xs font-bold text-white shadow-sm">
              {user.email?.[0].toUpperCase() || 'U'}
            </div>
          </div>
        </header>

        {/* Page Content */}
        <div className="flex-1 overflow-y-auto custom-scrollbar">
          <div className="animate-fade-in h-full">{children}</div>
        </div>
      </main>
    </div>
  );
}

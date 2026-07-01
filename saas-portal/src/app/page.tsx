'use client';

import { useAuth } from '@/components/AuthProvider';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export default function Home() {
  const { user, isLoading, isSuperAdmin } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (isLoading) return;

    if (!user) {
      router.push('/login');
    } else if (isSuperAdmin) {
      router.push('/admin');
    } else {
      router.push('/settings');
    }
  }, [user, isLoading, isSuperAdmin, router]);

  return (
    <div className="flex h-screen items-center justify-center bg-surface-50">
      <div className="flex flex-col items-center gap-6">
        <div className="relative">
          <div className="h-16 w-16 animate-spin rounded-full border-[3px] border-primary-100 border-t-primary-600 shadow-lg shadow-primary-500/10" />
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="h-6 w-6 rounded-full bg-gradient-to-br from-primary-500 to-primary-700" />
          </div>
        </div>
        <div className="text-center">
          <p className="text-sm font-medium text-surface-500 animate-pulse">Loading...</p>
          <p className="text-xs text-surface-400 mt-1">Preparing your dashboard</p>
        </div>
      </div>
    </div>
  );
}

'use client';

import { createClient } from '@/lib/supabase/client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { useAuth } from '@/components/AuthProvider';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const supabase = createClient();
  const router = useRouter();
  const { user, isLoading, isSuperAdmin } = useAuth();

  // If already logged in, redirect immediately - no flash
  if (user && isSuperAdmin && !isLoading) {
    router.push('/admin');
    return null;
  }
  if (user && !isSuperAdmin && !isLoading) {
    router.push('/settings');
    return null;
  }
  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-surface-950">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-primary-300 border-t-primary-600" />
      </div>
    );
  }

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setIsSubmitting(true);

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      toast.error(error.message);
      setIsSubmitting(false);
      return;
    }

    toast.success('Welcome back!');
    router.push('/');
    router.refresh();
  }

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-surface-950">
      {/* Animated gradient orbs */}
      <div className="absolute -top-40 -left-40 h-96 w-96 animate-float rounded-full bg-gradient-to-br from-primary-500/30 to-purple-500/20 blur-3xl" />
      <div className="absolute -bottom-40 -right-40 h-96 w-96 animate-float rounded-full bg-gradient-to-br from-blue-500/30 to-cyan-500/20 blur-3xl" style={{ animationDelay: '1.5s' }} />
      <div className="absolute top-1/2 left-1/2 h-64 w-64 -translate-x-1/2 -translate-y-1/2 rounded-full bg-gradient-to-br from-pink-500/10 to-primary-500/10 blur-3xl" style={{ animationDelay: '3s' }} />

      {/* Grid pattern overlay */}
      <div
        className="absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage: 'radial-gradient(circle, rgba(255,255,255,0.8) 1px, transparent 1px)',
          backgroundSize: '40px 40px',
        }}
      />

      {/* Floating particles */}
      <div className="absolute inset-0 overflow-hidden">
        {[...Array(6)].map((_, i) => (
          <div
            key={i}
            className="absolute h-1 w-1 rounded-full bg-white/20 animate-float"
            style={{
              left: `${10 + i * 18}%`,
              top: `${20 + (i % 3) * 30}%`,
              animationDelay: `${i * 0.5}s`,
              animationDuration: `${3 + i * 0.5}s`,
            }}
          />
        ))}
      </div>

      <div className="relative z-10 w-full max-w-md px-4 animate-fade-in-up">
        {/* Logo */}
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-500 to-primary-700 shadow-lg shadow-primary-500/30 animate-glow">
            <svg className="h-8 w-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
            </svg>
          </div>
          <h1 className="text-3xl font-bold text-white">Bag Shop SaaS</h1>
          <p className="mt-2 text-sm text-surface-400">
            Sign in to manage your account or tenants
          </p>
        </div>

        {/* Card */}
        <div className="relative group">
          <div className="absolute -inset-0.5 rounded-2xl bg-gradient-to-r from-primary-500 via-purple-500 to-pink-500 opacity-30 blur transition duration-500 group-hover:opacity-50" />
          <div className="relative rounded-2xl bg-surface-900/80 backdrop-blur-xl border border-white/10 p-8 shadow-2xl">
            <form onSubmit={handleLogin} className="space-y-5">
              <div className="animate-fade-in-up" style={{ animationDelay: '0.1s' }}>
                <label className="block text-sm font-medium text-surface-300 mb-1.5">
                  Email Address
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@example.com"
                  required
                  className="w-full rounded-xl border border-surface-700 bg-surface-800/50 px-4 py-3 text-sm text-white placeholder-surface-500 transition-all duration-200 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
                />
              </div>

              <div className="animate-fade-in-up" style={{ animationDelay: '0.2s' }}>
                <label className="block text-sm font-medium text-surface-300 mb-1.5">
                  Password
                </label>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  className="w-full rounded-xl border border-surface-700 bg-surface-800/50 px-4 py-3 text-sm text-white placeholder-surface-500 transition-all duration-200 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
                />
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                className="btn-primary w-full animate-fade-in-up"
                style={{ animationDelay: '0.3s' }}
              >
                {isSubmitting ? (
                  <span className="flex items-center gap-2">
                    <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    Signing in...
                  </span>
                ) : (
                  'Sign In'
                )}
              </button>
            </form>
          </div>
        </div>

        <p className="mt-6 text-center text-xs text-surface-500 animate-fade-in" style={{ animationDelay: '0.5s' }}>
          Admins manage tenants here.
          <br />
          Shop owners can upgrade plans and view usage.
        </p>
      </div>
    </div>
  );
}

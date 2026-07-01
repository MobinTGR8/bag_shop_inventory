'use client';

import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-surface-50 px-4">
      {/* Background decoration */}
      <div className="absolute -top-40 -right-40 h-96 w-96 animate-float rounded-full bg-gradient-to-br from-primary-500/20 to-purple-500/10 blur-3xl" />
      <div className="absolute -bottom-40 -left-40 h-96 w-96 animate-float rounded-full bg-gradient-to-br from-blue-500/20 to-cyan-500/10 blur-3xl" style={{ animationDelay: '1.5s' }} />

      <div className="relative z-10 text-center animate-fade-in-up">
        <div className="text-8xl font-black text-surface-200">404</div>
        <div className="-mt-4 mb-6">
          <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-100 to-purple-100 shadow-lg">
            <span className="text-4xl">🔍</span>
          </div>
        </div>
        <h1 className="text-2xl font-bold text-surface-900">Page not found</h1>
        <p className="mt-2 text-surface-400 max-w-sm mx-auto">
          The page you&apos;re looking for doesn&apos;t exist or has been moved.
        </p>
        <div className="mt-8 flex items-center justify-center gap-3">
          <Link href="/" className="btn-primary">
            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            </svg>
            Go Home
          </Link>
          <button onClick={() => window.history.back()} className="btn-secondary">
            Go Back
          </button>
        </div>
      </div>
    </div>
  );
}

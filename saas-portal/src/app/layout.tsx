import type { Metadata, Viewport } from 'next';
import './globals.css';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from '@/components/AuthProvider';

export const metadata: Metadata = {
  title: {
    default: 'Bag Shop SaaS — Admin Portal',
    template: '%s | Bag Shop SaaS',
  },
  description:
    'Enterprise-grade inventory management for bag shops. Manage tenants, plans, and subscriptions with real-time analytics and premium features.',
  keywords: [
    'inventory',
    'bag shop',
    'saas',
    'billing',
    'management',
    'subscription',
    'analytics',
  ],
  authors: [{ name: 'Bag Shop Inventory' }],
  creator: 'Bag Shop Inventory',
  publisher: 'Bag Shop Inventory',
  openGraph: {
    title: 'Bag Shop SaaS Portal',
    description: 'Enterprise-grade inventory management for bag shops',
    type: 'website',
    locale: 'en_US',
    siteName: 'Bag Shop SaaS',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Bag Shop SaaS Portal',
    description: 'Enterprise-grade inventory management for bag shops',
  },
  robots: {
    index: false,
    follow: false,
  },
};

export const viewport: Viewport = {
  themeColor: '#4f46e5',
  colorScheme: 'light',
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="custom-scrollbar">
      <body className="min-h-screen bg-surface-50 antialiased">
        <AuthProvider>
          {children}
          <Toaster
            position="top-right"
            gutter={8}
            containerClassName="!z-[100]"
            toastOptions={{
              duration: 4000,
              style: {
                borderRadius: '14px',
                padding: '16px 20px',
                fontSize: '14px',
                fontWeight: '500',
                lineHeight: '1.5',
                boxShadow:
                  '0 10px 40px rgba(0,0,0,0.12), 0 2px 8px rgba(0,0,0,0.06)',
              },
              success: {
                iconTheme: { primary: '#10b981', secondary: '#fff' },
                style: {
                  borderLeft: '4px solid #10b981',
                  background: '#f0fdf4',
                },
              },
              error: {
                iconTheme: { primary: '#ef4444', secondary: '#fff' },
                style: {
                  borderLeft: '4px solid #ef4444',
                  background: '#fef2f2',
                },
              },
            }}
          />
        </AuthProvider>
      </body>
    </html>
  );
}

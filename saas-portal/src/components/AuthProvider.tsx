'use client';

import { createClient } from '@/lib/supabase/client';
import { useRouter } from 'next/navigation';
import { createContext, useContext, useEffect, useState } from 'react';
import type { User } from '@supabase/supabase-js';

interface AuthContextValue {
  user: User | null;
  isLoading: boolean;
  isSuperAdmin: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue>({
  user: null,
  isLoading: true,
  isSuperAdmin: false,
  signOut: async () => {},
});

export function useAuth() {
  return useContext(AuthContext);
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);
  const supabase = createClient();
  const router = useRouter();

  async function checkSuperAdmin(userId: string): Promise<boolean> {
    try {
      const res = await fetch('/api/admin/check');
      const json = await res.json();
      return json.isSuperAdmin === true;
    } catch {
      return false;
    }
  }

  useEffect(() => {
    let mounted = true;

    async function init() {
      const { data } = await supabase.auth.getUser();
      if (!mounted) return;

      const currentUser = data.user ?? null;
      setUser(currentUser);

      if (currentUser) {
        const admin = await checkSuperAdmin(currentUser.id);
        if (mounted) {
          setIsSuperAdmin(admin);
          setIsLoading(false);
        }
      } else {
        if (mounted) setIsLoading(false);
      }
    }

    init();

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (_event, session) => {
      const currentUser = session?.user ?? null;
      setUser(currentUser);

      if (currentUser) {
        const admin = await checkSuperAdmin(currentUser.id);
        if (mounted) setIsSuperAdmin(admin);
      } else {
        if (mounted) setIsSuperAdmin(false);
      }
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  async function signOut() {
    await supabase.auth.signOut();
    router.push('/login');
    router.refresh();
  }

  return (
    <AuthContext.Provider value={{ user, isLoading, isSuperAdmin, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

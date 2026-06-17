---
description: Supabase — auth, RLS, realtime, Edge Functions, expo-secure-store token storage
globs: "**/{services,lib,hooks,supabase}/**/*.{ts,tsx}"
alwaysApply: false
---

# Supabase

## Client Setup

```tsx
// lib/supabase.ts
import { createClient } from '@supabase/supabase-js';
import * as SecureStore from 'expo-secure-store';
import type { Database } from './database.types';

const ExpoSecureStoreAdapter = {
  getItem: (key: string) => SecureStore.getItemAsync(key),
  setItem: (key: string, value: string) => SecureStore.setItemAsync(key, value),
  removeItem: (key: string) => SecureStore.deleteItemAsync(key),
};

export const supabase = createClient<Database>(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      storage: ExpoSecureStoreAdapter, // NEVER use AsyncStorage
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  }
);
```

## Auth Hook

```tsx
// hooks/useAuth.ts
import { useEffect, useState } from 'react';
import { Session } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';

export function useAuth() {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, []);

  return { session, user: session?.user ?? null, loading };
}
```

## Querying with RLS

```tsx
// RLS enabled → user can only see their own rows
const { data, error } = await supabase
  .from('brackets')
  .select('id, picks, champion_id, status')
  .eq('user_id', user.id) // RLS enforces this anyway, but be explicit
  .order('created_at', { ascending: false });

// Type-safe with generated types
const { data: bracket } = await supabase
  .from('brackets')
  .select('*')
  .eq('id', bracketId)
  .single();
```

## Edge Functions (AI prompts ALWAYS here)

```tsx
// services/aiService.ts
export async function generateRoast(bracketId: string, locale: string) {
  const { data, error } = await supabase.functions.invoke('generate-roast', {
    body: { bracketId, locale },
  });
  if (error) throw error;
  return data as { roast: string };
}

// supabase/functions/generate-roast/index.ts (Edge Function)
// AI prompts live ONLY here — never in the client app
```

## Realtime

```tsx
useEffect(() => {
  const channel = supabase
    .channel(`bracket:${bracketId}`)
    .on('postgres_changes', {
      event: 'UPDATE',
      schema: 'public',
      table: 'brackets',
      filter: `id=eq.${bracketId}`,
    }, (payload) => {
      setBracket(payload.new as Bracket);
    })
    .subscribe();

  return () => { supabase.removeChannel(channel); };
}, [bracketId]);
```

## Common Mistakes

```tsx
// ❌ Store tokens in AsyncStorage
AsyncStorage.setItem('supabase_session', token); // NEVER

// ❌ Call AI/LLM from client
const response = await openai.chat(...); // NEVER in app code

// ❌ Skip RLS — query without user context
supabase.from('brackets').select('*'); // returns nothing if RLS active

// ❌ Hardcode env vars
const url = 'https://xyz.supabase.co'; // use EXPO_PUBLIC_*
```

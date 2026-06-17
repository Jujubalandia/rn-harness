---
description: Zustand state management — store patterns, slices, selectors, persist, devtools
globs: "**/*.{ts,tsx}"
alwaysApply: false
---

# Zustand

One store per domain. Slice pattern for large state.

## Store Pattern

```tsx
// stores/useAuthStore.ts
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import * as SecureStore from 'expo-secure-store';

interface AuthState {
  user: User | null;
  session: Session | null;
  setSession: (session: Session | null) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      session: null,
      setSession: (session) => set({ session, user: session?.user ?? null }),
      logout: () => set({ user: null, session: null }),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => ({
        // Use SecureStore for sensitive state
        getItem: (k) => SecureStore.getItemAsync(k),
        setItem: (k, v) => SecureStore.setItemAsync(k, v),
        removeItem: (k) => SecureStore.deleteItemAsync(k),
      })),
    }
  )
);
```

## Selector Pattern (performance)

```tsx
// GOOD: subscribe to only what you need
const user = useAuthStore((s) => s.user);
const logout = useAuthStore((s) => s.logout);

// BAD: subscribe to whole store (re-renders on any change)
const store = useAuthStore();
```

## State Table

| State type | Tool |
|-----------|------|
| Auth session, user | Zustand + SecureStore persist |
| UI state (modals, tabs) | Zustand (no persist) |
| Server data | Zustand + useEffect fetch |
| Component-local | useState |
| Form data | React Hook Form |
| Derived/computed | useMemo |

## Async Actions

```tsx
interface BracketState {
  brackets: Bracket[];
  loading: boolean;
  fetchBrackets: () => Promise<void>;
}

const useBracketStore = create<BracketState>()((set) => ({
  brackets: [],
  loading: false,
  fetchBrackets: async () => {
    set({ loading: true });
    const { data } = await supabase.from('brackets').select('*');
    set({ brackets: data ?? [], loading: false });
  },
}));
```

## Common Mistakes

```tsx
// ❌ Mutate state directly
store.user.name = 'new'; // Zustand state is immutable

// ❌ Subscribe to entire store in hot-path components
const everything = useMyStore(); // causes re-render on any change

// ❌ Sensitive data in AsyncStorage-backed persist
// Always use SecureStore adapter for auth/tokens

// ❌ One massive store for everything
// Split by domain: useAuthStore, useBracketStore, useUIStore
```

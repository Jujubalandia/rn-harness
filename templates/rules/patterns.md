---
description: React Native architectural patterns — components, hooks, services, barrel exports, error boundaries
globs: "**/*.{ts,tsx}"
alwaysApply: false
---

# Patterns

## Folder Structure

```
app/               ← Expo Router screens
components/
  bracket/         ← feature folder
    BracketCard.tsx
    BracketCard.test.tsx
    index.ts       ← barrel export
hooks/             ← ALL business logic
  useAuth.ts
  useBracket.ts
services/          ← external API calls only
  bracketService.ts
  sharingService.ts
stores/            ← Zustand stores
  useAuthStore.ts
lib/
  supabase.ts
  i18n.ts
  types.ts         ← domain types
locales/
  pt.json
  en.json
  es.json
```

## Component Rules

```tsx
// Named exports only — no default exports in components
export function BracketCard({ bracket, onPress }: BracketCardProps) { ... }

// Props interface: ComponentNameProps
interface BracketCardProps {
  bracket: Bracket;
  onPress: (id: string) => void;
}

// One component per file
// Colocated small helpers OK (not exported)
```

## Custom Hooks for ALL Business Logic

```tsx
// hooks/useBracket.ts
export function useBracket(bracketId: string) {
  const [bracket, setBracket] = useState<Bracket | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    bracketService.get(bracketId).then(setBracket).finally(() => setLoading(false));
  }, [bracketId]);

  const lock = useCallback(async () => {
    await bracketService.lock(bracketId);
    setBracket(prev => prev ? { ...prev, status: 'locked' } : prev);
  }, [bracketId]);

  return { bracket, loading, lock };
}

// Screen only calls the hook, no business logic inline
function BracketScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { bracket, loading, lock } = useBracket(id);
  // ...
}
```

## Barrel Exports

```tsx
// components/bracket/index.ts
export { BracketCard } from './BracketCard';
export { BracketGrid } from './BracketGrid';
export type { BracketCardProps } from './BracketCard';

// Import clean
import { BracketCard, BracketGrid } from '@/components/bracket';
```

## Error Boundaries

```tsx
// Minimum: error boundary per route segment
// app/_layout.tsx
import * as Sentry from '@sentry/react-native'; // if used

export const ErrorBoundary = ({ error }: ErrorBoundaryProps) => (
  <ErrorScreen message={error.message} />
);
```

## Path Alias

```tsx
// tsconfig.json: "baseUrl": ".", "paths": { "@/*": ["./*"] }
import { supabase } from '@/lib/supabase';  // ✅
import { supabase } from '../../../lib/supabase'; // ❌
```

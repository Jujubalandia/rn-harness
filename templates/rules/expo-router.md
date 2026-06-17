---
description: Expo Router v3 file-based routing — layouts, typed routes, navigation patterns
globs: "app/**/*.{ts,tsx}"
alwaysApply: false
---

# Expo Router v3

File-based routing in `app/`. Each file = one route.

## File Conventions

```
app/
  _layout.tsx          # Root Stack layout
  index.tsx            # / (home)
  +not-found.tsx       # 404 catch-all
  (tabs)/
    _layout.tsx        # Tabs layout
    index.tsx          # /  (first tab)
    explore.tsx        # /explore
  (auth)/
    _layout.tsx        # Auth stack (no tabs shown)
    login.tsx          # /login
  bracket/
    [id].tsx           # /bracket/abc123
    [id]/results.tsx   # /bracket/abc123/results
```

## Navigation

```tsx
import { router, useLocalSearchParams, Link } from 'expo-router';

// Push
router.push('/bracket/123');
router.push({ pathname: '/bracket/[id]', params: { id: '123' } });

// Replace (no back)
router.replace('/login');

// Back
router.back();

// Typed params
const { id } = useLocalSearchParams<{ id: string }>();

// Declarative
<Link href="/explore">Explorar</Link>
<Link href={{ pathname: '/bracket/[id]', params: { id } }}>Ver bracket</Link>
```

## Layouts

```tsx
// Stack
import { Stack } from 'expo-router';

export default function Layout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="index" options={{ title: 'Home' }} />
      <Stack.Screen name="[id]" options={{ presentation: 'modal' }} />
    </Stack>
  );
}

// Tabs
import { Tabs } from 'expo-router';

export default function TabLayout() {
  return (
    <Tabs screenOptions={{ tabBarActiveTintColor: COLORS.primary }}>
      <Tabs.Screen name="index" options={{ title: 'Home', tabBarIcon: ({ color }) => <HomeIcon color={color} /> }} />
    </Tabs>
  );
}
```

## Deep Links

```tsx
// app.config.ts
export default {
  scheme: 'myapp', // enables myapp:// deep links
};

// Incoming: myapp://bracket/123 → app/bracket/[id].tsx with id='123'
```

## Common Mistakes

```tsx
// ❌ Use React Navigation directly (breaks Expo Router)
// Always use router.push / <Link> from expo-router

// ❌ Name file with spaces or uppercase
// app/MyScreen.tsx → use kebab-case: my-screen.tsx

// ❌ Forget _layout.tsx in (group) folders
// Every nested routing group needs its own _layout.tsx

// ❌ Use useRouter for simple back
router.back(); // ✅ not useRouter().back()
```

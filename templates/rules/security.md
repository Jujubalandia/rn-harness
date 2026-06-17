---
description: Mobile security — expo-secure-store, env vars, deep link validation, no hardcoded secrets
globs: "**/*.{ts,tsx,js,jsx}"
alwaysApply: false
---

# Security

## Token Storage — expo-secure-store ONLY

```tsx
import * as SecureStore from 'expo-secure-store';

// GOOD
await SecureStore.setItemAsync('auth_token', token);
const token = await SecureStore.getItemAsync('auth_token');
await SecureStore.deleteItemAsync('auth_token');

// BAD: AsyncStorage is NOT encrypted — plain text on device
await AsyncStorage.setItem('auth_token', token); // NEVER for sensitive data
```

## Environment Variables

```tsx
// .env.local (git-ignored)
EXPO_PUBLIC_SUPABASE_URL=https://xyz.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE=eyJ... // server-only, NOT EXPO_PUBLIC_

// Usage
const url = process.env.EXPO_PUBLIC_SUPABASE_URL!;

// ❌ Never hardcode
const url = 'https://xyz.supabase.co';
const key = 'sk-1234567890';
```

## AI / LLM Prompts — Edge Functions ONLY

```tsx
// ❌ Never call AI from client
const res = await openai.chat.completions.create({ ... }); // exposes API key

// ✅ Always via Supabase Edge Function
const { data } = await supabase.functions.invoke('generate-roast', {
  body: { bracketId, locale },
});
```

## Deep Link Validation

```tsx
import * as Linking from 'expo-linking';
import { router } from 'expo-router';

const ALLOWED_PATHS = ['/bracket/', '/challenge/'];

function handleDeepLink(url: string) {
  const { path } = Linking.parse(url);
  const isAllowed = ALLOWED_PATHS.some(p => path?.startsWith(p));
  if (!isAllowed) return; // silently reject unknown paths
  router.push(path as never);
}
```

## Input Sanitization

```tsx
// Sanitize user-generated content before display
// Never pass raw input to SQL (use Supabase client — parameterized by default)
// Never eval() or pass user input to dynamic imports
```

## EAS Secrets (CI/CD)

```bash
# Build-time secrets (not in .env, not in git)
eas secret:create --scope project --name SUPABASE_SERVICE_ROLE --value "eyJ..."
```

## Common Mistakes

```
❌ API keys in source code (caught by git-secret / trufflehog in pre-commit)
❌ EXPO_PUBLIC_ prefix on server-only secrets (exposes to client bundle)
❌ Service role key in client app (bypasses RLS entirely)
❌ AI prompts in client (exposes API key in bundle)
❌ No deep link validation (open redirect attack)
```

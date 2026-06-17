---
description: StyleSheet.create conventions — design tokens, no hardcoded colors/spacing, dark mode
globs: "**/*.{ts,tsx}"
alwaysApply: false
---

# Styling

## Design Tokens (never hardcode values)

```tsx
// lib/tokens.ts
export const COLORS = {
  primary: '#1D4ED8',
  primaryDark: '#1E40AF',
  surface: '#FFFFFF',
  surfaceDark: '#1F2937',
  text: '#111827',
  textSecondary: '#6B7280',
  textDark: '#F9FAFB',
  error: '#DC2626',
  success: '#16A34A',
  border: '#E5E7EB',
} as const;

export const SPACING = {
  xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48,
} as const;

export const RADIUS = {
  sm: 4, md: 8, lg: 16, full: 9999,
} as const;

export const FONT_SIZE = {
  xs: 12, sm: 14, md: 16, lg: 18, xl: 24, xxl: 32,
} as const;
```

## StyleSheet.create Pattern

```tsx
import { StyleSheet } from 'react-native';
import { COLORS, SPACING, RADIUS, FONT_SIZE } from '@/lib/tokens';

export function BracketCard({ bracket }: Props) {
  return (
    <Pressable style={styles.container}>
      <Text style={styles.title}>{bracket.name}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    marginBottom: SPACING.sm,
  },
  title: {
    fontSize: FONT_SIZE.md,
    color: COLORS.text,
    fontWeight: '600',
  },
});
```

## Dark Mode

```tsx
import { useColorScheme } from 'react-native';
import { COLORS } from '@/lib/tokens';

function useTheme() {
  const scheme = useColorScheme();
  return {
    background: scheme === 'dark' ? COLORS.surfaceDark : COLORS.surface,
    text: scheme === 'dark' ? COLORS.textDark : COLORS.text,
  };
}

// Usage
const theme = useTheme();
<View style={{ backgroundColor: theme.background }}>
```

## Common Mistakes

```tsx
// ❌ Hardcoded color
style={{ color: '#111827' }}
style={{ padding: 16 }}

// ✅ Token
style={{ color: COLORS.text }}
style={{ padding: SPACING.md }}

// ❌ Inline style in list items (new object each render)
<ListItem style={{ margin: 8, borderRadius: 12 }} />

// ✅ StyleSheet.create (flattened at startup)
const styles = StyleSheet.create({ item: { margin: SPACING.sm, borderRadius: RADIUS.md } });

// ❌ Mix of hardcoded and tokens
style={{ padding: SPACING.md, borderRadius: 8 }} // borderRadius should use RADIUS.md
```

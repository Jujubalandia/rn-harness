---
description: Accessibility — accessibilityLabel (i18n), roles, minimum touch targets, screen reader
globs: "**/*.{ts,tsx}"
alwaysApply: false
---

# Accessibility

Rule: **every interactive element needs `accessibilityLabel` with `t()`** (never hardcoded string).

## Labels & Roles

```tsx
import { useTranslation } from 'react-i18next';

function TeamCard({ team, onSelect, selected }: Props) {
  const { t } = useTranslation();

  return (
    <Pressable
      onPress={() => onSelect(team.id)}
      accessibilityRole="button"
      accessibilityLabel={t('bracket.select_team', { name: team.name })}
      accessibilityState={{ selected }}
      style={[styles.card, selected && styles.selected]}
    >
      <Image source={team.flag_url} accessibilityRole="image"
        accessibilityLabel={t('bracket.team_flag', { name: team.name })} />
      <Text>{team.name}</Text>
    </Pressable>
  );
}
```

## Touch Targets — minimum 44pt

```tsx
const styles = StyleSheet.create({
  button: {
    minWidth: 44,
    minHeight: 44,   // ✅ Apple HIG minimum
    justifyContent: 'center',
    alignItems: 'center',
    padding: 12,     // adds to touch area
  },
});

// For icon-only buttons — use hitSlop
<Pressable
  hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
  onPress={close}
  accessibilityLabel={t('common.close')}
>
  <CloseIcon />
</Pressable>
```

## Screen Reader Grouping

```tsx
// Group related elements to reduce noise
<View accessible={true} accessibilityLabel={t('bracket.match_result', { home, away, score })}>
  <Text>{home}</Text>
  <Text>{score}</Text>
  <Text>{away}</Text>
</View>
```

## Focus Management

```tsx
import { AccessibilityInfo, findNodeHandle } from 'react-native';

// Move focus after modal opens
useEffect(() => {
  if (visible && ref.current) {
    const node = findNodeHandle(ref.current);
    if (node) AccessibilityInfo.setAccessibilityFocus(node);
  }
}, [visible]);
```

## Loading States

```tsx
<ActivityIndicator
  accessibilityLabel={t('common.loading')}
  accessibilityRole="progressbar"
/>
```

## Common Mistakes

```tsx
// ❌ Hardcoded accessibilityLabel
<Pressable accessibilityLabel="Fechar" />

// ✅ Always via t()
<Pressable accessibilityLabel={t('common.close')} />

// ❌ Icon-only button with no label
<Pressable onPress={share}><ShareIcon /></Pressable>

// ✅
<Pressable onPress={share} accessibilityLabel={t('bracket.share')}><ShareIcon /></Pressable>

// ❌ Touch target < 44pt
style={{ width: 24, height: 24 }} // too small

// ❌ Image without accessibility
<Image source={flagUrl} /> // add accessibilityLabel or accessibilityRole="none" if decorative
```

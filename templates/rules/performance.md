---
description: React Native performance — FlatList, memoization, image optimization, bundle size
globs: "**/*.{ts,tsx}"
alwaysApply: false
---

# Performance

## Lists

```tsx
// GOOD: FlatList for > 20 items
<FlatList
  data={brackets}
  keyExtractor={(item) => item.id}
  renderItem={renderBracketCard}   // defined outside render with useCallback
  getItemLayout={(_, index) => ({ length: CARD_HEIGHT, offset: CARD_HEIGHT * index, index })}
  maxToRenderPerBatch={10}
  windowSize={5}
  removeClippedSubviews={true}
/>

// BAD: ScrollView with map (renders all at once)
<ScrollView>
  {brackets.map(b => <BracketCard key={b.id} bracket={b} />)}
</ScrollView>
```

## Memoization

```tsx
// Memoize stable callbacks passed to list items
const handlePress = useCallback((id: string) => {
  router.push({ pathname: '/bracket/[id]', params: { id } });
}, []);

// Memoize expensive computations
const sortedBrackets = useMemo(
  () => [...brackets].sort((a, b) => b.created_at.localeCompare(a.created_at)),
  [brackets]
);

// Memoize list item components
const BracketCard = memo(function BracketCard({ bracket, onPress }: Props) { ... });
```

## Images

```tsx
// Use expo-image (caching, blurhash placeholder)
import { Image } from 'expo-image';

<Image
  source={team.flag_url}
  style={styles.flag}
  placeholder={team.blurhash}
  contentFit="cover"
  transition={200}
/>

// Avoid <Image> from react-native for remote images (no cache)
```

## Re-render Debugging

```tsx
// Add during development to detect extra renders
// Remove before commit
const renderCount = useRef(0);
console.log(`BracketCard render #${++renderCount.current}`);
```

## Bundle Size

- Import only what you use: `import { create } from 'zustand'` not `import * as zustand`
- Lazy-load heavy screens: `const HeavyScreen = lazy(() => import('./HeavyScreen'))`
- No `lodash` — use native JS: `arr.find()`, `Object.keys()`, `arr.filter()`
- SVG flags > PNG (smaller, scalable, no resolution variants)

## Common Mistakes

```tsx
// ❌ Inline object/function in JSX (creates new reference every render)
<BracketCard style={{ margin: 8 }} onPress={() => navigate(id)} />

// ✅
const cardStyle = { margin: 8 }; // outside component or StyleSheet.create
<BracketCard style={cardStyle} onPress={handlePress} />

// ❌ useEffect with no deps array (runs every render)
useEffect(() => { fetchData(); }); // missing []

// ❌ Heavy work in render
function Screen() {
  const sorted = items.sort(...); // runs every render — use useMemo
}
```

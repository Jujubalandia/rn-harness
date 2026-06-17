---
description: React Native Gesture Handler v2 — Builder API, GestureDetector, simultaneous gestures
globs: "**/*.{ts,tsx}"
alwaysApply: false
---

# React Native Gesture Handler v2

Expo SDK 56 uses GH **v2** (Builder API). All gestures run on the native thread.

## Setup Requirement

```tsx
// app/_layout.tsx (root)
import 'react-native-gesture-handler'; // MUST be first import

// Wrap root in GestureHandlerRootView
import { GestureHandlerRootView } from 'react-native-gesture-handler';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <Stack />
    </GestureHandlerRootView>
  );
}
```

## Builder API (v2)

```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { useSharedValue, withSpring } from 'react-native-reanimated';

function DraggableCard() {
  const offsetX = useSharedValue(0);
  const offsetY = useSharedValue(0);
  const startX = useSharedValue(0);
  const startY = useSharedValue(0);

  // MUST wrap in useMemo (v2 requirement)
  const panGesture = useMemo(() =>
    Gesture.Pan()
      .onStart(() => {
        startX.value = offsetX.value;
        startY.value = offsetY.value;
      })
      .onUpdate((e) => {
        offsetX.value = startX.value + e.translationX;
        offsetY.value = startY.value + e.translationY;
      })
      .onEnd(() => {
        offsetX.value = withSpring(0);
        offsetY.value = withSpring(0);
      }),
    []
  );

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: offsetX.value }, { translateY: offsetY.value }],
  }));

  return (
    <GestureDetector gesture={panGesture}>
      <Animated.View style={[styles.card, animatedStyle]} />
    </GestureDetector>
  );
}
```

## Simultaneous Gestures

```tsx
const tap = useMemo(() => Gesture.Tap().onEnd(() => runOnJS(handleTap)()), []);
const pan = useMemo(() => Gesture.Pan().onUpdate((e) => { /* ... */ }), []);

// Both run at same time
const composed = Gesture.Simultaneous(tap, pan);

<GestureDetector gesture={composed}>
  <Animated.View />
</GestureDetector>
```

## Common Mistakes

```tsx
// ❌ Forget useMemo — gesture re-created every render
const bad = Gesture.Pan().onUpdate(() => {}); // no useMemo

// ❌ Forget GestureHandlerRootView at root
// Gestures silently fail or crash on Android

// ❌ Use TouchableOpacity inside GestureDetector without config
// Use activeOpacity={1} or replace with Pressable
```

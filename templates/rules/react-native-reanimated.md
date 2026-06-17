---
description: React Native Reanimated v3 — shared values, animated styles, transitions, runOnJS
globs: "**/*.{ts,tsx}"
alwaysApply: false
---

# React Native Reanimated v3

Expo SDK 56 ships Reanimated **v3** (not v4). Worklets run on the UI thread.

## Core Imports

```tsx
import Animated, {
  useSharedValue, useAnimatedStyle,
  withSpring, withTiming, withSequence, withDelay,
  runOnJS, interpolate, Extrapolation,
} from 'react-native-reanimated';
```

## Shared Values + Animated Style

```tsx
const opacity = useSharedValue(0);
const scale = useSharedValue(1);

const animatedStyle = useAnimatedStyle(() => ({
  opacity: opacity.value,
  transform: [{ scale: scale.value }],
}));

// Trigger
opacity.value = withSpring(1);
scale.value = withTiming(0.95, { duration: 150 });

// Component must be Animated.*
<Animated.View style={[styles.box, animatedStyle]} />
```

## Call JS from Worklet

```tsx
// GOOD: wrap JS callbacks with runOnJS
const onAnimationEnd = () => setVisible(false);

const animatedStyle = useAnimatedStyle(() => {
  if (opacity.value === 0) runOnJS(onAnimationEnd)();
  return { opacity: opacity.value };
});

// BAD: call JS directly from worklet (crashes)
const bad = useAnimatedStyle(() => {
  if (opacity.value === 0) setVisible(false); // ERROR
  return {};
});
```

## Haptic with Animation

```tsx
import * as Haptics from 'expo-haptics';

const triggerHaptic = () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

// In worklet:
offset.value = withSpring(0, {}, () => {
  runOnJS(triggerHaptic)();
});
```

## Layout Animations

```tsx
import { FadeIn, FadeOut, SlideInRight, Layout } from 'react-native-reanimated';

<Animated.View entering={FadeIn.duration(300)} exiting={FadeOut} layout={Layout.springify()}>
  <CardComponent />
</Animated.View>
```

## Common Mistakes

```tsx
// ❌ setState inside useAnimatedStyle
const bad = useAnimatedStyle(() => {
  setState(value.value); // crashes — always on UI thread
  return {};
});

// ❌ useSharedValue inside conditional
if (condition) {
  const v = useSharedValue(0); // hooks rule violation
}

// ✅ Always declare at component top level
const v = useSharedValue(0);
```

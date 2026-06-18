---
description: Padrões proibidos no harness — causam bugs silenciosos em produção Android/iOS. Aplicar em qualquer arquivo .ts/.tsx.
globs: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"]
alwaysApply: true
---

# Padrões Proibidos

## lineHeight em StyleSheet

```typescript
// ❌ NUNCA — causa texto cortado em Android
const styles = StyleSheet.create({
  text: {
    lineHeight: 24, // PROIBIDO
  },
});

// ✅ Usar padding/margin para espaçamento vertical
const styles = StyleSheet.create({
  text: {
    paddingVertical: 4,
  },
});
```

`lineHeight` comporta-se diferente entre iOS e Android — em Android pode cortar descenders (g, p, y). Use `paddingVertical` ou `marginVertical` para controlar espaçamento.

---

## expo-av — deprecated

```typescript
// ❌ NUNCA
import { Video } from 'expo-av';
import { Audio } from 'expo-av';

// ✅ APIs separadas e mantidas
import { VideoView } from 'expo-video';
import { useAudioPlayer } from 'expo-audio';
```

`expo-av` está deprecated desde Expo SDK 50. Usar `expo-video` para vídeo e `expo-audio` para áudio.

---

## AsyncStorage para dados sensíveis

```typescript
// ❌ NUNCA para tokens, sessões, dados do usuário
import AsyncStorage from '@react-native-async-storage/async-storage';
await AsyncStorage.setItem('auth_token', token); // texto puro no disco

// ✅ expo-secure-store para qualquer dado sensível
import * as SecureStore from 'expo-secure-store';
await SecureStore.setItemAsync('auth_token', token); // criptografado
```

AsyncStorage armazena em texto puro. Use `expo-secure-store` para tokens, sessões e dados do usuário.

---

## expo-ads-admob — deprecated

```typescript
// ❌ NUNCA — pacote abandonado
import { AdMobBanner } from 'expo-ads-admob';

// ✅ Biblioteca mantida
import { BannerAd } from 'react-native-google-mobile-ads';
```

`expo-ads-admob` foi descontinuado. Usar `react-native-google-mobile-ads`.

---

## Tabs legado do expo-router

```typescript
// ❌ Tabs de baixo desempenho, especialmente iOS
import { Tabs } from 'expo-router';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

// ✅ NativeTabs — animações nativas por plataforma
import { Tabs } from 'expo-router/unstable-native-tabs';
```

`expo-router/unstable-native-tabs` usa `UITabBarController` no iOS e `BottomNavigationView` no Android — desempenho nativo vs JS bridge.

---

## Checklist de auditoria

Antes de commitar, verificar ausência de:
- `lineHeight:` em qualquer StyleSheet
- `from 'expo-av'`
- `expo-ads-admob`
- `AsyncStorage` fora de contextos não-sensíveis
- `from 'expo-router'` importando `Tabs` (deve vir de `expo-router/unstable-native-tabs`)

---
description: Regras para RevenueCat (react-native-purchases) — IAP e subscriptions no iOS e Android. Aplicar quando MONETIZATION = RevenueCat.
globs: ["**/*.ts", "**/*.tsx"]
alwaysApply: false
---
# RevenueCat (react-native-purchases)

## Setup

```bash
npx expo install react-native-purchases
npx expo install expo-build-properties
```

```json
// app.json plugins
{
  "expo": {
    "plugins": [
      ["react-native-purchases", { "apiKey": "" }]
    ]
  }
}
```

## Inicialização (uma vez no app root)

```typescript
import Purchases, { LOG_LEVEL } from 'react-native-purchases';

const RC_API_KEY = Platform.select({
  ios: process.env.EXPO_PUBLIC_RC_IOS_KEY!,
  android: process.env.EXPO_PUBLIC_RC_ANDROID_KEY!,
});

Purchases.setLogLevel(LOG_LEVEL.VERBOSE); // só em __DEV__
Purchases.configure({ apiKey: RC_API_KEY! });
```

## Hook de entitlement

```typescript
import { useEffect, useState } from 'react';
import Purchases, { CustomerInfo } from 'react-native-purchases';

export function usePremium() {
  const [isPremium, setIsPremium] = useState(false);

  useEffect(() => {
    const check = async () => {
      const info = await Purchases.getCustomerInfo();
      setIsPremium(!!info.entitlements.active['premium']);
    };
    check();
    const unsub = Purchases.addCustomerInfoUpdateListener(info => {
      setIsPremium(!!info.entitlements.active['premium']);
    });
    return () => unsub();
  }, []);

  return isPremium;
}
```

## Paywall simples

```typescript
import Purchases, { PurchasesOffering } from 'react-native-purchases';

const offerings = await Purchases.getOfferings();
const current = offerings.current;
if (!current) return;

const pkg = current.monthly ?? current.availablePackages[0];
await Purchases.purchasePackage(pkg);
```

## Restore purchases

```typescript
await Purchases.restorePurchases();
```

## Regras

- ❌ API keys hardcoded — usar `EXPO_PUBLIC_RC_*` em `.env`
- ❌ Lógica de paywall em componentes — extrair para `usePremium` hook
- ❌ `getCustomerInfo()` sem try/catch — pode falhar offline
- ✅ Identificar usuário após login: `Purchases.logIn(userId)`
- ✅ Logout: `Purchases.logOut()` ao deslogar
- ✅ Sempre testar com sandbox antes de produção

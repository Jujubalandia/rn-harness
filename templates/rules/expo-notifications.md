---
description: Regras para expo-notifications — push e local notifications no SDK 56+. Aplicar quando NOTIFICATIONS = expo-notifications.
globs: ["**/*.ts", "**/*.tsx"]
alwaysApply: false
---
# expo-notifications (SDK 56+)

## Setup

```bash
npx expo install expo-notifications expo-device expo-constants
```

```json
// app.json
{
  "expo": {
    "plugins": [
      ["expo-notifications", {
        "icon": "./assets/notification-icon.png",
        "color": "#ffffff",
        "sounds": []
      }]
    ],
    "android": { "googleServicesFile": "./google-services.json" },
    "ios": { "bundleIdentifier": "com.example.app" }
  }
}
```

## Registro de push token

```typescript
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import Constants from 'expo-constants';

export async function registerForPushNotifications(): Promise<string | null> {
  if (!Device.isDevice) return null;

  const { status: existing } = await Notifications.getPermissionsAsync();
  let finalStatus = existing;
  if (existing !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }
  if (finalStatus !== 'granted') return null;

  const projectId = Constants.expoConfig?.extra?.eas?.projectId;
  const token = await Notifications.getExpoPushTokenAsync({ projectId });
  return token.data;
}
```

## Handler de notificações

```typescript
// Configurar antes de renderizar a app
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});
```

## Hook de listeners

```typescript
import { useEffect, useRef } from 'react';
import * as Notifications from 'expo-notifications';

export function useNotifications() {
  const responseListener = useRef<Notifications.Subscription>();

  useEffect(() => {
    responseListener.current = Notifications.addNotificationResponseReceivedListener(
      response => {
        const data = response.notification.request.content.data;
        // navegar com base em data.screen se necessário
      }
    );
    return () => responseListener.current?.remove();
  }, []);
}
```

## Notificação local (agendada)

```typescript
await Notifications.scheduleNotificationAsync({
  content: { title: 'Lembrete', body: 'Seu bracket ainda não foi enviado!' },
  trigger: { seconds: 3600 },
});
```

## Regras

- ❌ Solicitar permissão na inicialização — pedir no momento de valor (após onboarding)
- ❌ Token sem salvar no backend — sempre enviar para Supabase após registro
- ✅ `Device.isDevice` check — simulador não suporta push real
- ✅ `setNotificationHandler` antes de qualquer listener
- ✅ Cancelar listeners em cleanup (`remove()`)
- ✅ EAS projectId para tokens de produção

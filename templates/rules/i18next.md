---
description: i18next + react-i18next + expo-localization — setup, t(), Trans, plurals, Intl formatting
globs: "**/*.{ts,tsx}"
alwaysApply: false
---

# i18next (i18n)

Rule: **NEVER hardcode strings in components.** Always use `t()` or `<Trans>`.

## Setup

```tsx
// lib/i18n.ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import * as Localization from 'expo-localization';
import pt from '@/locales/pt.json';
import en from '@/locales/en.json';
import es from '@/locales/es.json';

i18n.use(initReactI18next).init({
  resources: { pt: { translation: pt }, en: { translation: en }, es: { translation: es } },
  lng: Localization.getLocales()[0]?.languageTag ?? 'pt',
  fallbackLng: 'en',
  interpolation: { escapeValue: false },
});

export default i18n;
```

## Usage

```tsx
import { useTranslation, Trans } from 'react-i18next';

function HomeScreen() {
  const { t, i18n } = useTranslation();

  // Simple key
  <Text>{t('home.welcome')}</Text>

  // With interpolation
  <Text>{t('home.greeting', { name: user.name })}</Text>

  // With JSX (Trans)
  <Trans i18nKey="home.terms">
    Aceito os <Text onPress={openTerms}>termos</Text>
  </Trans>
}
```

## Key Convention

Keys in English snake_case, grouped by screen/feature:

```json
{
  "home": {
    "welcome": "Bem-vindo",
    "greeting": "Olá, {{name}}!",
    "empty_state": "Nenhum bracket ainda"
  },
  "bracket": {
    "pick_winner": "Escolha o vencedor",
    "locked": "Bracket bloqueado"
  }
}
```

## Plurals (CLDR)

```json
// pt.json
{
  "points": "{{count}} ponto",
  "points_other": "{{count}} pontos"
}
```

```tsx
t('points', { count: 1 })  // "1 ponto"
t('points', { count: 5 })  // "5 pontos"
```

## Dates & Numbers (Intl.*)

```tsx
const { i18n } = useTranslation();

// Date — always use Intl, never hardcode format
const formatted = new Intl.DateTimeFormat(i18n.language, {
  day: '2-digit', month: 'short', year: 'numeric',
}).format(new Date(match.date));

// Number / currency
const score = new Intl.NumberFormat(i18n.language).format(123456);
```

## Language Switch

```tsx
const { i18n } = useTranslation();
await i18n.changeLanguage('en');
```

## Common Mistakes

```tsx
// ❌ Hardcoded string
<Text>Bem-vindo</Text>

// ❌ Template literal instead of t()
<Text>{`Olá, ${name}`}</Text>

// ❌ accessibilityLabel without t()
<Pressable accessibilityLabel="Fechar" />  // must be t('common.close')

// ❌ Date formatted without Intl
const d = `${day}/${month}/${year}`; // breaks for en/es locales
```

# 04 — Plano de Testes

> Fase: D13-D15 | Device matrix obrigatória antes da submissão.

---

## Tiers de Teste

| Tier | Ferramenta | Cobertura | Quando |
|------|-----------|-----------|--------|
| Unit | Jest + RNTL | `services/`, `lib/`, `hooks/` apenas | Pre-commit |
| Functional manual | Golden Paths | Fluxos críticos end-to-end | Diário D13+ |
| E2E automatizado | Maestro | 2 fluxos críticos máximo | Pre-production build |
| Smoke iOS | Appetize.io | UI + navegação + i18n | Semanal D11+ |

**Regra:** manual > automatizado no MVP. 1h de teste manual > 6h configurando Detox.

---

## Device Matrix

| Device | Tipo | Plataforma | Uso |
|--------|------|-----------|-----|
| Android físico próprio | Primary | Android | Iteração principal, haptic, share, deeplink |
| AVD Android Studio | Secondary | Android | Visual rápido, multi-user |
| iPhone emprestado | Tertiary | iOS | TestFlight D17+ (1-2h) |
| Appetize.io | Smoke | iOS | UI/nav/i18n semanal (grátis 30min) |

**Plano B iOS se iPhone não disponível:** BrowserStack App Live (30 min grátis) ou MacInCloud (~$1/h).

> **AÇÃO D1:** Agendar empréstimo de iPhone para D17-D18. Registrar contato no TODO.md agora.

---

## Maestro — apenas 2 fluxos

Instalar: `curl -Ls "https://get.maestro.mobile.dev" | bash`

Cobrir apenas:
1. **Fluxo de share** (o mais difícil de testar manualmente em CI)
2. **Deep link / universal link** (segundo mais crítico)

Todo o resto: manual via Golden Paths.

```yaml
# .maestro/flow_share.yaml — exemplo
appId: com.{{APP_BUNDLE_ID}}
---
- launchApp
- tapOn: "{{BOTAO_PRINCIPAL}}"
- tapOn: "Compartilhar"
- assertVisible: "Sheet de compartilhamento"
```

---

## Test Recipe por Feature

Para cada feature implementada, antes do commit final:

1. **Happy path** — fluxo normal funciona
2. **Offline** — sem internet, app não crasha
3. **Edge case** — input vazio, limite de caracteres, etc.
4. **i18n** — mudar idioma no sistema, strings mudam
5. **Acessibilidade** — VoiceOver/TalkBack consegue navegar

Documentar resultado no commit message: `feat(share): card generation + GP-3 ✅`

---

## Definition of Done por Milestone

### M1 (D3) — Auth + Nav
- [ ] Login Google/Apple funciona no Android físico
- [ ] Navegação entre telas sem crash
- [ ] AsyncStorage zero (só expo-secure-store)

### M2 (D7) — Core Flow
- [ ] Usuário completa fluxo principal sem ajuda
- [ ] Estados de loading em todas as chamadas async
- [ ] Error handling em chamadas Supabase

### M3 (D10) — MVP Completo
- [ ] Golden Paths GP-1..GP-5 passam no Android físico
- [ ] Zero crashes no Flipper/Logcat durante 10 min de uso

### M4 (D15) — Store Ready
- [ ] `pnpm quality:full` passa
- [ ] `pnpm preflight` passa
- [ ] Build de produção EAS no Android físico sem crash
- [ ] Smoke no Appetize.io: 3 telas principais ok

### M5 (D17-18) — Launched
- [ ] App aprovado na Play Store
- [ ] App aprovado na App Store
- [ ] Landing page no ar com link para as lojas

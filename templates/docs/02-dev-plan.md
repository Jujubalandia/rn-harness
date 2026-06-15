# 02 — Plano de Desenvolvimento 20 Dias

> Referência contínua. Preencher milestones antes de começar cada fase.

---

## Timeline

### D1-D3: Spec + UX + Setup

**Objetivo:** App rodando no device com navegação e tela home.

**Entregas:**
- [ ] `01-spec.md` preenchido e aprovado
- [ ] Design system definido (4-6 cores, tipografia, espaçamento base 8pt)
- [ ] Fluxo de telas mapeado (pode ser texto, não precisa ser Figma)
- [ ] Projeto Expo criado + Supabase configurado
- [ ] Auth funcionando (Google/Apple/email)
- [ ] Navegação entre telas principais

**Skill desta fase:** `design-token-guardian` (antes de commitar estilos)

**DoD D3:** App abre no Android físico, login funciona, 2+ telas navegáveis.

---

### D4-D10: Core Features

**Objetivo:** Fluxo principal completo e utilizável.

**Regra:** 1 feature por dia. Se travar > 4h numa feature → registrar blocker no TODO.md e seguir.

**Entregas (preencher antes de começar cada dia):**
- [ ] D4: {{FEATURE_CORE_1}}
- [ ] D5: {{FEATURE_CORE_2}}
- [ ] D6: {{FEATURE_CORE_3}}
- [ ] D7: {{FEATURE_CORE_4}}
- [ ] D8: {{FEATURE_CORE_5}}
- [ ] D9: {{FEATURE_CORE_6}}
- [ ] D10: Buffer / catchup + teste end-to-end do fluxo principal

**Skills desta fase:**
- `auth-assessment` ao implementar auth
- `secure-storage-audit` ao armazenar dados sensíveis
- `supabase-migrator` antes de cada nova migration
- `/code-review` antes de todo commit

**DoD D10:** Usuário consegue completar o fluxo principal do zero ao fim sem crash.

---

### D11-D13: Polish + i18n + Acessibilidade

**Objetivo:** App pronto para store review.

**Entregas:**
- [ ] i18n completo (PT-BR obrigatório + {{IDIOMAS_ADICIONAIS}})
- [ ] `accessibilityLabel` em todos elementos interativos
- [ ] Loading states e error states em todas telas
- [ ] Haptic feedback nas interações principais
- [ ] Performance: JS bundle < 3MB, TTI < 2s em device médio
- [ ] Splash screen + ícone do app (1024x1024 PNG)

**DoD D13:** `pnpm quality:full` passa zero erros. `pnpm preflight` passa. Golden Paths GP-1..GP-5 validados no Android físico.

---

### D14-D15: QA + Store Prep

**Objetivo:** Build de produção aprovado internamente.

**Entregas:**
- [ ] `eas build --profile production` completo (Android + iOS)
- [ ] Golden Paths testados na build de produção (não dev)
- [ ] Screenshots capturados para lojas (ver `05-store-launch.md`)
- [ ] Metadata das lojas preenchida (ver `05-store-launch.md`)
- [ ] Privacy policy URL publicada
- [ ] `store-metadata-reviewer` executado em ambas as lojas

**DoD D15:** Build de produção instalada no Android físico e sem crash nos Golden Paths.

---

### D16-D17: Submissão às Lojas

**Objetivo:** Apps submetidos e em review.

**Atenção: ações irreversíveis. Confirmar cada passo.**

- [ ] **Google Play:** Upload AAB → internal track → produção (ver `05-store-launch.md`)
- [ ] **Apple App Store:** Xcode Archive → TestFlight → submissão (ver `05-store-launch.md`)
- [ ] Responder perguntas de compliance de ambas as lojas

**Tempo médio de review:**
- Google Play: 1-3 dias (track produção)
- App Store: 1-3 dias (expedited possível)

**DoD D17:** Ambas as submissões confirmadas, número de build registrado no DECISIONS.md.

---

### D18-D20: Marketing Launch

**Objetivo:** Primeiros 100 usuários reais.

**Entregas (ver `06-marketing.md`):**
- [ ] Landing page publicada (1 página, GitHub Pages ou Vercel grátis)
- [ ] Posts para D-1, D0, D+3, D+7 preparados
- [ ] Reddit post no subreddit certo (não spam — contribuir primeiro)
- [ ] Product Hunt listing criado (launch D20 ou D21)
- [ ] Métricas de D+7 registradas no DECISIONS.md

**Skills desta fase:** `marketing-copywriter`, `viral-content-strategist`

**DoD D20:** App aprovado nas lojas, landing page no ar, pelo menos 1 canal de marketing ativo.

---

## Milestones e DoD

| Milestone | Dia | DoD |
|-----------|-----|-----|
| M1: Auth + Nav | D3 | Login funciona, 2+ telas |
| M2: Core flow | D7 | Fluxo principal completo |
| M3: MVP completo | D10 | End-to-end sem crash |
| M4: Store ready | D15 | quality:full + preflight pass |
| M5: Launched | D17-18 | Ambas as lojas aprovadas |

**Regra:** DoD ❌ em Android físico → não avança para próximo milestone.

---

## Bloqueadores comuns e como resolver

| Bloqueador | Solução |
|-----------|---------|
| EAS build falha | Subagente `expo-debugger` |
| Metro trava | `npx expo start --clear` |
| TypeScript erro difícil | `/code-review` no arquivo |
| Supabase RLS bloqueando | `supabase-migrator` para revisar policy |
| App Store rejeição | Ler feedback + `store-metadata-reviewer` |
| Feature tomando > 1 dia | Cortar ao MVP, registrar em TODO.md como v1.1 |

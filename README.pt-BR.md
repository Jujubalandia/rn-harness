# rn-harness

**🇧🇷 Português** | [🇺🇸 English](README.md)

Framework de desenvolvimento para lançar apps React Native na App Store + Play Store em ≤20 dias.

Desenvolvido sobre Claude Code com skills especializados, quality gates e um wizard de inicialização de projetos.

---

## O que é

Um conjunto de templates, skills e hooks que padronizam o fluxo completo:

```
Spec → UX → Dev → QA → Store → Marketing
```

O coração é a skill `/new-rn-project`: você abre um diretório (novo ou existente), digita o comando, e o Claude detecta automaticamente a stack via `package.json`, configura o projeto e cria toda a estrutura — CLAUDE.md preenchido, docs/, git hooks do perfil selecionado e knowledge rules seletivas.

---

## Pré-requisitos

| Ferramenta | Versão mínima | Instalação |
|-----------|---------------|-----------|
| Node.js | 20 LTS | `nvm install 20` |
| pnpm | qualquer | `npm i -g pnpm` |
| Claude Code | latest | `npm i -g @anthropic-ai/claude-code` |
| Git | qualquer | sistema |

---

## Instalação

```bash
curl -fsSL https://raw.githubusercontent.com/Jujubalandia/rn-harness/main/install.sh | sh
```

Ou manual (repo privado — requer acesso SSH):

```bash
git clone git@github.com:Jujubalandia/rn-harness.git ~/.rn-harness
~/.rn-harness/install.sh
```

O installer coloca:
- Templates em `~/.claude/templates/rn-20days/`
- Skills `new-rn-project` e `rn-doctor` em `~/.claude/skills/`
- Scripts (doctor, etc.) em `~/.rn-harness/scripts/`

---

## Uso — Novo Projeto

```bash
mkdir ~/projects/meu-app && cd ~/projects/meu-app
claude    # abre Claude Code
```

No Claude Code:

```
/new-rn-project
```

### O que o wizard faz

**1. Auto-detecta a stack via `package.json`** (se existir) em 13 dimensões:

| Dimensão | O que detecta |
|----------|--------------|
| State management | Zustand · Redux Toolkit · Jotai |
| Navigation | Expo Router · React Navigation |
| Styling | NativeWind · Tamagui · StyleSheet.create |
| Backend | Supabase · Firebase · Convex |
| i18n | i18next + expo-localization |
| Animation | Reanimated v3 |
| Gesture | Gesture Handler v2 |
| Storage | expo-secure-store (OK) · AsyncStorage (AVISO) |
| Image gen | Skia · react-native-view-shot |
| Testing | RNTL · Detox |
| Video | expo-video (OK) · expo-av (AVISO: deprecated) |
| Monetization | RevenueCat · react-native-iap |
| Notifications | expo-notifications |

Mostra tabela de detecção e pede confirmação antes de prosseguir.

**2. Pergunta só o que não pode detectar:** nome, descrição, idiomas, monetização, perfil de hooks.

**3. Cria a estrutura:**
- `CLAUDE.md` preenchido (sem placeholders)
- `DECISIONS.md` + `TODO.md` inicializados
- `docs/` com os 6 templates de fase
- `.githooks/pre-commit` e `pre-push` do perfil selecionado
- `.claude/rules/` com knowledge rules **seletivas** (só as relevantes para a stack detectada)

**4. Gera checklist de próximos passos** adaptado à stack — só sugere instalar dependências que ainda não estão no `package.json`, e executa `npx expo install --fix` para corrigir versões incompatíveis com o SDK 56.

---

## Doctor — Health Check

24 verificações de saúde do projeto. Roda em qualquer projeto existente.

```bash
bash ~/.rn-harness/scripts/doctor.sh           # output legível
bash ~/.rn-harness/scripts/doctor.sh --json    # output JSON (CI/scripts)
```

PowerShell:
```powershell
& "$env:USERPROFILE\.rn-harness\scripts\doctor.ps1"
& "$env:USERPROFILE\.rn-harness\scripts\doctor.ps1" -Json
```

Ou via skill Claude Code (explica FAILs e executa fixes):
```
/rn-doctor
```

### O que verifica

| Categoria | Checks |
|-----------|--------|
| Ambiente | node >= 20, pnpm, git, eas-cli |
| Estrutura | package.json, CLAUDE.md, .gitignore cobre .env*, .claude/rules/ |
| Segurança | .env* não commitado, sem chaves hardcoded em .ts/.tsx |
| Versões SDK | Expo 56, RN 0.76.x, Reanimated v3 (não v4) |
| Config | tsconfig strict, babel plugin reanimated, ESLint no-color-literals, scripts pnpm |
| Segurança deps | expo-secure-store presente, AsyncStorage ausente de deps diretas |
| Git/Hooks | .git/ inicializado, core.hooksPath = .githooks |
| Store | app.json bundleIdentifier + packageName, eas.json |
| Padrões proibidos | `lineHeight` em StyleSheet (bug Android), `expo-av` importado (deprecated) |

### Saída

```
  [OK]   node v22.x >= 20
  [WARN] CLAUDE.md ausente (rn-harness não inicializado)
  [FAIL] tsconfig.json sem "strict": true
         fix: Adicionar '"strict": true' em compilerOptions
  ...
  OK: 20  WARN: 2  FAIL: 2  / 24 total
```

Exit 0 = nenhum FAIL (OK e WARN passam). Exit 1 = pelo menos um FAIL.

### Quando rodar

- D1: logo após `/new-rn-project`
- Depois de clonar em nova máquina
- Quando pre-commit hook falha sem motivo claro
- Antes de `eas build --profile production`

---

## Segurança Claude Code

Dois mecanismos complementares bloqueiam operações destrutivas antes de execução:

### `settings.json` — allowlist/denylist declarativa

Criado em `.claude/settings.json` pelo `/new-rn-project`. Bloqueia sem prompt:

```json
{ "permissions": { "deny": [
  "Bash(eas submit*)",
  "Bash(supabase db reset*)",
  "Bash(git push --force*)",
  "Bash(git commit *--no-verify*)",
  "Bash(rm -rf /*)"
]}}
```

### `.claude/hooks/pre-tool-use.sh` — bloqueio em runtime

Script executado pelo Claude Code antes de cada ferramenta. Intercepta padrões destrutivos não cobertos pelo `settings.json` (ex: variantes de comando, SQL):

```
🚫 BLOQUEADO: 'supabase db reset' requer confirmação explícita.
   Execute manualmente no terminal se tiver certeza.
```

Padrões bloqueados: `eas submit`, `supabase db reset`, `git push --force`, `git commit --no-verify`, `rm -rf /`, `git reset --hard`, `DROP TABLE`, `truncate cascade`, `npx expo publish`.

Ambos os arquivos são copiados pelo `/new-rn-project` de `~/.claude/templates/rn-20days/claude/`.

---

## Hook Profiles

Três níveis de quality gates, selecionáveis na instalação:

| Profile | pre-commit | pre-push |
|---------|-----------|---------|
| `minimal` | typecheck | confirmação Android |
| `standard` | typecheck + lint + format | quality:full + confirmação Android |
| `strict` *(padrão)* | typecheck + lint + format + fta | quality:full + confirmação Android |

**Instalar com profile específico:**

```bash
~/.rn-harness/install.sh --profile minimal    # D1-D5: iteração rápida
~/.rn-harness/install.sh --profile standard   # sem fta
~/.rn-harness/install.sh --profile strict     # tudo (padrão, recomendado)
```

```powershell
& "$env:USERPROFILE\.rn-harness\install.ps1" -Profile minimal
& "$env:USERPROFILE\.rn-harness\install.ps1" -Profile standard
& "$env:USERPROFILE\.rn-harness\install.ps1" -Profile strict
```

O profile fica salvo em `~/.rn-harness/.profile`. O wizard `/new-rn-project` lê esse arquivo e copia os hooks correspondentes de `hooks/profiles/<profile>/` para o novo projeto.

**Mudar de profile em projeto existente:**

```bash
~/.rn-harness/install.sh --profile strict     # atualiza .profile
# depois, no projeto:
cp ~/.rn-harness/hooks/profiles/strict/pre-commit.sh .githooks/pre-commit
cp ~/.rn-harness/hooks/profiles/strict/pre-push.sh   .githooks/pre-push
```

---

## Knowledge Rules

15 arquivos `.md` que o Claude carrega automaticamente com base nos arquivos em edição (`globs`). Instalados em `.claude/rules/` de cada novo projeto pelo `/new-rn-project`.

**As rules são seletivas:** o wizard copia apenas as relevantes para a stack detectada. Projeto sem Supabase não recebe `supabase.md`. Projeto sem expo-video não recebe `expo-video.md`.

| Rule | Copiada quando | Cobre |
|------|---------------|-------|
| `patterns.md` | sempre | folder structure, custom hooks, barrel exports, error boundaries |
| `performance.md` | sempre | FlatList, memoization, bundle size, expo-image |
| `security.md` | sempre | expo-secure-store, env vars, deep link validation |
| `accessibility.md` | sempre | 44pt targets, t() em accessibilityLabel, screen reader |
| `forbidden.md` | sempre | lineHeight (bug Android), expo-av deprecated, AsyncStorage para secrets |
| `expo-router.md` | Navigation = Expo Router | file-based routing, NativeTabs, SF Symbols/MD icons, deep links |
| `supabase.md` | Backend = Supabase | auth + SecureStore, RLS, Edge Functions, realtime |
| `i18next.md` | i18n = i18next | t(), Trans, CLDR plurals, Intl.* dates/numbers |
| `zustand.md` | State = Zustand | stores por domínio, selector pattern, persist + SecureStore |
| `react-native-reanimated.md` | Animation = Reanimated v3 | v3: shared values, worklets, runOnJS, layout animations |
| `react-native-gesture-handler.md` | Gesture = GH v2 | v2 Builder API: Gesture.Pan/Tap, useMemo obrigatório |
| `styling.md` | Styling = StyleSheet.create | StyleSheet.create, design tokens, dark mode |
| `expo-video.md` | Video = expo-video | VideoView, useVideoPlayer, cleanup, expo-audio |
| `revenue-cat.md` | Monetization = RevenueCat | usePremium hook, paywall, restore, sandbox testing |
| `expo-notifications.md` | Notifications = expo-notifications | push token, handler, listeners, local scheduling |

**Versões alvo:** Expo SDK 56 · RN 0.76 · Reanimated v3 · GH v2 · React 18

> Diferença do ERNE: rules aqui são **específicos para a stack do harness** (Supabase, i18next, Expo SDK 56), não genéricos para qualquer projeto RN.

---

## Windows (PowerShell)

Requer PowerShell 5.1+ (pré-instalado no Windows 10+) e Git for Windows.

### Instalação

```powershell
# Clone manual (repo privado — requer acesso SSH):
git clone git@github.com:Jujubalandia/rn-harness.git $env:USERPROFILE\.rn-harness
& "$env:USERPROFILE\.rn-harness\install.ps1"
```

### Atualizar

```powershell
& "$env:USERPROFILE\.rn-harness\install.ps1"          # sem sobrescrever
& "$env:USERPROFILE\.rn-harness\install.ps1" -Force   # forca update dos templates
```

### Desinstalar

```powershell
& "$env:USERPROFILE\.rn-harness\uninstall.ps1"
```

### Git hooks no Windows

Os hooks `.sh` funcionam via Git for Windows (bash embutido) — nenhuma configuração extra.
Os `.ps1` em `hooks/` servem para testes e invocação manual no PowerShell.

### Testar suite PowerShell

```powershell
powershell -File "$env:USERPROFILE\.rn-harness\tests\test.ps1"
```

### Variaveis de ambiente (equivalentes)

| Bash | PowerShell |
|------|-----------|
| `RN_HARNESS_DIR` | `$env:RN_HARNESS_DIR` |
| `CLAUDE_CONFIG_DIR` | `$env:CLAUDE_CONFIG_DIR` |
| `HARNESS_REMOTE` | `$env:HARNESS_REMOTE` |
| `HARNESS_CONFIRM` | `$env:HARNESS_CONFIRM` (uninstall sem prompt) |
| `HARNESS_ANDROID_OK` | `$env:HARNESS_ANDROID_OK` (pre-push sem prompt) |

---

## Atualizar

```bash
# Atualiza o repo e os templates locais (sem sobrescrever arquivos de projeto)
~/.rn-harness/install.sh

# Força atualização dos templates instalados
~/.rn-harness/install.sh --force
```

---

## Estrutura do repo

```
rn-harness/
├── install.sh               ← instalador principal (bash)
├── install.ps1              ← instalador PowerShell
├── uninstall.sh / .ps1      ← limpeza completa
├── scripts/
│   ├── doctor.sh            ← 24 health checks (bash)
│   └── doctor.ps1           ← 24 health checks (PowerShell)
├── templates/
│   ├── CLAUDE.md.tmpl       ← template do projeto (com {{PLACEHOLDERS}})
│   ├── DECISIONS.md.stub    ← ADR log inicial
│   ├── TODO.md.stub         ← backlog inicial
│   ├── docs/
│   │   ├── 01-spec.md       ← spec + pesquisa de mercado (D1-D2)
│   │   ├── 02-dev-plan.md   ← plano 20 dias + milestones
│   │   ├── 03-quality-gates.md  ← pirâmide de qualidade
│   │   ├── 04-testing.md    ← tiers de teste + device matrix
│   │   ├── 05-store-launch.md   ← checklist App Store + Play Store
│   │   └── 06-marketing.md  ← calendário D-7→D+14
│   ├── rules/               ← 15 knowledge rules (copiadas seletivamente)
│   └── claude/
│       ├── settings.json        ← denylist de ops destrutivas
│       └── hooks/
│           └── pre-tool-use.sh  ← bloqueio runtime por padrão
├── skills/
│   ├── new-rn-project/      ← wizard: init, stack detection, rules, hooks
│   └── rn-doctor/           ← health check: 24 checks + fixes
├── hooks/
│   ├── pre-commit.sh / .ps1 ← strict (referência)
│   ├── pre-push.sh / .ps1   ← strict (referência)
│   └── profiles/
│       ├── minimal/         ← pre-commit: typecheck only
│       ├── standard/        ← pre-commit: typecheck+lint+format
│       └── strict/          ← pre-commit: +fta (padrão)
└── tests/
    ├── test.sh              ← 164 checks (bash)
    └── test.ps1             ← equivalente PowerShell
```

---

## Templates — O que cada doc faz

| Doc | Fase | Propósito |
|-----|------|-----------|
| `01-spec.md` | D1-D2 | Problema, mercado, concorrentes, Cut/Keep, viral loop |
| `02-dev-plan.md` | D1-D20 | Fases, milestones, DoD, bloqueadores comuns |
| `03-quality-gates.md` | contínuo | Pirâmide tsc→ESLint→Prettier→FTA→Golden Paths |
| `04-testing.md` | D13-D15 | Tiers de teste, device matrix, Maestro setup |
| `05-store-launch.md` | D15-D17 | Assets, metadata, checklist de submissão |
| `06-marketing.md` | D17-D20 | Calendário, templates por plataforma, landing page |

---

## Timeline de 20 Dias

| Fase | Dias | Foco | Doc principal |
|------|------|------|---------------|
| Spec + Setup | D1-D3 | Especificação + ambiente rodando | 01-spec |
| Core Dev | D4-D10 | Features do MVP (1/dia) | 02-dev-plan |
| Polish | D11-D13 | i18n, a11y, loading states | 03-quality-gates |
| QA + Store Prep | D14-D15 | Build produção + assets | 04-testing + 05-store-launch |
| Submissão | D16-D17 | Upload AAB/IPA + review | 05-store-launch |
| Marketing | D18-D20 | Launch posts + landing page | 06-marketing |

---

## Skills — Quando usar qual

| Fase | Trigger | Skill | Como invocar |
|------|---------|-------|--------------|
| D1 | Após `/new-rn-project` ou clone em nova máquina | `rn-doctor` | `/rn-doctor` |
| D1-D2 | Pesquisa de concorrentes | `firecrawl-search` | `/firecrawl-search` |
| D1-D2 | Scrape de página concorrente | `firecrawl-scrape` | `/firecrawl-scrape` |
| D3+ | Nova tela com cores hardcoded | `design-token-guardian` | subagente |
| D3+ | Texto de UI sem `t()` | `i18n-validator` | subagente |
| D4+ | EAS build / Metro travado | `expo-debugger` | subagente |
| D4+ | Fluxo de auth | `auth-assessment` | `/auth-assessment` |
| D4+ | Dados sensíveis em storage | `secure-storage-audit` | `/secure-storage-audit` |
| D4+ | Nova migration Supabase | `supabase-migrator` | subagente |
| Pre-commit | Qualquer diff | `code-review` | `/code-review` |
| D13-D15 | Feature completa para QA | `qa-tester` | subagente |
| D15 | Metadata App Store/Play | `store-metadata-reviewer` | subagente |
| D15 | Antes de build produção | `rn-doctor` | `/rn-doctor` |
| D17 | Copy de post por plataforma | `marketing-copywriter` | subagente |
| D18 | Conceito viral | `viral-content-strategist` | subagente |
| Pós-D20 | Auditoria de privacidade | `privacy-audit` | `/privacy-audit` |

### Skills bundled (instaladas pelo rn-harness)

| Skill | O que faz |
|-------|-----------|
| `new-rn-project` | Wizard de init: detecta stack, cria estrutura, configura hooks e rules |
| `rn-doctor` | 24 health checks + explica FAILs + executa fixes |

### Skills de marketplace (instalar separadamente)

| Skill | Provider | Quando |
|-------|----------|--------|
| `firecrawl-search` / `firecrawl-scrape` | firecrawl MCP | D1-D2 |
| `design-token-guardian` | plugin | D3+ |
| `i18n-validator` | plugin | D3+ |
| `expo-debugger` | callstack | D4+ |
| `auth-assessment` | plugin | D4+ |
| `secure-storage-audit` | plugin | D4+ |
| `supabase-migrator` | plugin | D4+ |
| `code-review` | plugin | pre-commit |
| `qa-tester` | plugin | D13-D15 |
| `store-metadata-reviewer` | plugin | D15 |
| `marketing-copywriter` | plugin | D17 |
| `viral-content-strategist` | plugin | D18 |
| `privacy-audit` | plugin | pós-D20 |

---

## Quality Gates

O pré-commit bloqueia conforme o **perfil ativo** (ver Hook Profiles):

| Profile | Bloqueia se falhar |
|---------|-------------------|
| `minimal` | tsc --noEmit |
| `standard` | tsc + eslint + prettier |
| `strict` *(padrão)* | tsc + eslint + prettier + fta score ≥ 60 |

Antes de push (todos os perfis): `pnpm quality:full` (typecheck + lint + format + fta + tests).

Antes de build produção: `pnpm preflight` + Golden Paths manuais + `/rn-doctor` sem FAILs.

**FTA ≥ 60?** Refatorar: extrair sub-componentes, custom hooks, lookup tables. **Nunca** aumentar o score_cap.

---

## Device Matrix

| Device | Plataforma | Uso |
|--------|-----------|-----|
| Android físico próprio | Android | Iteração principal (haptic, share, deeplink reais) |
| AVD Android Studio | Android | Visual rápido + multi-user |
| Appetize.io (free 30min) | iOS | Smoke semanal (UI, navegação, i18n) |
| iPhone emprestado | iOS | TestFlight D17+ (1-2h) |

**Plano B iOS:** BrowserStack App Live (30 min grátis) ou MacInCloud (~$1/h).

> **Ação D1:** Agendar empréstimo de iPhone para D17-D18. Registrar no TODO.md.

---

## FAQ

**Como iniciar um projeto sem sobrescrever arquivos existentes?**
`/new-rn-project` checa cada arquivo antes de criar. Existentes são pulados com aviso.

**Como forçar sobrescrita de um arquivo?**
Deletar manualmente e rodar `/new-rn-project` novamente, ou editar diretamente.

**As knowledge rules são sempre todas copiadas?**
Não — são seletivas. O wizard copia só as relevantes para a stack detectada. Projeto sem Supabase não recebe `supabase.md`, sem expo-video não recebe `expo-video.md`. Se quiser todas: `/new-rn-project` em projeto sem `package.json` copia as 15.

**Como mudar o hook profile depois de instalar?**
```bash
~/.rn-harness/install.sh --profile minimal     # atualiza ~/.rn-harness/.profile
# Copiar hooks no projeto existente:
cp ~/.rn-harness/hooks/profiles/minimal/pre-commit.sh .githooks/pre-commit
cp ~/.rn-harness/hooks/profiles/minimal/pre-push.sh   .githooks/pre-push
```

**Posso usar sem Supabase?**
Sim — na detecção de stack o wizard não vai copiar `supabase.md` nem sugerir `@supabase/supabase-js`. Basta confirmar o backend como "(nenhum)" ou Firebase.

**Não tenho Mac para iOS.**
Fluxo documentado em `04-testing.md`: Appetize.io para smoke + iPhone emprestado para TestFlight. O wizard inclui essa instrução no TODO.md.

**Como atualizar o harness sem quebrar projetos existentes?**
`install.sh` usa `cp -rn` (no-clobber). Projetos existentes não são afetados.

**O `/rn-doctor` modifica arquivos?**
Não — só lê e reporta. Fixes são sugeridos e executados apenas quando invocado via `/rn-doctor` no Claude Code, com confirmação do usuário.

---

## Contribuindo

Repo privado. Para melhorias:
1. Editar arquivos em `~/.rn-harness/` (clone local)
2. Rodar suite de testes: `bash tests/test.sh` (deve terminar 0 failures)
3. Testar skill manualmente: `/new-rn-project` ou `/rn-doctor` em projeto de teste
4. Commitar e fazer push

Mudanças em templates e rules entram em vigor nos **próximos** projetos criados. Projetos existentes não são afetados.

---

## Desinstalar

```bash
~/.rn-harness/uninstall.sh
```

Remove templates, skills (`new-rn-project` + `rn-doctor`) e o repo clonado. Projetos existentes não são afetados.

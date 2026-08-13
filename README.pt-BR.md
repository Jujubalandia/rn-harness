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

Escolha a subseção do seu SO. Ambas instalam a mesma estrutura — só mudam o shell e os caminhos.

### Linux / macOS / WSL (Bash)

```bash
curl -fsSL https://raw.githubusercontent.com/Jujubalandia/rn-harness/main/install.sh | sh
```

Ou clone manual (necessário se o repo for privado e a URL raw acima der 404 — requer acesso SSH):

```bash
git clone git@github.com:Jujubalandia/rn-harness.git ~/.rn-harness
~/.rn-harness/install.sh
```

### Windows (PowerShell)

Requer PowerShell 5.1+ (pré-instalado no Windows 10+) e Git for Windows. Não existe one-liner curl para Windows — clone manualmente e rode o installer:

```powershell
git clone git@github.com:Jujubalandia/rn-harness.git $env:USERPROFILE\.rn-harness
& "$env:USERPROFILE\.rn-harness\install.ps1"
```

Os hooks `.sh` instalados depois funcionam direto via bash embutido do Git for Windows — nenhuma configuração extra. Os arquivos `.ps1` em `hooks/` servem só para teste manual no PowerShell.

### O que o installer coloca

| | Linux / macOS / WSL | Windows |
|---|---|---|
| Templates | `~/.claude/templates/rn-20days/` | `$env:USERPROFILE\.claude\templates\rn-20days\` |
| Skills (`new-rn-project`, `rn-doctor`) | `~/.claude/skills/` | `$env:USERPROFILE\.claude\skills\` |
| Scripts (doctor, etc.) | `~/.rn-harness/scripts/` | `$env:USERPROFILE\.rn-harness\scripts\` |

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
| Storage | só expo-secure-store (OK) · ambos presentes (AVISO) · só AsyncStorage (FAIL) |
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

## Notas Windows

Detalhes extras específicos de PowerShell não cobertos nas seções Instalação/Atualizar/Desinstalar acima.

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

### Linux / macOS / WSL (Bash)

```bash
~/.rn-harness/install.sh            # atualiza repo + templates, sem sobrescrever arquivos de projeto
~/.rn-harness/install.sh --force    # força atualização dos templates instalados
```

### Windows (PowerShell)

```powershell
& "$env:USERPROFILE\.rn-harness\install.ps1"          # atualiza repo + templates, sem sobrescrever
& "$env:USERPROFILE\.rn-harness\install.ps1" -Force   # força atualização dos templates instalados
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

## D1→D20 Passo a Passo

Tabela operacional: cada comando/passo do fluxo, o dia a que pertence, sua classificação, artefatos de entrada/saída e o próximo passo.

**Classificação:**
- **Interno Claude** — ação de ferramenta nativa do Claude Code executada automaticamente na sessão (Read/Edit/Write), não é comando digitado pelo usuário.
- **Externo** — comando de terminal/shell ou ferramenta terceira fora do Claude Code (npm, pnpm, eas, git, curl, consoles de loja).
- **Skill** — `/comando` ou subagente invocado dentro do Claude Code (bundled ou marketplace).
- **Edição** — edição manual de conteúdo pelo usuário num arquivo/doc, sem execução de comando.

| Dia | Comando | Classificação | Artefato(s) manipulado(s)/criado(s) | Artefato(s) resultante(s)/modificado(s) | Próximo passo |
|-----|---------|---------------|--------------------------------------|-------------------------------------------|---------------|
| D1 | `nvm install 20` | Externo | Node.js (máquina) | Node 20 LTS ativo | instalar pnpm |
| D1 | `npm i -g pnpm` | Externo | — | pnpm CLI disponível | instalar Claude Code |
| D1 | `npm i -g @anthropic-ai/claude-code` | Externo | — | Claude Code CLI instalado | rodar installer rn-harness |
| D1 | `curl -fsSL .../install.sh \| sh` | Externo | repo rn-harness remoto | `~/.claude/templates/rn-20days/`, `~/.claude/skills/{new-rn-project,rn-doctor}`, `~/.rn-harness/scripts/`, `~/.rn-harness/.profile` | criar pasta do projeto |
| D1 | `mkdir ~/projects/my-app && cd ...` | Externo | filesystem | diretório do projeto | abrir Claude Code |
| D1 | `claude` | Externo | — | sessão Claude Code aberta | rodar wizard |
| D1 | `/new-rn-project` | Skill | `package.json` (se existir) | `CLAUDE.md`, `DECISIONS.md`, `TODO.md`, `docs/01-spec.md`…`06-marketing.md`, `.githooks/`, `.claude/rules/`, `.claude/settings.json`, `.claude/hooks/pre-tool-use.sh` | rodar `/rn-doctor` |
| D1 | `/rn-doctor` | Skill | CLAUDE.md, package.json, tsconfig.json, .env*, .git/, app.json, eas.json | relatório 24 checks (OK/WARN/FAIL) | corrigir FAILs apontados |
| D1 | Preencher checklist de prep (problema, público, concorrentes, diferencial, cut/keep, monetização, viral loop, riscos) | Edição | `docs/01-spec.md` (vazio) | `docs/01-spec.md` com rascunho | pesquisar concorrentes (D2) |
| D1 | `npx expo install --fix` | Externo | package.json / node_modules | versões compatíveis c/ SDK 56 | corrigir FAILs restantes |
| D2 | `/firecrawl-search` | Skill (marketplace) | query de busca | lista de concorrentes | escolher top 3 |
| D2 | `/firecrawl-scrape` | Skill (marketplace) | URL do concorrente | conteúdo extraído | preencher tabela de concorrentes |
| D2 | Preencher concorrentes + Cut/Keep + diff + viral loop | Edição | `docs/01-spec.md` | `docs/01-spec.md` completo (pronto para aprovar antes de D3 — não é DoD/Milestone formal) | aprovar spec, seguir p/ D3 |
| D3 | Definir design system (cores, tipografia, grid 8pt) | Edição | `docs/01-spec.md` | seção design system preenchida | mapear fluxo de telas |
| D3 | Mapear fluxo de telas (texto) | Edição | `docs/01-spec.md` | fluxo documentado | criar projeto Expo + Supabase |
| D3 | `npx create-expo-app` + config Supabase | Externo | filesystem / dashboard Supabase | projeto Expo + client Supabase configurados | implementar auth |
| D3 | Implementar auth (Google/Apple/email) | Interno Claude | arquivos de auth/hooks | login funcional | implementar navegação |
| D3 | `design-token-guardian` (antes de commitar estilos) | Skill (subagente) | arquivos de estilo/tela nova | flag de cores hardcoded | corrigir, commit |
| D3 | Implementar navegação entre telas | Interno Claude | arquivos de rota | 2+ telas navegáveis | validar DoD D3 |
| D3 | Testar no Android físico (login + nav) | Externo (manual) | build dev no device | **DoD D3 / Milestone M1 confirmado:** app abre no Android físico, login funciona, 2+ telas navegáveis | iniciar D4 |
| D4 | Implementar feature core 1 | Interno Claude | código da feature | feature 1 funcional | `/code-review` |
| D4 | `/code-review` | Skill (marketplace) | diff feature 1 | relatório de findings | corrigir, commit |
| D5 | Implementar feature core 2 | Interno Claude | código da feature | feature 2 funcional | `/code-review` |
| D5 | `/code-review` | Skill | diff feature 2 | findings | corrigir, commit |
| D6 | Implementar feature core 3 | Interno Claude | código da feature | feature 3 funcional | `/code-review` |
| D6 | `/code-review` | Skill | diff feature 3 | findings | corrigir, commit |
| D7 | Implementar feature core 4 | Interno Claude | código da feature | feature 4 funcional | `/code-review` |
| D7 | `/code-review` | Skill | diff feature 4 | findings | corrigir, commit |
| D7 | Confirmar Milestone M2 (fluxo principal funcionalmente completo) | Externo (manual) | features core 1-4 funcionando | **Milestone M2 confirmado** | iniciar D8 |
| D8 | Implementar feature core 5 | Interno Claude | código da feature | feature 5 funcional | `/code-review` |
| D8 | `/code-review` | Skill | diff feature 5 | findings | corrigir, commit |
| D9 | Implementar feature core 6 | Interno Claude | código da feature | feature 6 funcional | `/code-review` |
| D9 | `/code-review` | Skill | diff feature 6 | findings | corrigir, commit |
| D4-D9 | `/auth-assessment` (ao implementar/alterar auth) | Skill (marketplace) | fluxo de auth | relatório de gaps | corrigir achados |
| D4-D9 | `/secure-storage-audit` (ao guardar dado sensível) | Skill (marketplace) | código de storage | relatório de conformidade | migrar p/ SecureStore se preciso |
| D4-D9 | `supabase-migrator` (nova migration) | Skill (subagente) | arquivo de migration SQL | migration revisada | aplicar no Supabase |
| D4-D9 | `expo-debugger` (EAS build/Metro travado) | Skill (subagente) | logs de build/Metro | causa raiz + fix sugerido | aplicar fix, re-rodar |
| D10 | Buffer/catchup de features atrasadas | Interno Claude / Edição | código pendente | features completas | testar fluxo e2e |
| D10 | Testar fluxo principal ponta a ponta (Android físico) | Externo (manual) | build dev | **DoD D10 / Milestone M3 confirmado:** usuário completa o fluxo principal do zero ao fim sem crash | iniciar D11 |
| D11 | Completar i18n (PT-BR + idiomas extra) | Interno Claude | strings/telas | textos com `t()` | `i18n-validator` |
| D11 | `i18n-validator` (texto sem `t()`) | Skill (subagente) | arquivos de tela | relatório de strings hardcoded | corrigir restantes |
| D12 | Adicionar `accessibilityLabel` nos elementos interativos | Interno Claude | componentes de UI | a11y labels presentes | loading/error states |
| D12 | Implementar loading + error states em todas telas | Interno Claude | telas | UX de loading/erro | haptic feedback |
| D13 | Haptic feedback nas interações principais | Interno Claude | componentes interativos | haptics aplicados | ajustar performance |
| D13 | Ajustar performance (bundle <3MB, TTI <2s) + splash/ícone | Interno Claude / Edição (assets) | bundle config, assets/icon.png | app otimizado + ícone/splash prontos | rodar quality gates |
| D13 | `pnpm quality:full` | Externo | código do projeto | relatório zero erros (ou falhas) | corrigir falhas, preflight |
| D13 | `pnpm preflight` | Externo | build de produção local | preflight OK | validar Golden Paths |
| D13 | Validar Golden Paths GP-1..GP-5 (Android físico) | Externo (manual) | app no device | **DoD D13 confirmado:** `quality:full` zero erros, `preflight` passa, Golden Paths GP-1..GP-5 validados no Android físico | iniciar D14 |
| D14 | `eas build --profile production` (Android + iOS) | Externo | eas.json / código | AAB/IPA de produção | testar Golden Paths na build prod |
| D14 | Testar Golden Paths na build de produção | Externo (manual) | AAB/IPA instalado | validação sem crash | capturar screenshots |
| D14 | Capturar screenshots para as lojas | Externo (manual) | app rodando | imagens p/ `05-store-launch.md` | preencher metadata |
| D15 | Preencher metadata das lojas | Edição | `docs/05-store-launch.md` | metadata completa | publicar privacy policy |
| D15 | Publicar Privacy Policy (URL) | Externo | página de privacy policy | URL pública | rodar store-metadata-reviewer |
| D15 | `store-metadata-reviewer` | Skill (subagente) | metadata + screenshots | relatório de conformidade | corrigir apontamentos |
| D15 | `/rn-doctor` (antes do build final) | Skill | projeto (24 checks) | relatório sem FAILs | validar DoD D15 |
| D15 | Confirmar DoD D15 / Milestone M4 | Externo (manual) | build produção instalada | **DoD D15 / Milestone M4 confirmado:** build de produção instalada no Android físico, sem crash nos Golden Paths | iniciar D16 |
| D16 | Upload AAB → internal track (Google Play Console) | Externo (irreversível) | AAB de produção | release no internal track | promover p/ produção |
| D16 | Promover release p/ produção (Google Play) | Externo (irreversível) | release internal track | app em review na Play Store | responder compliance |
| D17 | Xcode Archive → upload TestFlight | Externo (irreversível) | build iOS | build no TestFlight | submeter p/ review |
| D17 | Submissão App Store (App Store Connect) | Externo (irreversível) | build TestFlight | app em review na App Store | responder compliance |
| D17 | Responder compliance (ambas lojas) | Edição/Externo | formulários das lojas | compliance respondido | registrar build number |
| D17 | Registrar build number/status em DECISIONS.md | Edição | `DECISIONS.md` | registro salvo — **DoD D17 / Milestone M5 confirmado:** ambas submissões confirmadas, build number registrado | iniciar D18 |
| D18 | Publicar landing page (GitHub Pages/Vercel) | Externo | 1 página estática | landing page no ar | preparar posts |
| D18 | `marketing-copywriter` | Skill (subagente) | briefing do app | copy por plataforma | revisar/agendar posts |
| D18 | `viral-content-strategist` | Skill (subagente) | contexto do app/público | conceito de conteúdo viral | criar posts D-1/D0 |
| D19 | Publicar posts D-1/D0 (Reddit, redes) | Externo (manual) | copy pronta | posts publicados | monitorar reação |
| D20 | Criar listing Product Hunt | Externo (manual) | assets + copy | listing publicado | acompanhar métricas |
| D20 | Publicar posts D+3/D+7 (agendados) | Externo (manual) | copy pronta | posts publicados | registrar métricas |
| D20 | Registrar métricas D+7 em DECISIONS.md | Edição | `DECISIONS.md` | métricas registradas — **DoD D20 confirmado:** app aprovado nas lojas, landing page no ar, ≥1 canal de marketing ativo | encerrar milestone / v1.1 |

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

Antes de build produção: `pnpm preflight` + Golden Paths manuais (5 fluxos críticos, definidos em `docs/03-quality-gates.md`) + `/rn-doctor` sem FAILs.

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

**O que é a tabela D1→D20 Passo a Passo?**
É a referência operacional na seção [D1→D20 Passo a Passo](#d1d20-passo-a-passo): uma linha por comando/passo do fluxo completo de 20 dias, com dia, classificação (Interno Claude / Externo / Skill / Edição), artefatos de entrada/saída e próximo passo.

**Como funciona o fluxo de PR (branch antes de main)?**
Criar branch de feature (`git checkout -b <nome>`), commitar nela, dar push, e abrir PR (`gh pr create`) para revisão antes de mergear em `main`. Não commitar direto em `main`.

**O `/rn-doctor --json` é confiável pra CI?**
Ainda não — `tests/test.sh` tem hoje um check falhando conhecido ("doctor.sh --json nao produz JSON valido"). Tratar a saída `--json` como não verificada até esse teste passar; usar a saída legível por enquanto.

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

### Linux / macOS / WSL (Bash)

```bash
~/.rn-harness/uninstall.sh
```

### Windows (PowerShell)

```powershell
& "$env:USERPROFILE\.rn-harness\uninstall.ps1"
```

Ambos removem `templates/rn-20days/`, os dois skills (`new-rn-project` + `rn-doctor`) e o repo clonado (`~/.rn-harness` ou `$env:USERPROFILE\.rn-harness`). Projetos existentes não são afetados.

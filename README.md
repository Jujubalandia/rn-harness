# rn-harness

Framework de desenvolvimento para lançar apps React Native na App Store + Play Store em ≤20 dias.

Desenvolvido sobre Claude Code com skills especializados, quality gates e um wizard de inicialização de projetos.

---

## O que é

Um conjunto de templates, skills e hooks que padronizam o fluxo completo:

```
Spec → UX → Dev → QA → Store → Marketing
```

O coração é a skill `/new-rn-project`: você abre um diretório vazio, digita o comando, e o Claude configura todo o projeto interativamente — CLAUDE.md preenchido, docs/, git hooks e checklist de dependências.

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
- Skill `new-rn-project` em `~/.claude/skills/`

---

---

---

## Knowledge Rules

11 arquivos `.md` instalados em `.claude/rules/` de cada novo projeto (copiados pelo `/new-rn-project`). O Claude carrega automaticamente o rule relevante com base nos arquivos que está editando (`globs`).

| Rule | Cobre |
|------|-------|
| `react-native-reanimated.md` | v3: shared values, worklets, runOnJS, layout animations |
| `react-native-gesture-handler.md` | v2 Builder API: Gesture.Pan/Tap, useMemo obrigatório |
| `expo-router.md` | file-based routing, typed routes, deep links |
| `supabase.md` | auth + SecureStore, RLS, Edge Functions, realtime |
| `i18next.md` | t(), Trans, CLDR plurals, Intl.* dates/numbers |
| `zustand.md` | stores por domínio, selector pattern, persist + SecureStore |
| `patterns.md` | folder structure, custom hooks, barrel exports, error boundaries |
| `performance.md` | FlatList, memoization, bundle size, expo-image |
| `security.md` | expo-secure-store, env vars, deep link validation, sem hardcode |
| `accessibility.md` | 44pt targets, t() em accessibilityLabel, screen reader |
| `styling.md` | StyleSheet.create, design tokens, dark mode |

**Versões alvo:** Expo SDK 56 · RN 0.76 · Reanimated v3 · GH v2 · React 18

> Diferença do ERNE: rules aqui são **específicos para a stack do harness** (Supabase, i18next, Expo SDK 56), não genéricos para qualquer projeto RN.


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


## Uso — Novo Projeto

```bash
mkdir ~/projects/meu-app && cd ~/projects/meu-app
claude    # abre Claude Code
```

No Claude Code:

```
/new-rn-project
```

O wizard pergunta nome, descrição, idiomas e monetização, depois cria:
- `CLAUDE.md` preenchido (sem placeholders)
- `DECISIONS.md` + `TODO.md` inicializados
- `docs/` com os 6 templates de fase
- `.githooks/pre-commit` e `pre-push` ativados

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
├── install.sh               ← instalador principal
├── uninstall.sh             ← limpeza completa
├── templates/
│   ├── CLAUDE.md.tmpl       ← template do projeto (com {{PLACEHOLDERS}})
│   ├── DECISIONS.md.stub    ← ADR log inicial
│   ├── TODO.md.stub         ← backlog inicial
│   └── docs/
│       ├── 01-spec.md       ← spec + pesquisa de mercado (D1-D2)
│       ├── 02-dev-plan.md   ← plano 20 dias + milestones
│       ├── 03-quality-gates.md  ← pirâmide de qualidade
│       ├── 04-testing.md    ← tiers de teste + device matrix
│       ├── 05-store-launch.md   ← checklist App Store + Play Store
│       └── 06-marketing.md  ← calendário D-7→D+14
├── skills/
│   └── new-rn-project/      ← skill Claude para wizard de init
│       └── SKILL.md
└── hooks/
    ├── pre-commit.sh        ← typecheck + lint + format + fta
    └── pre-push.sh          ← quality:full + confirmação Android
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
| D17 | Copy de post por plataforma | `marketing-copywriter` | subagente |
| D18 | Conceito viral | `viral-content-strategist` | subagente |
| Pós-D20 | Auditoria de privacidade | `privacy-audit` | `/privacy-audit` |

### Skills bundled (instaladas pelo rn-harness)

- `new-rn-project` — wizard de inicialização de projeto

### Skills de marketplace (instalar separadamente)

Abrir Claude Code e instalar via marketplace ou conforme documentação de cada provider:

| Skill | Provider |
|-------|----------|
| `react-native-best-practices` | callstack (Software Mansion) |
| `zafer-skills` | thedotmack |
| `expo-debugger` | callstack |
| `design-token-guardian` | plugin |
| `i18n-validator` | plugin |
| `store-metadata-reviewer` | plugin |
| `qa-tester` | plugin |
| `marketing-copywriter` | plugin |
| `viral-content-strategist` | plugin |
| `supabase-migrator` | plugin |
| `firecrawl-*` | firecrawl MCP |

---

## Quality Gates

O pré-commit bloqueia se qualquer gate falhar:

```
tsc --noEmit          → zero erros TypeScript
eslint --max-warnings 0 → zero warnings (warnings = erros)
prettier --check      → formatação 100% limpa
fta --score-cap 60    → nenhum arquivo com complexidade ≥ 60
```

Antes de push: `pnpm quality:full` (acima + testes).

Antes de build produção: `pnpm preflight` + Golden Paths manuais.

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
A skill `/new-rn-project` checa a existência de cada arquivo antes de criar. Arquivos existentes são pulados com aviso.

**Como forçar sobrescrita de um arquivo?**
Deletar o arquivo manualmente e rodar `/new-rn-project` novamente, ou editar diretamente.

**Posso usar sem Supabase?**
Sim — remover as linhas de Supabase do `CLAUDE.md` após a geração e substituir pelo seu backend.

**Não tenho Mac para iOS.**
Fluxo documentado em `04-testing.md`: Appetize.io para smoke + iPhone emprestado para TestFlight. O wizard do `/new-rn-project` inclui essa instrução no TODO.md.

**Como atualizar o harness sem quebrar projetos existentes?**
`~/.rn-harness/install.sh` usa `cp -rn` (no-clobber). Projetos existentes com `CLAUDE.md` e `docs/` não são afetados.

---

## Contribuindo

Este é um repo privado. Para melhorias:
1. Editar os arquivos em `~/.rn-harness/` (clone local)
2. Testar com `/new-rn-project` em projeto de teste
3. Commitar e fazer push

Mudanças nos templates entram em vigor nos **próximos** projetos criados via `/new-rn-project`. Projetos existentes não são afetados.

---

## Desinstalar

```bash
~/.rn-harness/uninstall.sh
```

Remove templates, skill e o repo clonado. Projetos existentes não são afetados.

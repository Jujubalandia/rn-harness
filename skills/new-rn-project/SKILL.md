---
name: new-rn-project
description: Wizard interativo para inicializar um novo projeto React Native com o rn-harness. Auto-detecta stack via package.json, cria CLAUDE.md, docs/, DECISIONS.md, TODO.md, git hooks e .claude/rules/. Não sobrescreve arquivos existentes. Invocar no diretório raiz do novo projeto.
---

# New RN Project — Wizard

> Skill instalada em `~/.claude/skills/new-rn-project/` pelo `install.sh` do rn-harness.

## Quando invocar

Usuário está em um diretório de projeto React Native (novo ou existente sem CLAUDE.md) e quer iniciar com o rn-harness.

## Passos — executar nesta ordem

### Passo 1: Verificar localização

Confirmar que o diretório atual é o root do projeto (não subdiretório). Se `CLAUDE.md` já existir, avisar e perguntar se quer continuar.

---

### Passo 1b: Auto-detectar stack via package.json

**Se `package.json` existir**, ler seu conteúdo e detectar automaticamente:

```
STATE_MGMT:
  "zustand"                        → Zustand
  "react-redux"/"@reduxjs/toolkit" → Redux Toolkit
  "jotai"                          → Jotai
  else                             → Zustand (default)

NAVIGATION:
  "expo-router"       → Expo Router (file-based)
  "@react-navigation" → React Navigation
  else                → Expo Router (default)

STYLING:
  "nativewind"   → NativeWind
  "tamagui"      → Tamagui
  "gluestack-ui" → Gluestack
  else           → StyleSheet.create (default)

BACKEND:
  "@supabase/supabase-js"    → Supabase
  "firebase"/"@firebase"     → Firebase
  "convex"                   → Convex
  else                       → "(nenhum)"

I18N:
  "i18next"  → i18next + expo-localization
  else       → "(nenhum)"

ANIMATION:
  "react-native-reanimated"  → Reanimated v3
  else                       → "(nenhum)"

GESTURE:
  "react-native-gesture-handler" → Gesture Handler v2
  else                           → "(nenhum)"

STORAGE:
  "expo-secure-store"                → expo-secure-store (OK)
  "@react-native-async-storage"      → AsyncStorage AVISO: migrar para secure-store
  else                               → "(nenhum)"

IMAGE_GEN:
  "@shopify/react-native-skia"  → Skia
  "react-native-view-shot"      → view-shot
  else                          → "(nenhum)"

TESTING:
  "@testing-library/react-native" → RNTL
  "detox"                         → Detox
  else                            → "(nenhum)"

EXTRAS (para LIBS_ADICIONAIS):
  expo-camera, expo-maps, react-native-maps, react-hook-form,
  expo-sharing, expo-haptics
```

**Exibir tabela de detecção** antes das perguntas:

```
Stack detectada em package.json:
─────────────────────────────────────────────
State management : Zustand           (detectado)
Navigation       : Expo Router       (detectado)
Styling          : StyleSheet.create (default)
Backend          : Supabase          (detectado)
i18n             : i18next           (detectado)
Animation        : Reanimated v3     (detectado)
Gesture          : Gesture Handler   (detectado)
Storage          : expo-secure-store (detectado)
Image gen        : Skia              (detectado)
Testing          : RNTL              (detectado)
Extras           : expo-haptics, expo-sharing
─────────────────────────────────────────────
Enter para confirmar ou informe correções:
```

Aguardar confirmação. Se usuário corrigir alguma dimensão, usar o valor informado.

**Avisos automáticos:**
- AsyncStorage detectado para tokens → `AVISO: Tokens em AsyncStorage — migrar para expo-secure-store`
- Firebase detectado → `AVISO: supabase.md rule não se aplica (Firebase detectado)`

---

### Passo 2: Coletar informações com AskUserQuestion

Perguntar **somente o que não pode ser detectado automaticamente**:

- **APP_NAME**: nome display do app (ex: "BracketBall", "FitTracker")
- **APP_SLUG**: kebab-case sem espaços (ex: "bracketball", "fittracker")
- **COMPANY**: nome da empresa/dev para bundle ID (ex: "jujubalandia")
- **DESCRICAO**: uma linha — problema + solução
- **FOCO_PRINCIPAL**: diferencial ou viral hook (ex: "share card com IA", "gamification diária")
- **IDIOMAS**: PT-BR / EN-US / ES-419 (mínimo PT-BR)
- **MONETIZACAO**: freemium / IAP / ads / subscription / none
- **HOOK_PROFILE**: ler de `~/.rn-harness/.profile` (gravado pelo install). Se arquivo existir, mostrar valor e perguntar se quer manter ou trocar. Se não existir, default `strict`.
  - `minimal` — typecheck apenas (D1-D5, iteração rápida)
  - `standard` — typecheck + lint + format + quality:full no push
  - `strict` — tudo + fta (score-cap 60) — padrão para code freeze

Derivar automaticamente:
- `BUNDLE_ID` = `com.{{COMPANY}}.{{APP_SLUG}}`
- `DATA_INICIO` = data de hoje (ISO)
- `LIBS_ADICIONAIS` = lista das EXTRAS detectadas + backend/i18n/animation se presentes
- `DOMINIO` = derivado do APP_NAME (ex: "Bracket" de "BracketBall")

---

### Passo 3: Verificar ferramentas instaladas

Rodar cada verificação e reportar status:

```
node --version    → precisa >= 20.x
pnpm --version    → precisa estar instalado
git --version     → precisa estar instalado
eas --version     → opcional (instalar: pnpm i -g eas-cli)
supabase --version → opcional se BACKEND=Supabase
maestro --version  → opcional (para E2E)
```

Mostrar tabela: ferramenta | status (OK/FALTA/opcional) | comando de instalação se faltando.

---

### Passo 4: Criar estrutura (sem sobrescrever arquivos existentes)

Para cada arquivo abaixo, checar se existe antes de criar:

**A. `CLAUDE.md`** — de `~/.claude/templates/rn-20days/CLAUDE.md.tmpl`

Substituir todos os `{{PLACEHOLDERS}}`:

| Placeholder | Valor |
|-------------|-------|
| `{{APP_NAME}}` | valor coletado |
| `{{DESCRICAO_UMA_LINHA}}` | valor coletado |
| `{{FOCO_PRINCIPAL}}` | valor coletado |
| `{{IDIOMAS — ex: PT-BR / EN-US}}` | valor coletado |
| `{{LIBS_ADICIONAIS — ex: ...}}` | libs detectadas (ou vazio) |
| `{{TIPOS_DO_DOMINIO}}` | `// TODO: definir tipos do dominio em D3` |
| `{{TABELAS_PRINCIPAIS — ex: ...}}` | `// TODO: definir schema em D3` |
| `{{REGRAS_DO_DOMINIO — ex: ...}}` | remover linha |
| `{{EDITOR — ex: Zed, VS Code}}` | perguntar ou deixar Zed |
| `{{SHELL — ex: PowerShell Windows, bash WSL}}` | detectar ou perguntar |
| `{{DOMINIO}}` | derivado do APP_NAME |

**B. `DECISIONS.md`** — de `~/.claude/templates/rn-20days/DECISIONS.md.stub`
Substituir: `{{APP_NAME}}`, `{{DATA_INICIO}}`

**C. `TODO.md`** — de `~/.claude/templates/rn-20days/TODO.md.stub`
Substituir: `{{APP_NAME}}`, `{{DATA_INICIO}}`
Deixar `{{FEATURE_1}}`, `{{FEATURE_2}}`, `{{FEATURE_3}}` — usuario preenche em D3

**D. `docs/` (6 arquivos)** — copiar de `~/.claude/templates/rn-20days/docs/`
Criar `docs/` se nao existir. Copiar sem substituicao.

**E. `.githooks/pre-commit`** — de `~/.rn-harness/hooks/pre-commit.sh`
**F. `.githooks/pre-push`** — de `~/.rn-harness/hooks/pre-push.sh`

**G. `.claude/rules/`** — copiar de `~/.claude/templates/rn-20days/rules/`

Criar `.claude/rules/` e copiar **seletivamente** com base na stack detectada:

| Rule | Copiar quando |
|------|---------------|
| `patterns.md` | **sempre** |
| `performance.md` | **sempre** |
| `security.md` | **sempre** |
| `accessibility.md` | **sempre** |
| `expo-router.md` | NAVIGATION = Expo Router |
| `supabase.md` | BACKEND = Supabase |
| `i18next.md` | I18N = i18next |
| `zustand.md` | STATE_MGMT = Zustand |
| `react-native-reanimated.md` | ANIMATION = Reanimated v3 |
| `react-native-gesture-handler.md` | GESTURE = Gesture Handler |
| `styling.md` | STYLING = StyleSheet.create |

Se projeto novo (sem package.json): copiar **todos os 11** como base.

---

### Passo 5: Configurar git hooks

```bash
mkdir -p .githooks .claude/rules

# Ler perfil do harness (default strict)
HOOK_PROFILE=$(cat ~/.rn-harness/.profile 2>/dev/null || echo "strict")

# Copiar hooks do perfil selecionado
cp ~/.rn-harness/hooks/profiles/$HOOK_PROFILE/pre-commit.sh .githooks/pre-commit
cp ~/.rn-harness/hooks/profiles/$HOOK_PROFILE/pre-push.sh   .githooks/pre-push
chmod +x .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks
# Rules ja copiadas no Passo 4G
```

Se o usuario escolheu trocar o perfil no Passo 2, usar o perfil escolhido em vez do lido do arquivo.

Mostrar apos configurar: `Hooks instalados com perfil: [minimal/standard/strict]`

Se `.git/` nao existir, rodar `git init` primeiro.

---

### Passo 6: Mostrar checklist de proximos passos

Gerar checklist **adaptado a stack detectada**:

```
Projeto inicializado: {{APP_NAME}}
Stack: {{STATE_MGMT}} + {{NAVIGATION}} + {{STYLING}} + {{BACKEND}} + {{I18N}}

## Proximos passos (D1)
```

Se projeto novo (sem package.json):
```
- [ ] npx create-expo-app@latest . --template blank-typescript
```

Gerar comando `pnpm add` incluindo **apenas o que NAO foi detectado**:
- expo-router (se NAVIGATION nao detectado)
- expo-secure-store (se STORAGE nao detectado)
- expo-haptics (se nao detectado)
- expo-sharing (se nao detectado)
- react-native-reanimated (se ANIMATION nao detectado)
- react-native-gesture-handler (se GESTURE nao detectado)
- zustand (se STATE_MGMT nao e Zustand instalado)
- i18next react-i18next expo-localization (se I18N nao detectado)
- @supabase/supabase-js (se BACKEND nao e Supabase instalado)

Sempre incluir:

```
### Scripts no package.json (adicionar se ausentes):
{
  "typecheck": "tsc --noEmit",
  "lint": "eslint . --max-warnings 0",
  "format:check": "prettier --check .",
  "fta": "fta-cli --score-cap 60 src/",
  "quality:full": "pnpm typecheck && pnpm lint && pnpm format:check && pnpm fta && pnpm test",
  "preflight": "pnpm quality:full"
}

### Supabase (se BACKEND = Supabase):
supabase init
supabase link --project-ref <SEU_PROJECT_REF>

### Skills uteis agora:
- /firecrawl-search — pesquisa de concorrentes (D1-D2)
- /code-review — antes de todo commit
- Subagente design-token-guardian — antes de commitar estilos
- Subagente i18n-validator — antes de commitar texto (se i18n detectado)
```

---

## Comportamento em caso de arquivo existente

Se qualquer arquivo ja existir:
- Avisar: `AVISO: CLAUDE.md ja existe — pulando (use --force para sobrescrever)`
- Continuar criando os outros arquivos
- No resumo final: listar criados vs pulados

## Referencia de templates

Todos os templates estao em `~/.claude/templates/rn-20days/` (instalados pelo `install.sh` do rn-harness).

Se os templates nao existirem (harness nao instalado):
```
ERRO: Templates nao encontrados em ~/.claude/templates/rn-20days/
   Instalar o rn-harness primeiro:
   curl -fsSL https://raw.githubusercontent.com/Jujubalandia/rn-harness/main/install.sh | sh
```

---
name: new-rn-project
description: Wizard interativo para inicializar um novo projeto React Native com o rn-harness. Cria CLAUDE.md, docs/, DECISIONS.md, TODO.md, git hooks. Não sobrescreve arquivos existentes. Invocar no diretório raiz do novo projeto vazio.
---

# New RN Project — Wizard

> Skill instalada em `~/.claude/skills/new-rn-project/` pelo `install.sh` do rn-harness.

## Quando invocar

Usuário está em um diretório novo (sem CLAUDE.md) e quer iniciar um app React Native + Expo + Supabase pronto para lançar em 20 dias.

## Passos — executar nesta ordem

### Passo 1: Verificar localização

Confirmar que o diretório atual é o root do novo projeto (não um subdiretório). Se `CLAUDE.md` já existir, avisar e perguntar se quer continuar mesmo assim.

### Passo 2: Coletar informações com AskUserQuestion

Perguntar ao usuário (pode ser em uma rodada única):
- **APP_NAME**: nome display do app (ex: "BracketBall", "FitTracker")
- **APP_SLUG**: kebab-case sem espaços (ex: "bracketball", "fittracker")
- **COMPANY**: nome da empresa/dev para bundle ID (ex: "jujubalandia")
- **DESCRICAO**: uma linha do que o app faz (problema + solução)
- **FOCO_PRINCIPAL**: diferencial ou viral hook (ex: "share card com IA", "gamification diária")
- **IDIOMAS**: PT-BR / EN-US / ES-419 (ou subconjunto — mínimo PT-BR)
- **MONETIZACAO**: freemium / IAP / ads / subscription / none

Derivar automaticamente:
- `BUNDLE_ID` = `com.{{COMPANY}}.{{APP_SLUG}}`
- `DATA_INICIO` = data de hoje (ISO)

### Passo 3: Verificar ferramentas instaladas

Rodar cada verificação e reportar status:

```
node --version          → precisa ≥ 20.x
pnpm --version          → precisa estar instalado
git --version           → precisa estar instalado
eas --version           → opcional (instalar: pnpm i -g eas-cli)
supabase --version      → opcional (instalar: pnpm i -g supabase)
maestro --version       → opcional (para E2E)
```

Mostrar tabela: ferramenta | status (✅/❌/opcional) | comando de instalação se faltando.

### Passo 4: Criar estrutura (sem sobrescrever arquivos existentes)

Para cada arquivo abaixo, checar se existe antes de criar:

**A. `CLAUDE.md`** — de `~/.claude/templates/rn-20days/CLAUDE.md.tmpl`
  Substituir todos os `{{PLACEHOLDERS}}`:
  - `{{APP_NAME}}` → valor coletado
  - `{{DESCRICAO_UMA_LINHA}}` → valor coletado
  - `{{FOCO_PRINCIPAL}}` → valor coletado
  - `{{IDIOMAS — ex: PT-BR / EN-US}}` → valor coletado
  - `{{LIBS_ADICIONAIS — ex: ...}}` → deixar vazio por enquanto (usuário preenche depois)
  - `{{TIPOS_DO_DOMINIO}}` → comentário: `// TODO: definir tipos do domínio em D3`
  - `{{TABELAS_PRINCIPAIS — ex: ...}}` → comentário: `// TODO: definir schema em D3`
  - `{{REGRAS_DO_DOMINIO — ex: ...}}` → remover linha
  - `{{EDITOR — ex: Zed, VS Code}}` → perguntar ou deixar como `Zed`
  - `{{SHELL — ex: PowerShell Windows, bash WSL}}` → perguntar ou detectar do ambiente

**B. `DECISIONS.md`** — de `~/.claude/templates/rn-20days/templates/DECISIONS.md.stub`
  Substituir: `{{APP_NAME}}`, `{{DATA_INICIO}}`

**C. `TODO.md`** — de `~/.claude/templates/rn-20days/templates/TODO.md.stub`
  Substituir: `{{APP_NAME}}`, `{{DATA_INICIO}}`
  Deixar `{{FEATURE_1}}`, `{{FEATURE_2}}`, `{{FEATURE_3}}` — usuário preenche em D3

**D. `docs/` (6 arquivos)** — copiar de `~/.claude/templates/rn-20days/docs/`
  Criar diretório `docs/` se não existir.
  Copiar sem substituição (os docs têm seus próprios placeholders para o usuário preencher).

**E. `.githooks/pre-commit`** — de `~/.rn-harness/hooks/pre-commit.sh`
**F. `.githooks/pre-push`** — de `~/.rn-harness/hooks/pre-push.sh`

**G. `.claude/rules/`** — copiar de `~/.claude/templates/rn-20days/rules/`
  Criar diretório `.claude/rules/` e copiar todos os 11 arquivos `.md` de rules.
  Esses arquivos ensinam o Claude as APIs corretas para cada biblioteca da stack:
  `react-native-reanimated.md`, `react-native-gesture-handler.md`, `expo-router.md`,
  `supabase.md`, `i18next.md`, `zustand.md`, `patterns.md`, `performance.md`,
  `security.md`, `accessibility.md`, `styling.md`

### Passo 5: Configurar git hooks

```bash
mkdir -p .githooks .claude/rules
cp ~/.rn-harness/hooks/pre-commit.sh .githooks/pre-commit
cp ~/.rn-harness/hooks/pre-push.sh .githooks/pre-push
chmod +x .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks
cp ~/.claude/templates/rn-20days/rules/*.md .claude/rules/
```

Se `.git/` não existir ainda, rodar `git init` primeiro.

### Passo 6: Mostrar checklist de próximos passos

Exibir em markdown após concluir:

```
✅ Projeto inicializado: {{APP_NAME}}

## Próximos passos

### Agora (D1)
- [ ] npx create-expo-app@latest . --template blank-typescript
- [ ] Instalar deps base (ver abaixo)
- [ ] Configurar .env com credenciais Supabase
- [ ] Preencher docs/01-spec.md

### Deps base para instalar
pnpm add expo-router expo-secure-store expo-haptics expo-sharing \
  react-native-reanimated zustand \
  i18next react-i18next expo-localization \
  @supabase/supabase-js

pnpm add -D typescript @types/react \
  eslint @typescript-eslint/eslint-plugin \
  eslint-plugin-react-native eslint-plugin-i18next \
  prettier fta-cli

### Scripts no package.json
{
  "typecheck": "tsc --noEmit",
  "lint": "eslint . --max-warnings 0",
  "format:check": "prettier --check .",
  "fta": "fta-cli --score-cap 60 src/",
  "quality:full": "pnpm typecheck && pnpm lint && pnpm format:check && pnpm fta && pnpm test",
  "preflight": "pnpm quality:full"
}

### Supabase
supabase init
supabase link --project-ref <SEU_PROJECT_REF>

### Skills úteis agora
- /firecrawl-search — pesquisa de concorrentes (D1-D2)
- /code-review — antes de todo commit
- Subagente design-token-guardian — antes de commitar estilos
```

## Comportamento em caso de arquivo existente

Se qualquer arquivo já existir:
- Avisar: "⚠️ `CLAUDE.md` já existe — pulando (use --force para sobrescrever)"
- Continuar criando os outros arquivos
- No resumo final, listar o que foi criado e o que foi pulado

## Referência de templates

Todos os templates estão em `~/.claude/templates/rn-20days/` (instalados pelo `install.sh` do rn-harness).

Se os templates não existirem (harness não instalado), avisar:
```
❌ Templates não encontrados em ~/.claude/templates/rn-20days/
   Instalar o rn-harness primeiro:
   curl -fsSL https://raw.githubusercontent.com/Jujubalandia/rn-harness/main/install.sh | sh
```

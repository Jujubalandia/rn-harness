# 03 — Quality Gates

> Checklist obrigatório. Rodar na ordem. Nenhum commit quebra a cadeia.

---

## Pirâmide de Qualidade

```
          [Golden Paths manuais]     ← D13+, 5 min/dia
         [react-native-optimizer]    ← semanal
        [FTA score < 60/arquivo]
       [ESLint --max-warnings 0]
      [Prettier --check clean]
     [tsc --noEmit zero erros]       ← a cada save
```

Menor custo → maior frequência. Não pule camadas.

---

## Comandos

```bash
# Rodar individualmente
pnpm typecheck        # tsc --noEmit
pnpm lint             # eslint . --max-warnings 0
pnpm format:check     # prettier --check .
pnpm fta              # fta-cli --score-cap 60

# Rodar tudo antes de push para main
pnpm quality:full     # typecheck + lint + format + fta + tests

# Rodar antes de eas build --profile production
pnpm preflight        # quality:full + rnopt
```

> Configurar esses scripts no `package.json` do projeto no D1.

---

## Thresholds

| Gate | Threshold | Quando |
|------|-----------|--------|
| TypeScript | 0 erros | A cada save (IDE) + pre-commit |
| ESLint | 0 warnings | Pre-commit |
| Prettier | 100% clean | Pre-commit |
| FTA score | < 60 | Pre-commit (bloqueia se ≥ 60) |
| Bundle size | JS < 3MB | Pre-production build |
| Tests | 100% pass | Pre-push |

---

## FTA score ≥ 60 — o que fazer

NÃO aumentar o `score_cap`. Refatorar:
1. Extrair sub-componentes (arquivo > 200 linhas)
2. Extrair custom hook (lógica misturada com UI)
3. Extrair lookup table (switch/if-else > 5 casos)
4. Dividir service em funções menores

---

## ESLint rules críticas para React Native

```json
"react-native/no-color-literals": "error",
"react-native/no-unused-styles": "error",
"react-native/split-platform-components": "warn",
"i18next/no-literal-string": "error"
```

Qualquer `"error"` aqui → bloqueia commit.

---

## Golden Paths (GP) — 5 min/dia a partir de D13

Definir 5 fluxos críticos do app antes de D13. Exemplo genérico:

| GP | Fluxo |
|----|-------|
| GP-1 | Novo usuário: install → onboarding → feature principal |
| GP-2 | Usuário retornando: login → feature principal → resultado |
| GP-3 | Share: gerar algo → compartilhar → abrir link |
| GP-4 | Edge case: sem internet → comportamento gracioso |
| GP-5 | Acessibilidade: navegação completa via leitor de tela |

Preencher os GPs reais em `02-dev-plan.md` antes de D13.

---

## Pre-commit hook mínimo

```bash
#!/bin/sh
# .githooks/pre-commit
pnpm typecheck && pnpm lint && pnpm format:check && pnpm fta
```

Ativar com: `git config core.hooksPath .githooks`

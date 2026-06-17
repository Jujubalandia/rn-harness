---
name: rn-doctor
description: Health check de projeto React Native. Roda 22 verificações (ambiente, versões, configs, segurança, git) e explica cada falha com comando de fix. Invocar quando: projeto não commita, build falha, suspeita de config errada, ou no início de cada dia de dev.
---

# rn-doctor — Health Check

> Skill instalada em `~/.claude/skills/rn-doctor/` pelo `install.sh` do rn-harness.

## Quando invocar

- Início de um novo projeto (antes do D1)
- Depois de clonar o repo em nova máquina
- Quando pre-commit hook falha sem motivo claro
- Antes de `eas build --profile production`
- Após atualizar dependências

## Execução

### 1. Rodar o script

```bash
bash ~/.rn-harness/scripts/doctor.sh
```

PowerShell (Windows):
```powershell
& "$env:USERPROFILE\.rn-harness\scripts\doctor.ps1"
```

Ou com `--json` para output estruturado:
```bash
bash ~/.rn-harness/scripts/doctor.sh --json
```

### 2. Interpretar resultado

O script reporta cada check em uma linha:

```
  [OK]   descrição
  [WARN] descrição
  [FAIL] descrição
         fix: comando
```

**Exit code:**
- `0` = nenhum FAIL (OK e WARN passam)
- `1` = pelo menos um FAIL

### 3. Explicar e corrigir FAILs

Para cada `[FAIL]` no output, explicar a causa raiz e executar o fix sugerido após confirmação do usuário.

Para `[WARN]`, avaliar contexto: se projeto está em D1-D5 e ainda sem store build, warns de eas.json são irrelevantes.

## Os 22 checks

| # | Check | Nível se falhar |
|---|-------|----------------|
| 1 | node >= 20.x | FAIL |
| 2 | pnpm instalado | FAIL |
| 3 | git instalado | FAIL |
| 4 | eas-cli instalado | WARN |
| 5 | package.json presente no CWD | FAIL |
| 6 | CLAUDE.md presente | WARN |
| 7 | .gitignore cobre .env* | FAIL |
| 8 | Nenhum .env* commitado no git | FAIL |
| 9 | .claude/rules/ presente | WARN |
| 10 | Expo SDK = ^56 | FAIL |
| 11 | React Native = 0.76.x | WARN |
| 12 | react-native-reanimated = ^3.x (não v4) | FAIL se v4, WARN se ausente |
| 13 | tsconfig.json com "strict": true | FAIL |
| 14 | babel.config.js tem plugin reanimated | FAIL se reanimated instalado |
| 15 | ESLint tem react-native/no-color-literals | WARN |
| 16 | Scripts pnpm: typecheck, lint, format:check, fta, quality:full | FAIL |
| 17 | expo-secure-store presente, AsyncStorage ausente de deps | FAIL se só AsyncStorage |
| 18 | Sem chaves hardcoded em .ts/.tsx | FAIL |
| 19 | .git/ existe | FAIL |
| 20 | git core.hooksPath = .githooks | FAIL |
| 21 | app.json/app.config.ts tem bundleIdentifier + packageName | WARN |
| 22 | eas.json presente | WARN |

## Fixes frequentes

### FAIL 7: .gitignore sem .env*

```bash
echo '.env*' >> .gitignore
echo '!.env.example' >> .gitignore
git add .gitignore && git commit -m "chore: gitignore .env*"
```

### FAIL 13: tsconfig sem strict

```json
// tsconfig.json — dentro de compilerOptions:
{
  "compilerOptions": {
    "strict": true
  }
}
```

### FAIL 14: babel.config.js sem plugin reanimated

```javascript
// babel.config.js
module.exports = function(api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: ['react-native-reanimated/plugin'],  // DEVE ser o último
  };
};
```

### FAIL 16: scripts pnpm ausentes

```json
// package.json
{
  "scripts": {
    "typecheck": "tsc --noEmit",
    "lint": "eslint . --max-warnings 0",
    "format:check": "prettier --check .",
    "fta": "fta-cli --score-cap 60 src/",
    "quality:full": "pnpm typecheck && pnpm lint && pnpm format:check && pnpm fta && pnpm test"
  }
}
```

### FAIL 20: core.hooksPath não configurado

```bash
mkdir -p .githooks
cp ~/.rn-harness/hooks/profiles/strict/pre-commit.sh .githooks/pre-commit
cp ~/.rn-harness/hooks/profiles/strict/pre-push.sh   .githooks/pre-push
chmod +x .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks
```

## Comportamento esperado por fase

| Fase | FAILs aceitáveis | WARNs normais |
|------|-----------------|---------------|
| D1 (setup) | nenhum | 6 (CLAUDE.md), 9 (rules), 21-22 (store) |
| D3+ (dev) | nenhum | 21-22 (se ainda sem store config) |
| D14+ (store prep) | nenhum | nenhum — todos devem ser OK |

## Referência dos scripts

```
~/.rn-harness/scripts/doctor.sh   ← bash (Linux/macOS/WSL)
~/.rn-harness/scripts/doctor.ps1  ← PowerShell 5.1+ (Windows)
```

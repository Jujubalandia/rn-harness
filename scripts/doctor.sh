#!/bin/sh
# rn-harness doctor — 22 health checks for a React Native project
# Usage: doctor.sh [--json] [project-dir]
# Exit: 0 = all OK/WARN, 1 = at least one FAIL

set -e

PROJECT_DIR="${2:-${1:-.}}"
JSON_MODE=""
[ "$1" = "--json" ] && { JSON_MODE=1; PROJECT_DIR="${2:-.}"; }

OK=0; WARN=0; FAIL=0
RESULTS=""

_out() {
  # _out LEVEL NUMBER MESSAGE [FIX]
  local level="$1" num="$2" msg="$3" fix="${4:-}"
  case "$level" in
    OK)   OK=$((OK + 1))   ;;
    WARN) WARN=$((WARN + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
  esac
  if [ -n "$JSON_MODE" ]; then
    RESULTS="${RESULTS}{\"n\":$num,\"level\":\"$level\",\"msg\":\"$msg\",\"fix\":\"$fix\"},"
  else
    case "$level" in
      OK)   printf '  [OK]   %s\n' "$msg" ;;
      WARN) printf '  [WARN] %s\n' "$msg" ;;
      FAIL) printf '  [FAIL] %s\n  ↳ fix: %s\n' "$msg" "$fix" ;;
    esac
  fi
}

[ -z "$JSON_MODE" ] && printf '\nrn-harness doctor\n=================\n'

# ── 1. node >= 20 ─────────────────────────────────────────────────────────────
if command -v node >/dev/null 2>&1; then
  NODE_MAJ=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_MAJ" -ge 20 ] 2>/dev/null; then
    _out OK 1 "node $(node --version) >= 20"
  else
    _out FAIL 1 "node $(node --version) < 20" "nvm install 20 && nvm use 20"
  fi
else
  _out FAIL 1 "node não encontrado" "https://nodejs.org (LTS 20)"
fi

# ── 2. pnpm ───────────────────────────────────────────────────────────────────
if command -v pnpm >/dev/null 2>&1; then
  _out OK 2 "pnpm $(pnpm --version) instalado"
else
  _out FAIL 2 "pnpm não encontrado" "npm install -g pnpm"
fi

# ── 3. git ────────────────────────────────────────────────────────────────────
if command -v git >/dev/null 2>&1; then
  _out OK 3 "git $(git --version | awk '{print $3}') instalado"
else
  _out FAIL 3 "git não encontrado" "https://git-scm.com"
fi

# ── 4. eas-cli ────────────────────────────────────────────────────────────────
if command -v eas >/dev/null 2>&1; then
  _out OK 4 "eas-cli $(eas --version 2>/dev/null | head -1) instalado"
else
  _out WARN 4 "eas-cli não encontrado (opcional para builds)" "pnpm install -g eas-cli"
fi

# ── 5. package.json ───────────────────────────────────────────────────────────
PKG="$PROJECT_DIR/package.json"
if [ -f "$PKG" ]; then
  _out OK 5 "package.json presente"
else
  _out FAIL 5 "package.json não encontrado (não é raiz do projeto?)" "cd <projeto> && pnpm init"
fi

# ── 6. CLAUDE.md ──────────────────────────────────────────────────────────────
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  _out OK 6 "CLAUDE.md presente"
else
  _out WARN 6 "CLAUDE.md ausente (rn-harness não inicializado)" "/new-rn-project para criar"
fi

# ── 7. .gitignore cobre .env* ─────────────────────────────────────────────────
GITIGNORE="$PROJECT_DIR/.gitignore"
if [ -f "$GITIGNORE" ] && grep -qE '^\.(env|env\*)' "$GITIGNORE" 2>/dev/null; then
  _out OK 7 ".gitignore cobre .env*"
else
  _out FAIL 7 ".gitignore não cobre .env* (risco de vazar segredos)" "echo '.env*' >> .gitignore && echo '!.env.example' >> .gitignore"
fi

# ── 8. nenhum .env* commitado ────────────────────────────────────────────────
if [ -d "$PROJECT_DIR/.git" ]; then
  ENV_COMMITTED=$(git -C "$PROJECT_DIR" ls-files '*.env' '.env.*' '.env' 2>/dev/null | head -1)
  if [ -z "$ENV_COMMITTED" ]; then
    _out OK 8 "nenhum .env* commitado no git"
  else
    _out FAIL 8 ".env* commitado: $ENV_COMMITTED" "git rm --cached $ENV_COMMITTED && echo '$ENV_COMMITTED' >> .gitignore"
  fi
else
  _out WARN 8 ".git/ ausente — não é possível verificar .env* commitados" "git init"
fi

# ── 9. .claude/rules/ presente ───────────────────────────────────────────────
if [ -d "$PROJECT_DIR/.claude/rules" ] && [ "$(ls -A "$PROJECT_DIR/.claude/rules" 2>/dev/null)" ]; then
  RULE_COUNT=$(find "$PROJECT_DIR/.claude/rules" -name '*.md' | wc -l | tr -d ' ')
  _out OK 9 ".claude/rules/ presente ($RULE_COUNT rules)"
else
  _out WARN 9 ".claude/rules/ ausente (knowledge rules não instaladas)" "/rn-harness:new-rn-project ou copiar manualmente do plugin (\$CLAUDE_PLUGIN_ROOT/templates/rules/)"
fi

# ── 10. Expo SDK 56 ───────────────────────────────────────────────────────────
if [ -f "$PKG" ]; then
  EXPO_VER=$(grep -o '"expo"[[:space:]]*:[[:space:]]*"[^"]*"' "$PKG" | sed 's/.*"expo"[^"]*"//;s/".*//' | tr -d '"^~' | head -1)
  EXPO_MAJ=$(echo "$EXPO_VER" | cut -d. -f1)
  if [ "$EXPO_MAJ" = "56" ] 2>/dev/null; then
    _out OK 10 "Expo SDK $EXPO_VER (56)"
  elif [ -n "$EXPO_MAJ" ]; then
    _out FAIL 10 "Expo SDK $EXPO_VER (harness alvo: SDK 56)" "npx expo install expo@^56 --fix"
  else
    _out WARN 10 "expo não encontrado em package.json" "pnpm add expo@^56"
  fi
fi

# ── 11. React Native 0.76.x ──────────────────────────────────────────────────
if [ -f "$PKG" ]; then
  RN_VER=$(grep -o '"react-native"[[:space:]]*:[[:space:]]*"[^"]*"' "$PKG" | grep -o '"[^"]*"$' | tr -d '"' | head -1)
  RN_MINOR=$(echo "$RN_VER" | sed 's/[\^~]//' | cut -d. -f2)
  if [ "$RN_MINOR" = "76" ] 2>/dev/null; then
    _out OK 11 "React Native $RN_VER (0.76.x)"
  elif [ -n "$RN_MINOR" ]; then
    _out WARN 11 "React Native $RN_VER (harness alvo: 0.76.x — verificar compatibilidade)" ""
  else
    _out WARN 11 "react-native não encontrado em package.json" ""
  fi
fi

# ── 12. Reanimated v3 (não v4) ───────────────────────────────────────────────
if [ -f "$PKG" ]; then
  REANIM_VER=$(grep -o '"react-native-reanimated"[[:space:]]*:[[:space:]]*"[^"]*"' "$PKG" | grep -o '"[^"]*"$' | tr -d '"' | head -1)
  REANIM_MAJ=$(echo "$REANIM_VER" | sed 's/[\^~]//' | cut -d. -f1)
  if [ "$REANIM_MAJ" = "3" ] 2>/dev/null; then
    _out OK 12 "react-native-reanimated $REANIM_VER (v3)"
  elif [ "$REANIM_MAJ" = "4" ] 2>/dev/null; then
    _out FAIL 12 "react-native-reanimated $REANIM_VER (v4 — harness usa v3, rules incompatíveis)" "pnpm add react-native-reanimated@^3"
  elif [ -n "$REANIM_MAJ" ]; then
    _out WARN 12 "react-native-reanimated $REANIM_VER (esperado ^3.x)" ""
  else
    _out WARN 12 "react-native-reanimated não encontrado" "pnpm add react-native-reanimated@^3"
  fi
fi

# ── 13. tsconfig.json com strict:true ────────────────────────────────────────
TSCONFIG="$PROJECT_DIR/tsconfig.json"
if [ -f "$TSCONFIG" ]; then
  if grep -q '"strict"[[:space:]]*:[[:space:]]*true' "$TSCONFIG" 2>/dev/null; then
    _out OK 13 "tsconfig.json com \"strict\": true"
  else
    _out FAIL 13 "tsconfig.json sem \"strict\": true" "Adicionar '\"strict\": true' em compilerOptions"
  fi
else
  _out FAIL 13 "tsconfig.json não encontrado" "npx tsc --init"
fi

# ── 14. babel.config.js tem plugin reanimated ────────────────────────────────
BABEL="$PROJECT_DIR/babel.config.js"
if [ ! -f "$BABEL" ]; then
  BABEL="$PROJECT_DIR/babel.config.ts"
fi
if [ -f "$BABEL" ]; then
  if grep -q 'react-native-reanimated/plugin' "$BABEL" 2>/dev/null; then
    _out OK 14 "babel.config.js tem plugin react-native-reanimated"
  else
    if [ -f "$PROJECT_DIR/package.json" ] && grep -q '"react-native-reanimated"' "$PKG" 2>/dev/null; then
      _out FAIL 14 "babel.config.js sem plugin react-native-reanimated (reanimated instalado)" "Adicionar 'react-native-reanimated/plugin' ao array plugins do babel.config.js"
    else
      _out OK 14 "babel.config.js sem plugin reanimated (reanimated não instalado)"
    fi
  fi
else
  _out WARN 14 "babel.config.js não encontrado" "criar babel.config.js com preset expo"
fi

# ── 15. ESLint tem react-native/no-color-literals ────────────────────────────
ESLINT=""
for f in "$PROJECT_DIR/.eslintrc.js" "$PROJECT_DIR/.eslintrc.cjs" "$PROJECT_DIR/.eslintrc.json" "$PROJECT_DIR/.eslintrc.yaml" "$PROJECT_DIR/eslint.config.js" "$PROJECT_DIR/eslint.config.mjs"; do
  [ -f "$f" ] && { ESLINT="$f"; break; }
done
if [ -n "$ESLINT" ]; then
  if grep -q 'no-color-literals' "$ESLINT" 2>/dev/null; then
    _out OK 15 "ESLint tem react-native/no-color-literals"
  else
    _out WARN 15 "ESLint sem react-native/no-color-literals" "Adicionar 'react-native/no-color-literals': 'error' ao ESLint config"
  fi
else
  _out WARN 15 "ESLint config não encontrado (adicionar em D3+)" "pnpm add -D eslint @react-native/eslint-config"
fi

# ── 16. Scripts pnpm obrigatórios ────────────────────────────────────────────
if [ -f "$PKG" ]; then
  MISSING_SCRIPTS=""
  for script in typecheck lint "format:check" fta "quality:full"; do
    grep -q "\"$script\"" "$PKG" 2>/dev/null || MISSING_SCRIPTS="$MISSING_SCRIPTS $script"
  done
  if [ -z "$MISSING_SCRIPTS" ]; then
    _out OK 16 "scripts pnpm: typecheck, lint, format:check, fta, quality:full — todos presentes"
  else
    _out FAIL 16 "scripts pnpm ausentes:$MISSING_SCRIPTS" "Adicionar scripts em package.json (ver docs/03-quality-gates.md)"
  fi
fi

# ── 17. expo-secure-store presente, AsyncStorage ausente de deps diretas ──────
if [ -f "$PKG" ]; then
  HAS_SECURE=$(grep -c '"expo-secure-store"' "$PKG" 2>/dev/null; true)
  HAS_ASYNC=$(grep -c '"@react-native-async-storage/async-storage"' "$PKG" 2>/dev/null; true)
  if [ "$HAS_SECURE" -gt 0 ] && [ "$HAS_ASYNC" -eq 0 ]; then
    _out OK 17 "expo-secure-store presente, AsyncStorage ausente"
  elif [ "$HAS_SECURE" -gt 0 ] && [ "$HAS_ASYNC" -gt 0 ]; then
    _out WARN 17 "expo-secure-store E AsyncStorage presentes — garantir que tokens usam SecureStore" "Ver rules/security.md — AsyncStorage não é criptografado"
  elif [ "$HAS_ASYNC" -gt 0 ]; then
    _out FAIL 17 "AsyncStorage presente sem expo-secure-store — tokens em texto puro" "pnpm add expo-secure-store && migrar tokens"
  else
    _out WARN 17 "expo-secure-store não encontrado" "pnpm add expo-secure-store"
  fi
fi

# ── 18. Sem chaves hardcoded em .ts/.tsx ─────────────────────────────────────
if [ -d "$PROJECT_DIR" ]; then
  HARDCODED=$(grep -rn --include='*.ts' --include='*.tsx' \
    -E '(API_KEY|SECRET|PASSWORD|api_key|apiKey)\s*=\s*["'"'"'][A-Za-z0-9_\-]{8,}' \
    "$PROJECT_DIR" 2>/dev/null | grep -v 'node_modules\|\.test\.' | head -3)
  if [ -z "$HARDCODED" ]; then
    _out OK 18 "sem chaves hardcoded detectadas em .ts/.tsx"
  else
    FIRST=$(echo "$HARDCODED" | head -1)
    _out FAIL 18 "possível chave hardcoded: $FIRST" "Mover para .env.local + process.env.EXPO_PUBLIC_*"
  fi
fi

# ── 19. .git/ existe ──────────────────────────────────────────────────────────
if [ -d "$PROJECT_DIR/.git" ]; then
  _out OK 19 "repositório git inicializado"
else
  _out FAIL 19 ".git/ não encontrado" "git init && git add . && git commit -m 'init'"
fi

# ── 20. core.hooksPath = .githooks ───────────────────────────────────────────
if [ -d "$PROJECT_DIR/.git" ]; then
  HOOKS_PATH=$(git -C "$PROJECT_DIR" config core.hooksPath 2>/dev/null || echo "")
  if [ "$HOOKS_PATH" = ".githooks" ]; then
    _out OK 20 "git core.hooksPath = .githooks"
  elif [ -n "$HOOKS_PATH" ]; then
    _out WARN 20 "git core.hooksPath = '$HOOKS_PATH' (esperado .githooks)" "git config core.hooksPath .githooks"
  else
    _out FAIL 20 "git core.hooksPath não configurado — hooks não vão rodar" "git config core.hooksPath .githooks"
  fi
else
  _out WARN 20 ".git/ ausente — core.hooksPath não verificável" "git init"
fi

# ── 21. app.json tem bundleIdentifier + packageName ──────────────────────────
APP_JSON=""
[ -f "$PROJECT_DIR/app.json" ] && APP_JSON="$PROJECT_DIR/app.json"
[ -f "$PROJECT_DIR/app.config.ts" ] && APP_JSON="$PROJECT_DIR/app.config.ts"
[ -f "$PROJECT_DIR/app.config.js" ] && APP_JSON="$PROJECT_DIR/app.config.js"
if [ -n "$APP_JSON" ]; then
  HAS_BUNDLE=$(grep -c 'bundleIdentifier' "$APP_JSON" 2>/dev/null || echo 0)
  HAS_PKG=$(grep -c 'package' "$APP_JSON" 2>/dev/null || echo 0)
  if [ "$HAS_BUNDLE" -gt 0 ] && [ "$HAS_PKG" -gt 0 ]; then
    _out OK 21 "$APP_JSON tem bundleIdentifier e packageName"
  else
    _out WARN 21 "$APP_JSON sem bundleIdentifier/packageName (obrigatório para store build)" "Preencher ios.bundleIdentifier e android.package em app.json"
  fi
else
  _out WARN 21 "app.json / app.config.ts não encontrado" "npx create-expo-app ou criar app.json manualmente"
fi

# ── 22. eas.json presente ─────────────────────────────────────────────────────
if [ -f "$PROJECT_DIR/eas.json" ]; then
  _out OK 22 "eas.json presente"
else
  if command -v eas >/dev/null 2>&1; then
    _out WARN 22 "eas.json ausente (eas-cli instalado — builds de store não configurados)" "eas build:configure"
  else
    _out WARN 22 "eas.json ausente (opcional se não usar EAS Build)" "eas build:configure quando pronto para store"
  fi
fi

# ── 23. lineHeight em StyleSheet (bug Android) ───────────────────────────────
if [ -d "$PROJECT_DIR" ]; then
  LINEH=$(grep -rn --include='*.ts' --include='*.tsx' --include='*.js' \
    'lineHeight' "$PROJECT_DIR" 2>/dev/null \
    | grep -v 'node_modules\|\.test\.\|\.d\.ts' | head -1)
  if [ -z "$LINEH" ]; then
    _out OK 23 "sem lineHeight em StyleSheet (Android-safe)"
  else
    _out FAIL 23 "lineHeight detectado: $(echo "$LINEH" | head -1 | cut -c1-80)" "Substituir por paddingVertical/marginVertical (lineHeight corta texto em Android)"
  fi
fi

# ── 24. expo-av importado (deprecated) ───────────────────────────────────────
if [ -d "$PROJECT_DIR" ]; then
  EXPOAV=$(grep -rn --include='*.ts' --include='*.tsx' --include='*.js' \
    "from 'expo-av'" "$PROJECT_DIR" 2>/dev/null \
    | grep -v 'node_modules\|\.test\.' | head -1)
  if [ -z "$EXPOAV" ]; then
    _out OK 24 "expo-av não usado (usar expo-video + expo-audio)"
  else
    _out FAIL 24 "expo-av importado (deprecated): $(echo "$EXPOAV" | head -1 | cut -c1-80)" "Migrar para expo-video (vídeo) e expo-audio (áudio)"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
TOTAL=$((OK + WARN + FAIL))

if [ -n "$JSON_MODE" ]; then
  RESULTS="${RESULTS%,}"
  printf '{"ok":%d,"warn":%d,"fail":%d,"total":%d,"results":[%s]}\n' \
    "$OK" "$WARN" "$FAIL" "$TOTAL" "$RESULTS"
else
  printf '\n%s\n' "────────────────────────────────────────"
  printf 'OK: %d  WARN: %d  FAIL: %d  / %d total\n' "$OK" "$WARN" "$FAIL" "$TOTAL"
  printf '%s\n\n' "────────────────────────────────────────"
fi

[ "$FAIL" -eq 0 ]

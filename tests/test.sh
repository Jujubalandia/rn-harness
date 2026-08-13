#!/usr/bin/env bash
# tests/test.sh — plain bash tests para rn-harness
# Sem dependências externas. Roda: bash tests/test.sh
#
# Cobre:
#   1. Estrutura do repo (plugin manifests, arquivos, permissões)
#   2. Placeholder lint (CLAUDE.md.tmpl)
#   3. Placeholder lint (stubs)
#   4. Git hooks — exit codes
#   5. SKILL.md — referências de path (${CLAUDE_PLUGIN_ROOT})
#   6. Doctor — estrutura e checks básicos
#
# Instalação/desinstalação são responsabilidade do Claude Code plugin manager
# (/plugin install, /plugin uninstall) — não há mais install.sh/uninstall.sh
# neste repo para testar.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
ERRORS=()

# ── cores ─────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

# ── helpers ───────────────────────────────────────────────────────────────
pass()   { echo -e "  ${GREEN}✅${NC} $1"; PASS=$((PASS + 1)); }
fail()   { echo -e "  ${RED}❌${NC} $1"; FAIL=$((FAIL + 1)); ERRORS+=("$1"); }
section(){ echo -e "\n${BOLD}$1${NC}"; }

assert_file()  { [ -f "$1" ] && pass "${2:-$1}" || fail "${2:-$1} — arquivo ausente"; }
assert_dir()   { [ -d "$1" ] && pass "${2:-$1}" || fail "${2:-$1} — dir ausente"; }
assert_exec()  { [ -x "$1" ] && pass "${2:-$1} executável" || fail "${2:-$1} não é executável"; }

assert_has()   { grep -q "$2" "$1" && pass "${3:-$1 contém '$2'}" || fail "${3:-$1 não contém '$2'}"; }
assert_lacks() { ! grep -q "$2" "$1" && pass "${3:-$1 sem '$2'}" || fail "${3:-$1 contém '$2' indevido}"; }

run_exit() {
  # run_exit EXPECTED_CODE LABEL CMD [args...]
  local expected="$1" label="$2"; shift 2
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  [ "$actual" -eq "$expected" ] \
    && pass "$label (exit $expected)" \
    || fail "$label (esperado $expected, obtido $actual)"
}

# ── ambiente temporário ────────────────────────────────────────────────────
TMPBASE="$(mktemp -d)"
cleanup() { rm -rf "$TMPBASE"; }
trap cleanup EXIT

MOCK_BIN="$TMPBASE/bin"
mkdir -p "$MOCK_BIN"

SKILL="$REPO_DIR/skills/new-rn-project/SKILL.md"

# ══════════════════════════════════════════════════════════════════════════
section "1. Estrutura do repo (plugin)"

assert_file "$REPO_DIR/.claude-plugin/plugin.json"            "plugin.json"
assert_file "$REPO_DIR/.claude-plugin/marketplace.json"       "marketplace.json"
assert_has  "$REPO_DIR/.claude-plugin/marketplace.json" '"source": "./"' \
  "marketplace.json aponta source: \"./\" (self-hosted)"

assert_file "$REPO_DIR/README.md"                             "README.md"
assert_dir  "$REPO_DIR/templates"                             "templates/"
assert_dir  "$REPO_DIR/templates/docs"                        "templates/docs/"
assert_dir  "$REPO_DIR/skills/new-rn-project"                 "skills/new-rn-project/"
assert_dir  "$REPO_DIR/git-hooks"                              "git-hooks/"

assert_file "$REPO_DIR/templates/CLAUDE.md.tmpl"              "CLAUDE.md.tmpl"
assert_file "$REPO_DIR/templates/DECISIONS.md.stub"           "DECISIONS.md.stub"
assert_file "$REPO_DIR/templates/TODO.md.stub"                "TODO.md.stub"
assert_file "$REPO_DIR/skills/new-rn-project/SKILL.md"        "SKILL.md"
assert_file "$REPO_DIR/git-hooks/pre-commit.sh"                "git-hooks/pre-commit.sh"
assert_file "$REPO_DIR/git-hooks/pre-push.sh"                  "git-hooks/pre-push.sh"

assert_exec "$REPO_DIR/git-hooks/pre-commit.sh"                "pre-commit.sh executável"
assert_exec "$REPO_DIR/git-hooks/pre-push.sh"                  "pre-push.sh executável"

assert_file "$REPO_DIR/git-hooks/pre-commit.ps1"               "git-hooks/pre-commit.ps1"
assert_file "$REPO_DIR/git-hooks/pre-push.ps1"                 "git-hooks/pre-push.ps1"
assert_file "$REPO_DIR/tests/test.ps1"                        "tests/test.ps1"

assert_dir  "$REPO_DIR/git-hooks/profiles/minimal"             "git-hooks/profiles/minimal/"
assert_dir  "$REPO_DIR/git-hooks/profiles/standard"            "git-hooks/profiles/standard/"
assert_dir  "$REPO_DIR/git-hooks/profiles/strict"              "git-hooks/profiles/strict/"
for profile in minimal standard strict; do
  assert_file "$REPO_DIR/git-hooks/profiles/$profile/pre-commit.sh"  "profiles/$profile/pre-commit.sh"
  assert_file "$REPO_DIR/git-hooks/profiles/$profile/pre-push.sh"    "profiles/$profile/pre-push.sh"
  assert_file "$REPO_DIR/git-hooks/profiles/$profile/pre-commit.ps1" "profiles/$profile/pre-commit.ps1"
  assert_file "$REPO_DIR/git-hooks/profiles/$profile/pre-push.ps1"   "profiles/$profile/pre-push.ps1"
done

assert_file "$REPO_DIR/scripts/doctor.sh"              "scripts/doctor.sh"
assert_file "$REPO_DIR/scripts/doctor.ps1"             "scripts/doctor.ps1"
assert_file "$REPO_DIR/skills/rn-doctor/SKILL.md"      "skills/rn-doctor/SKILL.md"

assert_dir  "$REPO_DIR/templates/rules"                           "templates/rules/"
assert_file "$REPO_DIR/templates/rules/react-native-reanimated.md" "rules/reanimated.md"
assert_file "$REPO_DIR/templates/rules/expo-router.md"             "rules/expo-router.md"
assert_file "$REPO_DIR/templates/rules/supabase.md"                "rules/supabase.md"
assert_file "$REPO_DIR/templates/rules/i18next.md"                 "rules/i18next.md"
assert_file "$REPO_DIR/templates/rules/zustand.md"                 "rules/zustand.md"
assert_file "$REPO_DIR/templates/rules/patterns.md"                "rules/patterns.md"
assert_file "$REPO_DIR/templates/rules/performance.md"             "rules/performance.md"
assert_file "$REPO_DIR/templates/rules/security.md"                "rules/security.md"
assert_file "$REPO_DIR/templates/rules/accessibility.md"           "rules/accessibility.md"
assert_file "$REPO_DIR/templates/rules/styling.md"                 "rules/styling.md"
assert_file "$REPO_DIR/templates/rules/react-native-gesture-handler.md" "rules/gesture-handler.md"
assert_file "$REPO_DIR/templates/rules/forbidden.md"                       "rules/forbidden.md"
assert_file "$REPO_DIR/templates/rules/expo-video.md"                     "rules/expo-video.md"
assert_file "$REPO_DIR/templates/rules/revenue-cat.md"                    "rules/revenue-cat.md"
assert_file "$REPO_DIR/templates/rules/expo-notifications.md"             "rules/expo-notifications.md"
assert_file "$REPO_DIR/templates/claude/settings.json"                    "claude/settings.json"
assert_file "$REPO_DIR/templates/claude/hooks/pre-tool-use.sh"            "claude/hooks/pre-tool-use.sh"

for prefix in "01" "02" "03" "04" "05" "06"; do
  found=0
  for f in "$REPO_DIR/templates/docs/${prefix}-"*.md; do
    [ -f "$f" ] && found=1 && break
  done
  [ "$found" -eq 1 ] \
    && pass "templates/docs/${prefix}-*.md" \
    || fail "templates/docs/${prefix}-*.md ausente"
done

# ══════════════════════════════════════════════════════════════════════════
section "2. Placeholder lint — CLAUDE.md.tmpl"

TMPL="$REPO_DIR/templates/CLAUDE.md.tmpl"

# Extrair chaves: {{APP_NAME}}, {{IDIOMAS — ex: ...}} → APP_NAME, IDIOMAS
KEYS=$(grep -oE '\{\{[A-Z_]+' "$TMPL" | sed 's/{{//' | sort -u)

while IFS= read -r key; do
  [ -z "$key" ] && continue
  assert_has "$SKILL" "$key" "Placeholder {{$key}} referenciado no SKILL.md"
done <<< "$KEYS"

# Checar balanceamento {{ }}
opens=$(grep -o '{{' "$TMPL" | wc -l)
closes=$(grep -o '}}' "$TMPL" | wc -l)
[ "$opens" -eq "$closes" ] \
  && pass "Placeholders balanceados ($opens abre, $closes fecha)" \
  || fail "Placeholders desbalanceados ($opens abre, $closes fecha)"

# ══════════════════════════════════════════════════════════════════════════
section "3. Placeholder lint — stubs"

for stub in "$REPO_DIR/templates/"*.stub; do
  name="$(basename "$stub")"
  KEYS=$(grep -oE '\{\{[A-Z_]+' "$stub" | sed 's/{{//' | sort -u)
  while IFS= read -r key; do
    [ -z "$key" ] && continue
    assert_has "$SKILL" "$key" "$name: {{$key}} no SKILL.md"
  done <<< "$KEYS"

  opens=$(grep -o '{{' "$stub" | wc -l)
  closes=$(grep -o '}}' "$stub" | wc -l)
  [ "$opens" -eq "$closes" ] \
    && pass "$name: placeholders balanceados" \
    || fail "$name: placeholders desbalanceados ($opens//$closes)"
done

# ══════════════════════════════════════════════════════════════════════════
section "4. Git hooks — exit codes"

# pnpm falha → pre-commit deve sair 1
cat > "$MOCK_BIN/pnpm" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$MOCK_BIN/pnpm"

run_exit 1 "pre-commit sai 1 quando pnpm falha" \
  env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/git-hooks/pre-commit.sh"

# pnpm passa → pre-commit deve sair 0
cat > "$MOCK_BIN/pnpm" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$MOCK_BIN/pnpm"

run_exit 0 "pre-commit sai 0 quando pnpm passa" \
  env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/git-hooks/pre-commit.sh"

# pre-push: resposta N → sai 1
actual=0
(echo "N" | env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/git-hooks/pre-push.sh" >/dev/null 2>&1) || actual=$?
[ "$actual" -eq 1 ] \
  && pass "pre-push sai 1 com resposta N" \
  || fail "pre-push sai $actual com resposta N (esperado 1)"

# pre-push: resposta y → sai 0
actual=0
(echo "y" | env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/git-hooks/pre-push.sh" >/dev/null 2>&1) || actual=$?
[ "$actual" -eq 0 ] \
  && pass "pre-push sai 0 com resposta y" \
  || fail "pre-push sai $actual com resposta y (esperado 0)"

# Profiles: minimal sem fta, strict com fta, standard com lint sem fta
assert_lacks "$REPO_DIR/git-hooks/profiles/minimal/pre-commit.sh"   "fta" "minimal/pre-commit.sh sem fta"
assert_has   "$REPO_DIR/git-hooks/profiles/minimal/pre-commit.sh"   "typecheck" "minimal/pre-commit.sh tem typecheck"
assert_has   "$REPO_DIR/git-hooks/profiles/strict/pre-commit.sh"    "fta" "strict/pre-commit.sh tem fta"
assert_has   "$REPO_DIR/git-hooks/profiles/standard/pre-commit.sh"  "lint" "standard/pre-commit.sh tem lint"
assert_lacks "$REPO_DIR/git-hooks/profiles/standard/pre-commit.sh"  "fta" "standard/pre-commit.sh sem fta"

# ══════════════════════════════════════════════════════════════════════════
section "5. SKILL.md — referências de path (plugin)"

assert_has "$SKILL" '\${CLAUDE_PLUGIN_ROOT}/templates' \
  "SKILL.md referencia templates via \${CLAUDE_PLUGIN_ROOT}"

assert_has "$SKILL" '\${CLAUDE_PLUGIN_ROOT}/git-hooks' \
  "SKILL.md referencia git-hooks via \${CLAUDE_PLUGIN_ROOT}"

assert_lacks "$SKILL" '~/.rn-harness' \
  "SKILL.md sem referências a ~/.rn-harness (legado)"

assert_lacks "$SKILL" '~/.claude/templates' \
  "SKILL.md sem referências a ~/.claude/templates (legado)"

assert_has "$SKILL" 'package.json' \
  "SKILL.md menciona deteccao via package.json"
assert_has "$SKILL" 'STATE_MGMT' \
  "SKILL.md tem deteccao de state management"
assert_has "$SKILL" 'NAVIGATION' \
  "SKILL.md tem deteccao de navigation"
assert_has "$SKILL" 'BACKEND' \
  "SKILL.md tem deteccao de backend"
assert_has "$SKILL" 'VIDEO' \
  "SKILL.md tem deteccao de video"
assert_has "$SKILL" 'MONETIZATION' \
  "SKILL.md tem deteccao de monetizacao"
assert_has "$SKILL" 'expo install --fix' \
  "SKILL.md inclui expo install --fix"
assert_has "$SKILL" 'expo-video.md' \
  "SKILL.md referencia expo-video.md"
assert_has "$SKILL" 'NOTIFICATIONS' \
  "SKILL.md tem deteccao de notifications"
assert_has "$SKILL" 'revenue-cat.md' \
  "SKILL.md referencia revenue-cat.md"
assert_has "$SKILL" 'expo-notifications.md' \
  "SKILL.md referencia expo-notifications.md"
assert_has "$SKILL" 'seletivamente' \
  "SKILL.md copia rules seletivamente"
assert_has "$SKILL" 'settings.json' \
  "SKILL.md referencia settings.json"
assert_has "$SKILL" 'pre-tool-use.sh' \
  "SKILL.md referencia pre-tool-use.sh"

# settings.json conteúdo
assert_has "$REPO_DIR/templates/claude/settings.json" 'eas submit' \
  "settings.json bloqueia eas submit"
assert_has "$REPO_DIR/templates/claude/settings.json" 'deny' \
  "settings.json tem secao deny"
assert_has "$REPO_DIR/templates/claude/hooks/pre-tool-use.sh" 'BLOQUEADO' \
  "pre-tool-use.sh tem mensagem de bloqueio"
assert_has "$REPO_DIR/templates/claude/hooks/pre-tool-use.sh" 'supabase db reset' \
  "pre-tool-use.sh bloqueia supabase db reset"

assert_has "$REPO_DIR/templates/rules/expo-router.md" 'NativeTabs' \
  "expo-router.md tem secao NativeTabs"
assert_has "$REPO_DIR/templates/rules/expo-router.md" 'sfSymbol' \
  "expo-router.md tem pares SF Symbol"
assert_has "$REPO_DIR/templates/rules/expo-router.md" 'materialIcon' \
  "expo-router.md tem pares Material Icon"
assert_has "$REPO_DIR/templates/rules/expo-router.md" 'unstable-native-tabs' \
  "expo-router.md usa unstable-native-tabs"

assert_has "$SKILL" 'HOOK_PROFILE'   "SKILL.md referencia HOOK_PROFILE"
assert_has "$SKILL" 'CLAUDE_PLUGIN_DATA'   "SKILL.md le/grava .profile via CLAUDE_PLUGIN_DATA"
assert_has "$SKILL" 'profiles/'   "SKILL.md usa git-hooks/profiles/"

# ══════════════════════════════════════════════════════════════════════════
section "6. Doctor — estrutura e checks básicos"

DOCTOR="$REPO_DIR/scripts/doctor.sh"
DOCTOR_SKILL="$REPO_DIR/skills/rn-doctor/SKILL.md"

# Existência dos artefatos
assert_file "$DOCTOR"        "scripts/doctor.sh"
assert_exec "$DOCTOR"        "scripts/doctor.sh executável"
assert_file "$REPO_DIR/scripts/doctor.ps1" "scripts/doctor.ps1"
assert_file "$DOCTOR_SKILL"  "skills/rn-doctor/SKILL.md"

# doctor.sh: conteúdo estrutural
assert_has "$DOCTOR" 'node'   "doctor.sh checa node"
assert_has "$DOCTOR" 'tsconfig'   "doctor.sh checa tsconfig"
assert_has "$DOCTOR" 'babel'   "doctor.sh checa babel"
assert_has "$DOCTOR" 'no-color-literals'   "doctor.sh checa ESLint no-color-literals"
assert_has "$DOCTOR" 'expo-secure-store'   "doctor.sh checa expo-secure-store"
assert_has "$DOCTOR" 'core.hooksPath'   "doctor.sh checa git hooks"
assert_has "$DOCTOR" '\-\-json'   "doctor.sh suporta --json"
assert_lacks "$DOCTOR" 'expo-doctor'   "doctor.sh nao depende de expo-doctor externo"

# doctor.sh: exit 0 num projeto saudável mínimo
HEALTHY_DIR="$(mktemp -d)"
git init --quiet "$HEALTHY_DIR"
mkdir -p "$HEALTHY_DIR/.githooks" "$HEALTHY_DIR/.claude/rules"
git -C "$HEALTHY_DIR" config core.hooksPath .githooks
touch "$HEALTHY_DIR/.claude/rules/patterns.md"
cat > "$HEALTHY_DIR/package.json" <<'PKGJSON'
{
  "name": "test-app",
  "scripts": {
    "typecheck": "tsc --noEmit",
    "lint": "eslint . --max-warnings 0",
    "format:check": "prettier --check .",
    "fta": "fta-cli --score-cap 60 src/",
    "quality:full": "pnpm typecheck"
  },
  "dependencies": {
    "expo": "^56.0.0",
    "react-native": "0.76.0",
    "react-native-reanimated": "^3.0.0",
    "expo-secure-store": "^14.0.0"
  }
}
PKGJSON
echo ".env*" > "$HEALTHY_DIR/.gitignore"
echo '{"compilerOptions":{"strict":true}}' > "$HEALTHY_DIR/tsconfig.json"
printf 'module.exports={presets:["babel-preset-expo"],plugins:["react-native-reanimated/plugin"]}' > "$HEALTHY_DIR/babel.config.js"
printf '{"rules":{"react-native/no-color-literals":"error"}}' > "$HEALTHY_DIR/.eslintrc.json"
touch "$HEALTHY_DIR/CLAUDE.md"

actual=0
bash "$DOCTOR" "$HEALTHY_DIR" >/dev/null 2>&1 || actual=$?
[ "$actual" -eq 0 ]   && pass "doctor.sh exit 0 em projeto saudavel"   || fail "doctor.sh exit $actual em projeto saudavel (esperado 0)"
rm -rf "$HEALTHY_DIR"

# doctor.sh: exit 1 quando há FAIL (sem tsconfig)
SICK_DIR="$(mktemp -d)"
mkdir -p "$SICK_DIR/.git"
echo '{"name":"bad"}' > "$SICK_DIR/package.json"
actual=0
bash "$DOCTOR" "$SICK_DIR" >/dev/null 2>&1 || actual=$?
[ "$actual" -eq 1 ]   && pass "doctor.sh exit 1 em projeto com FAILs"   || fail "doctor.sh exit $actual em projeto doente (esperado 1)"
rm -rf "$SICK_DIR"

# doctor.sh: --json produz JSON válido
JSON_OUT=$(bash "$DOCTOR" --json "." 2>/dev/null || true)
echo "$JSON_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'ok' in d and 'fail' in d and 'results' in d" 2>/dev/null   && pass "doctor.sh --json produz JSON valido"   || fail "doctor.sh --json nao produz JSON valido"

# SKILL.md: conteúdo
assert_has "$DOCTOR_SKILL" '24'   "rn-doctor SKILL.md menciona 24 checks"
assert_has "$DOCTOR"       'lineHeight'   "doctor.sh checa lineHeight"
assert_has "$DOCTOR"       'expo-av'      "doctor.sh checa expo-av"
assert_has "$DOCTOR_SKILL" 'doctor.sh'   "rn-doctor SKILL.md referencia doctor.sh"
assert_has "$DOCTOR_SKILL" 'doctor.ps1'   "rn-doctor SKILL.md referencia doctor.ps1"

# ── sumário ───────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TOTAL=$((PASS + FAIL))
echo -e "${BOLD}Resultado: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC} / ${TOTAL} total${NC}"

if [ "${#ERRORS[@]}" -gt 0 ]; then
  echo ""
  echo -e "${RED}Falhas:${NC}"
  for e in "${ERRORS[@]}"; do
    echo "  • $e"
  done
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ "$FAIL" -eq 0 ]

#!/usr/bin/env bash
# tests/test.sh — plain bash tests para rn-harness
# Sem dependências externas. Roda: bash tests/test.sh
#
# Cobre:
#   1. Estrutura do repo (arquivos e permissões)
#   2. Install fresh (clone local + cópia)
#   3. Idempotência (2ª install não sobrescreve)
#   4. --force (sobrescreve)
#   5. Uninstall com 'y'
#   6. Uninstall cancelado com 'N'
#   7. Placeholder lint (CLAUDE.md.tmpl)
#   8. Placeholder lint (stubs)
#   9. Hooks — exit codes
#  10. SKILL.md — referências de path

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
assert_gone()  { [ ! -e "$1" ] && pass "${2:-$1} removido" || fail "${2:-$1} deveria ter sido removido"; }
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

TEST_CLAUDE="$TMPBASE/claude"
TEST_HARNESS="$TMPBASE/harness"
TEST_REMOTE="$TMPBASE/remote.git"
MOCK_BIN="$TMPBASE/bin"

mkdir -p "$TEST_CLAUDE/templates" "$TEST_CLAUDE/skills" "$MOCK_BIN"

# Repo local simulando o GitHub remote (bare clone)
git clone --bare --quiet "$REPO_DIR" "$TEST_REMOTE" 2>/dev/null

run_install() {
  RN_HARNESS_DIR="$TEST_HARNESS" \
  CLAUDE_CONFIG_DIR="$TEST_CLAUDE" \
  HARNESS_REMOTE="$TEST_REMOTE" \
  bash "$REPO_DIR/install.sh" "$@" 2>&1
}

run_uninstall() {
  RN_HARNESS_DIR="$TEST_HARNESS" \
  CLAUDE_CONFIG_DIR="$TEST_CLAUDE" \
  bash "$REPO_DIR/uninstall.sh" 2>&1
}

# ══════════════════════════════════════════════════════════════════════════
section "1. Estrutura do repo"

assert_file "$REPO_DIR/install.sh"                            "install.sh"
assert_file "$REPO_DIR/uninstall.sh"                          "uninstall.sh"
assert_file "$REPO_DIR/README.md"                             "README.md"
assert_dir  "$REPO_DIR/templates"                             "templates/"
assert_dir  "$REPO_DIR/templates/docs"                        "templates/docs/"
assert_dir  "$REPO_DIR/skills/new-rn-project"                 "skills/new-rn-project/"
assert_dir  "$REPO_DIR/hooks"                                 "hooks/"

assert_file "$REPO_DIR/templates/CLAUDE.md.tmpl"              "CLAUDE.md.tmpl"
assert_file "$REPO_DIR/templates/DECISIONS.md.stub"           "DECISIONS.md.stub"
assert_file "$REPO_DIR/templates/TODO.md.stub"                "TODO.md.stub"
assert_file "$REPO_DIR/skills/new-rn-project/SKILL.md"        "SKILL.md"
assert_file "$REPO_DIR/hooks/pre-commit.sh"                   "hooks/pre-commit.sh"
assert_file "$REPO_DIR/hooks/pre-push.sh"                     "hooks/pre-push.sh"

assert_exec "$REPO_DIR/install.sh"                            "install.sh executável"
assert_exec "$REPO_DIR/uninstall.sh"                          "uninstall.sh executável"
assert_exec "$REPO_DIR/hooks/pre-commit.sh"                   "pre-commit.sh executável"
assert_exec "$REPO_DIR/hooks/pre-push.sh"                     "pre-push.sh executável"

assert_file "$REPO_DIR/install.ps1"                           "install.ps1"
assert_file "$REPO_DIR/uninstall.ps1"                         "uninstall.ps1"
assert_file "$REPO_DIR/hooks/pre-commit.ps1"                  "hooks/pre-commit.ps1"
assert_file "$REPO_DIR/hooks/pre-push.ps1"                    "hooks/pre-push.ps1"
assert_file "$REPO_DIR/tests/test.ps1"                        "tests/test.ps1"

assert_dir  "$REPO_DIR/hooks/profiles/minimal"                "hooks/profiles/minimal/"
assert_dir  "$REPO_DIR/hooks/profiles/standard"               "hooks/profiles/standard/"
assert_dir  "$REPO_DIR/hooks/profiles/strict"                 "hooks/profiles/strict/"
for profile in minimal standard strict; do
  assert_file "$REPO_DIR/hooks/profiles/$profile/pre-commit.sh"  "profiles/$profile/pre-commit.sh"
  assert_file "$REPO_DIR/hooks/profiles/$profile/pre-push.sh"    "profiles/$profile/pre-push.sh"
  assert_file "$REPO_DIR/hooks/profiles/$profile/pre-commit.ps1" "profiles/$profile/pre-commit.ps1"
  assert_file "$REPO_DIR/hooks/profiles/$profile/pre-push.ps1"   "profiles/$profile/pre-push.ps1"
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
section "2. Fresh install"

run_install

assert_dir  "$TEST_HARNESS"                                           "harness clonado"
assert_dir  "$TEST_CLAUDE/templates/rn-20days"                        "templates dest"
assert_file "$TEST_CLAUDE/templates/rn-20days/CLAUDE.md.tmpl"         "CLAUDE.md.tmpl instalado"
assert_file "$TEST_CLAUDE/templates/rn-20days/DECISIONS.md.stub"       "DECISIONS.md.stub instalado"
assert_file "$TEST_CLAUDE/templates/rn-20days/TODO.md.stub"            "TODO.md.stub instalado"
assert_dir  "$TEST_CLAUDE/templates/rn-20days/docs"                   "docs/ instalado"
assert_dir  "$TEST_CLAUDE/skills/new-rn-project"                      "skill instalada"
assert_file "$TEST_CLAUDE/skills/new-rn-project/SKILL.md"             "SKILL.md instalado"

assert_dir  "$TEST_CLAUDE/templates/rn-20days/rules"                           "rules/ instalado"
assert_file "$TEST_CLAUDE/templates/rn-20days/rules/supabase.md"               "rules/supabase.md instalado"
assert_file "$TEST_CLAUDE/templates/rn-20days/rules/i18next.md"                "rules/i18next.md instalado"

for prefix in "01" "02" "03" "04" "05" "06"; do
  found=0
  for f in "$TEST_CLAUDE/templates/rn-20days/docs/${prefix}-"*.md; do
    [ -f "$f" ] && found=1 && break
  done
  [ "$found" -eq 1 ] \
    && pass "docs/${prefix}-*.md instalado" \
    || fail "docs/${prefix}-*.md ausente no destino"
done

# ══════════════════════════════════════════════════════════════════════════
section "3. Idempotência — 2ª install não sobrescreve"

echo "SENTINEL_IDEMPOTENCY" >> "$TEST_CLAUDE/templates/rn-20days/CLAUDE.md.tmpl"
run_install  # sem --force

assert_has "$TEST_CLAUDE/templates/rn-20days/CLAUDE.md.tmpl" \
  "SENTINEL_IDEMPOTENCY" \
  "CLAUDE.md.tmpl preservado na 2ª install"

# ══════════════════════════════════════════════════════════════════════════
section "4. --force sobrescreve"

run_install --force

assert_lacks "$TEST_CLAUDE/templates/rn-20days/CLAUDE.md.tmpl" \
  "SENTINEL_IDEMPOTENCY" \
  "CLAUDE.md.tmpl sobrescrito com --force"

# ══════════════════════════════════════════════════════════════════════════
section "5. Uninstall com 'y'"

echo "y" | run_uninstall

assert_gone "$TEST_CLAUDE/templates/rn-20days"    "templates/ removido"
assert_gone "$TEST_CLAUDE/skills/new-rn-project"  "skill removida"
assert_gone "$TEST_HARNESS"                        "harness dir removido"

# ══════════════════════════════════════════════════════════════════════════
section "6. Uninstall cancelado com 'N' não remove"

run_install >/dev/null  # re-instala para testar cancel

echo "N" | run_uninstall

assert_dir "$TEST_CLAUDE/templates/rn-20days"   "templates/ preservado após N"
assert_dir "$TEST_CLAUDE/skills/new-rn-project" "skill preservada após N"
assert_dir "$TEST_HARNESS"                       "harness dir preservado após N"

# ══════════════════════════════════════════════════════════════════════════
section "7. Placeholder lint — CLAUDE.md.tmpl"

TMPL="$REPO_DIR/templates/CLAUDE.md.tmpl"
SKILL="$REPO_DIR/skills/new-rn-project/SKILL.md"

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
section "8. Placeholder lint — stubs"

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
section "9. Hooks — exit codes"

# pnpm falha → pre-commit deve sair 1
cat > "$MOCK_BIN/pnpm" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$MOCK_BIN/pnpm"

run_exit 1 "pre-commit sai 1 quando pnpm falha" \
  env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/hooks/pre-commit.sh"

# pnpm passa → pre-commit deve sair 0
cat > "$MOCK_BIN/pnpm" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$MOCK_BIN/pnpm"

run_exit 0 "pre-commit sai 0 quando pnpm passa" \
  env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/hooks/pre-commit.sh"

# pre-push: resposta N → sai 1
actual=0
(echo "N" | env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/hooks/pre-push.sh" >/dev/null 2>&1) || actual=$?
[ "$actual" -eq 1 ] \
  && pass "pre-push sai 1 com resposta N" \
  || fail "pre-push sai $actual com resposta N (esperado 1)"

# pre-push: resposta y → sai 0
actual=0
(echo "y" | env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/hooks/pre-push.sh" >/dev/null 2>&1) || actual=$?
[ "$actual" -eq 0 ] \
  && pass "pre-push sai 0 com resposta y" \
  || fail "pre-push sai $actual com resposta y (esperado 0)"

# ══════════════════════════════════════════════════════════════════════════
section "9b. Profiles — install salva .profile e hooks corretos"

# Default install -> .profile = "strict"
run_install >/dev/null 2>&1
profile_val="$(cat "$TEST_HARNESS/.profile" 2>/dev/null || echo "")"
[ "$profile_val" = "strict" ]   && pass ".profile = strict apos install padrao"   || fail ".profile esperado strict, obtido '$profile_val'"

# Minimal pre-commit nao deve ter 'fta'
assert_lacks "$TEST_HARNESS/hooks/profiles/minimal/pre-commit.sh"   "fta" "minimal/pre-commit.sh sem fta"

# Minimal pre-commit deve ter apenas typecheck
assert_has "$TEST_HARNESS/hooks/profiles/minimal/pre-commit.sh"   "typecheck" "minimal/pre-commit.sh tem typecheck"

# Strict pre-commit deve ter fta
assert_has "$TEST_HARNESS/hooks/profiles/strict/pre-commit.sh"   "fta" "strict/pre-commit.sh tem fta"

# Standard pre-commit: tem lint, nao tem fta
assert_has   "$TEST_HARNESS/hooks/profiles/standard/pre-commit.sh"   "lint" "standard/pre-commit.sh tem lint"
assert_lacks "$TEST_HARNESS/hooks/profiles/standard/pre-commit.sh"   "fta" "standard/pre-commit.sh sem fta"

# --profile minimal -> .profile = "minimal"
run_install --profile minimal >/dev/null 2>&1
profile_val="$(cat "$TEST_HARNESS/.profile" 2>/dev/null || echo "")"
[ "$profile_val" = "minimal" ]   && pass ".profile = minimal apos --profile minimal"   || fail ".profile esperado minimal, obtido '$profile_val'"

# --profile standard -> .profile = "standard"
run_install --profile standard >/dev/null 2>&1
profile_val="$(cat "$TEST_HARNESS/.profile" 2>/dev/null || echo "")"
[ "$profile_val" = "standard" ]   && pass ".profile = standard apos --profile standard"   || fail ".profile esperado standard, obtido '$profile_val'"

# ══════════════════════════════════════════════════════════════════════════
section "10. SKILL.md — referências de path"

assert_has "$SKILL" "~/.claude/templates/rn-20days" \
  "SKILL.md referencia path correto de templates"

assert_has "$SKILL" "~/.rn-harness/hooks" \
  "SKILL.md referencia path correto de hooks"

assert_has "$SKILL" "~/.claude/skills/new-rn-project" \
  "SKILL.md referencia path correto da skill"

# install.sh deve usar HARNESS_REMOTE env var (não URL hardcoded nos if/else)
assert_has "$REPO_DIR/install.sh" 'HARNESS_REMOTE' \
  "install.sh usa variável HARNESS_REMOTE"

assert_lacks "$REPO_DIR/install.sh" 'ls-remote git@github' \
  "install.sh sem URL hardcoded no ls-remote"

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
assert_has "$SKILL" 'seletivamente' \
  "SKILL.md copia rules seletivamente"

assert_has "$SKILL" 'HOOK_PROFILE'   "SKILL.md referencia HOOK_PROFILE"
assert_has "$SKILL" '.rn-harness/.profile'   "SKILL.md le .profile do harness"
assert_has "$SKILL" 'profiles/'   "SKILL.md usa hooks/profiles/"

# ══════════════════════════════════════════════════════════════════════════
section "11. Doctor — estrutura e checks básicos"

DOCTOR="$REPO_DIR/scripts/doctor.sh"
DOCTOR_SKILL="$REPO_DIR/skills/rn-doctor/SKILL.md"

# Existência dos artefatos
assert_file "$DOCTOR"        "scripts/doctor.sh"
assert_exec "$DOCTOR"        "scripts/doctor.sh executável"
assert_file "$REPO_DIR/scripts/doctor.ps1" "scripts/doctor.ps1"
assert_file "$DOCTOR_SKILL"  "skills/rn-doctor/SKILL.md"

# install.sh menciona doctor e rn-doctor
assert_has "$REPO_DIR/install.sh" 'rn-doctor'   "install.sh instala skill rn-doctor"
assert_has "$REPO_DIR/install.sh" 'scripts/'   "install.sh referencia scripts/"

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

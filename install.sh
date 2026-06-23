#!/usr/bin/env bash
# rn-harness installer
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/jujubalandia/rn-harness/main/install.sh | sh
#
#   ou clone manual:
#   git clone git@github.com:jujubalandia/rn-harness.git ~/.rn-harness && ~/.rn-harness/install.sh

set -e

HARNESS_DIR="${RN_HARNESS_DIR:-$HOME/.rn-harness}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
HARNESS_REMOTE="${HARNESS_REMOTE:-git@github.com:Jujubalandia/rn-harness.git}"
TEMPLATES_DEST="$CLAUDE_DIR/templates/rn-20days"
SKILLS_DEST="$CLAUDE_DIR/skills"
FORCE=""
PROFILE="strict"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)   FORCE="--force"; shift ;;
    --profile) PROFILE="$2";   shift 2 ;;
    *)         shift ;;
  esac
done

case "$PROFILE" in
  minimal|standard|strict) ;;
  *) echo "ERRO: --profile deve ser minimal, standard ou strict"; exit 1 ;;
esac

echo "rn-harness installer"
echo "===================="
echo ""

# --- 1. Obter o repo ---

if [ -d "$HARNESS_DIR/.git" ]; then
  echo "→ Atualizando $HARNESS_DIR..."
  git -C "$HARNESS_DIR" pull --ff-only --quiet
else
  # Se rodando via curl | sh, o repo ainda não existe localmente
  # Tentar clonar. Se não tiver acesso SSH, instruir o usuário.
  if git ls-remote "$HARNESS_REMOTE" HEAD >/dev/null 2>&1; then
    echo "→ Clonando rn-harness em $HARNESS_DIR..."
    git clone --quiet "$HARNESS_REMOTE" "$HARNESS_DIR"
  else
    echo "❌ Sem acesso ao repo $HARNESS_REMOTE"
    echo "   Clone manualmente:"
    echo "   git clone git@github.com:Jujubalandia/rn-harness.git $HARNESS_DIR"
    echo "   $HARNESS_DIR/install.sh"
    exit 1
  fi
fi

# --- 1b. Salvar perfil selecionado ---

echo "$PROFILE" > "$HARNESS_DIR/.profile"

# --- 2. Templates → ~/.claude/templates/rn-20days/ ---

mkdir -p "$TEMPLATES_DEST/docs" "$TEMPLATES_DEST/rules"

if [ "$FORCE" = "--force" ]; then
  echo "→ Copiando templates (--force: sobrescrevendo)..."
  cp -rf "$HARNESS_DIR/templates/." "$TEMPLATES_DEST/"
else
  echo "→ Copiando templates (pula arquivos existentes)..."
  cp -rn "$HARNESS_DIR/templates/." "$TEMPLATES_DEST/" 2>/dev/null || true
fi

# --- 3. Scripts — garantir exec bit ---

chmod +x "$HARNESS_DIR/scripts/"*.sh 2>/dev/null || true

# --- 4. Skills → ~/.claude/skills/ ---

mkdir -p "$SKILLS_DEST"
for skill in new-rn-project rn-doctor; do
  if [ -d "$SKILLS_DEST/$skill" ] && [ "$FORCE" != "--force" ]; then
    echo "→ Skill $skill já existe (pular — use --force para atualizar)"
  else
    echo "→ Instalando skill $skill..."
    if [ "$FORCE" = "--force" ]; then
      cp -rf "$HARNESS_DIR/skills/$skill/" "$SKILLS_DEST/$skill/"
    else
      cp -rn "$HARNESS_DIR/skills/$skill/" "$SKILLS_DEST/$skill/" 2>/dev/null || true
    fi
  fi
done

# --- 5. Resultado ---

echo ""
echo "✅ rn-harness instalado"
echo "   Repo:      $HARNESS_DIR"
echo "   Templates: $TEMPLATES_DEST"
echo "   Skills:    $SKILLS_DEST/new-rn-project, $SKILLS_DEST/rn-doctor"
echo "   Doctor:    $HARNESS_DIR/scripts/doctor.sh"
echo "   Perfil:    $PROFILE (hooks)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PRÓXIMOS PASSOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Novo projeto:"
echo "   mkdir ~/projects/meu-app && cd ~/projects/meu-app"
echo "   claude  ← abrir Claude Code e digitar /new-rn-project"
echo ""
echo "2. Skills de marketplace (instalar se ainda não tiver):"
echo "   Abrir Claude Code e verificar com /find-skills ou:"
echo "   - firecrawl-search, firecrawl-scrape  (firecrawl MCP — D1-D2)"
echo "   - design-token-guardian, i18n-validator  (D3+)"
echo "   - expo-debugger, auth-assessment, secure-storage-audit, supabase-migrator  (D4+)"
echo "   - code-review  (pre-commit)"
echo "   - qa-tester, store-metadata-reviewer  (D13-D15)"
echo "   - marketing-copywriter, viral-content-strategist  (D17-D18)"
echo "   - privacy-audit  (pós-D20)"
echo ""
echo "3. Atualizar depois:"
echo "   $HARNESS_DIR/install.sh                          ← atualiza sem sobrescrever"
echo "   $HARNESS_DIR/install.sh --force                   ← força atualização dos templates"
echo "   $HARNESS_DIR/install.sh --profile minimal         ← muda perfil de hooks"
echo "   $HARNESS_DIR/install.sh --profile standard        ← muda perfil de hooks"
echo "   $HARNESS_DIR/install.sh --profile strict          ← muda perfil de hooks (padrão)"
echo ""

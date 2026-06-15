#!/usr/bin/env bash
# rn-harness uninstaller
set -e

HARNESS_DIR="${RN_HARNESS_DIR:-$HOME/.rn-harness}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

echo "rn-harness uninstaller"
echo "======================"
echo ""
echo "Isso vai remover:"
echo "  - $CLAUDE_DIR/templates/rn-20days/"
echo "  - $CLAUDE_DIR/skills/new-rn-project/"
echo "  - $HARNESS_DIR/"
echo ""
printf "Confirmar? [y/N] "
read -r answer
case "$answer" in
  y|Y) ;;
  *) echo "Cancelado."; exit 0 ;;
esac

rm -rf "$CLAUDE_DIR/templates/rn-20days/"
rm -rf "$CLAUDE_DIR/skills/new-rn-project/"
rm -rf "$HARNESS_DIR/"

echo ""
echo "✅ rn-harness removido."
echo "   Projetos existentes não foram afetados."

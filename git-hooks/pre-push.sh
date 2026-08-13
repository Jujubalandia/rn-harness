#!/bin/sh
# rn-harness pre-push hook
set -e

echo "→ quality:full..."
pnpm quality:full

echo ""
printf "Testou no Android físico? [y/N] "
read -r answer
case "$answer" in
  y|Y) echo "✅ push liberado" ;;
  *)   echo "❌ Teste no Android físico antes de push."; exit 1 ;;
esac

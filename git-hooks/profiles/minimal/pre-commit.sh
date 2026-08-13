#!/bin/sh
# rn-harness pre-commit — perfil minimal (typecheck somente)
set -e
echo "-> typecheck..."
pnpm typecheck
echo "OK pre-commit passed [minimal]"

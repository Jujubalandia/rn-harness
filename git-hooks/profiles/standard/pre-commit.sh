#!/bin/sh
# rn-harness pre-commit — perfil standard (typecheck + lint + format)
set -e
echo "-> typecheck..."
pnpm typecheck
echo "-> lint..."
pnpm lint
echo "-> format..."
pnpm format:check
echo "OK pre-commit passed [standard]"

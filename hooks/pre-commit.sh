#!/bin/sh
# rn-harness pre-commit hook
# Instalar: git config core.hooksPath .githooks
set -e

echo "→ typecheck..."
pnpm typecheck

echo "→ lint..."
pnpm lint

echo "→ format..."
pnpm format:check

echo "→ fta (score cap: 60)..."
pnpm fta

echo "✅ pre-commit passed"

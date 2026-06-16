#Requires -Version 5.1
# rn-harness pre-commit hook (PowerShell)
# Ativar: git config core.hooksPath .githooks
# Nota: git não executa .ps1 diretamente — use os hooks .sh via Git for Windows.
#       Este arquivo serve para rodar manualmente ou via testes.
$ErrorActionPreference = 'Stop'

Write-Host "-> typecheck..."
pnpm typecheck
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "-> lint..."
pnpm lint
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "-> format..."
pnpm format:check
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "-> fta (score cap: 60)..."
pnpm fta
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "OK pre-commit passed"

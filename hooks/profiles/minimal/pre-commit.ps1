#Requires -Version 5.1
# rn-harness pre-commit — perfil minimal (typecheck somente)
$ErrorActionPreference = 'Stop'
Write-Host "-> typecheck..."
pnpm typecheck
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "OK pre-commit passed [minimal]"

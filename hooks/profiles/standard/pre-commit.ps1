#Requires -Version 5.1
# rn-harness pre-commit — perfil standard (typecheck + lint + format)
$ErrorActionPreference = 'Stop'
Write-Host "-> typecheck..."; pnpm typecheck; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "-> lint...";      pnpm lint;      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "-> format...";    pnpm format:check; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "OK pre-commit passed [standard]"

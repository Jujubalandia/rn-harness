#Requires -Version 5.1
# rn-harness pre-push — perfil standard (quality:full + Android)
$ErrorActionPreference = 'Stop'
Write-Host "-> quality:full..."
pnpm quality:full
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$ans = if ($env:HARNESS_ANDROID_OK) { $env:HARNESS_ANDROID_OK } else { Read-Host "Testou no Android fisico? [y/N]" }
if ($ans -notmatch '^[yY]$') { Write-Host "ERRO: Teste no Android fisico antes de push."; exit 1 }
Write-Host "OK push liberado [standard]"

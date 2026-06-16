#Requires -Version 5.1
# rn-harness pre-push hook (PowerShell)
$ErrorActionPreference = 'Stop'

Write-Host "-> quality:full..."
pnpm quality:full

$ans = if ($env:HARNESS_ANDROID_OK) {
    $env:HARNESS_ANDROID_OK
} else {
    Read-Host "Testou no Android fisico? [y/N]"
}

if ($ans -notmatch '^[yY]$') {
    Write-Host "ERRO: Teste no Android fisico antes de push."
    exit 1
}
Write-Host "OK push liberado"

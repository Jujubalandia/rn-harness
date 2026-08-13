#Requires -Version 5.1
# rn-harness uninstaller (PowerShell)
[CmdletBinding()] param()
$ErrorActionPreference = 'Stop'

$HarnessDir = if ($env:RN_HARNESS_DIR)    { $env:RN_HARNESS_DIR }    else { "$env:USERPROFILE\.rn-harness" }
$ClaudeDir  = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { "$env:USERPROFILE\.claude" }

Write-Host "rn-harness uninstaller"
Write-Host "======================"
Write-Host ""
Write-Host "Isso vai remover:"
Write-Host "  - $ClaudeDir\templates\rn-20days\"
Write-Host "  - $ClaudeDir\skills\new-rn-project\"
Write-Host "  - $ClaudeDir\skills\rn-doctor\"
Write-Host "  - $HarnessDir\"
Write-Host ""

$confirm = if ($env:HARNESS_CONFIRM) {
    $env:HARNESS_CONFIRM
} else {
    Read-Host "Confirmar? [y/N]"
}

if ($confirm -notmatch '^[yY]$') {
    Write-Host "Cancelado."
    exit 0
}

$targets = @(
    "$ClaudeDir\templates\rn-20days",
    "$ClaudeDir\skills\new-rn-project",
    "$ClaudeDir\skills\rn-doctor",
    $HarnessDir
)
foreach ($t in $targets) {
    if (Test-Path $t) {
        Remove-Item -Recurse -Force $t
    }
}

Write-Host ""
Write-Host "OK rn-harness removido."
Write-Host "   Projetos existentes nao foram afetados."

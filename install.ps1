#Requires -Version 5.1
# rn-harness installer (PowerShell)
#
# Uso:
#   git clone git@github.com:Jujubalandia/rn-harness.git $env:USERPROFILE\.rn-harness
#   & "$env:USERPROFILE\.rn-harness\install.ps1"
#
#   Atualizar sem sobrescrever:  & "$env:USERPROFILE\.rn-harness\install.ps1"
#   Forcar update dos templates:  & "$env:USERPROFILE\.rn-harness\install.ps1" -Force
[CmdletBinding()]
param(
    [switch]$Force,
    [ValidateSet("minimal","standard","strict")][string]$Profile = "strict"
)
$ErrorActionPreference = 'Stop'

$HarnessDir    = if ($env:RN_HARNESS_DIR)    { $env:RN_HARNESS_DIR }    else { "$env:USERPROFILE\.rn-harness" }
$ClaudeDir     = if ($env:CLAUDE_CONFIG_DIR)  { $env:CLAUDE_CONFIG_DIR } else { "$env:USERPROFILE\.claude" }
$HarnessRemote = if ($env:HARNESS_REMOTE)     { $env:HARNESS_REMOTE }    else { "git@github.com:Jujubalandia/rn-harness.git" }
$TemplatesDest = Join-Path $ClaudeDir "templates\rn-20days"
$SkillsDest    = Join-Path $ClaudeDir "skills"

Write-Host "rn-harness installer (PowerShell)"
Write-Host "=================================="
Write-Host ""

# --- Helpers ---

function Copy-NoClob([string]$Src, [string]$Dest) {
    # Equivalente a cp -rn: copia somente arquivos que nao existem no destino
    Get-ChildItem -Recurse -File $Src | ForEach-Object {
        $rel = $_.FullName.Substring($Src.TrimEnd('\','/').Length).TrimStart('\','/')
        $dst = Join-Path $Dest $rel
        if (-not (Test-Path $dst -PathType Leaf)) {
            $dstDir = Split-Path $dst -Parent
            New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
            Copy-Item $_.FullName $dst
        }
    }
}

# --- 1. Obter o repo ---

if (Test-Path (Join-Path $HarnessDir ".git") -PathType Container) {
    Write-Host "-> Atualizando $HarnessDir..."
    git -C $HarnessDir pull --ff-only --quiet
    if ($LASTEXITCODE -ne 0) { Write-Error "git pull falhou"; exit 1 }
} else {
    Write-Host "-> Verificando acesso ao repo..."
    git ls-remote $HarnessRemote HEAD 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "-> Clonando rn-harness em $HarnessDir..."
        git clone --quiet $HarnessRemote $HarnessDir
        if ($LASTEXITCODE -ne 0) { Write-Error "git clone falhou"; exit 1 }
    } else {
        Write-Host "ERRO: Sem acesso ao repo $HarnessRemote"
        Write-Host "   Clone manualmente:"
        Write-Host "   git clone git@github.com:Jujubalandia/rn-harness.git $HarnessDir"
        Write-Host "   & `"$HarnessDir\install.ps1`""
        exit 1
    }
}

# --- 1b. Salvar perfil selecionado ---

$Profile | Set-Content (Join-Path $HarnessDir ".profile") -Encoding UTF8

# --- 2. Templates -> $TemplatesDest ---

New-Item -ItemType Directory -Force -Path (Join-Path $TemplatesDest "docs") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $TemplatesDest "rules") | Out-Null
$templatesSrc = Join-Path $HarnessDir "templates"

if ($Force) {
    Write-Host "-> Copiando templates (-Force: sobrescrevendo)..."
    Copy-Item -Recurse -Force "$templatesSrc\*" $TemplatesDest
} else {
    Write-Host "-> Copiando templates (pula arquivos existentes)..."
    Copy-NoClob $templatesSrc $TemplatesDest
}

# --- 3. Skills -> $SkillsDest ---

New-Item -ItemType Directory -Force -Path $SkillsDest | Out-Null
foreach ($skill in @("new-rn-project","rn-doctor")) {
    $skillSrc  = Join-Path $HarnessDir "skills\$skill"
    $skillDest = Join-Path $SkillsDest $skill
    if ((Test-Path $skillDest -PathType Container) -and -not $Force) {
        Write-Host "-> Skill $skill ja existe (pular -- use -Force para atualizar)"
    } else {
        Write-Host "-> Instalando skill $skill..."
        if ($Force -and (Test-Path $skillDest)) { Remove-Item -Recurse -Force $skillDest }
        if (-not (Test-Path $skillDest)) { Copy-Item -Recurse $skillSrc $skillDest }
    }
}

# --- 4. Resultado ---

Write-Host ""
Write-Host "OK rn-harness instalado"
Write-Host "   Repo:      $HarnessDir"
Write-Host "   Templates: $TemplatesDest"
Write-Host "   Skills:    $(Join-Path $SkillsDest 'new-rn-project'), rn-doctor"
Write-Host "   Doctor:    $(Join-Path $HarnessDir 'scripts\doctor.ps1')"
Write-Host "   Perfil:    $Profile (hooks)"
Write-Host ""
Write-Host "========================================"
Write-Host "PROXIMOS PASSOS"
Write-Host "========================================"
Write-Host ""
Write-Host "1. Novo projeto:"
Write-Host "   mkdir `"`$env:USERPROFILE\projects\meu-app`" ; cd `"`$env:USERPROFILE\projects\meu-app`""
Write-Host "   claude  <- abrir Claude Code e digitar /new-rn-project"
Write-Host ""
Write-Host "2. Skills de marketplace (instalar se nao tiver):"
Write-Host "   - react-native-best-practices  (callstack marketplace)"
Write-Host "   - zafer-skills                 (thedotmack marketplace)"
Write-Host "   - expo-debugger, design-token-guardian, i18n-validator"
Write-Host "   - store-metadata-reviewer, qa-tester"
Write-Host "   - marketing-copywriter, viral-content-strategist"
Write-Host "   - supabase-migrator"
Write-Host ""
Write-Host "3. Atualizar depois:"
Write-Host "   & `"$HarnessDir\install.ps1`"                        <- sem sobrescrever"
Write-Host "   & `"$HarnessDir\install.ps1`" -Force                 <- forca update dos templates"
Write-Host "   & `"$HarnessDir\install.ps1`" -Profile minimal      <- muda perfil de hooks"
Write-Host "   & `"$HarnessDir\install.ps1`" -Profile standard     <- muda perfil de hooks"
Write-Host "   & `"$HarnessDir\install.ps1`" -Profile strict       <- muda perfil de hooks (padrao)"
Write-Host ""

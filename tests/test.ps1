#Requires -Version 5.1
# tests/test.ps1 — suite de testes PowerShell para rn-harness
# Roda: powershell -File tests\test.ps1
#
# Cobre:
#   1. Estrutura do repo (arquivos)
#   2. Install fresh (clone local + copia)
#   3. Idempotencia (2a install nao sobrescreve)
#   4. -Force (sobrescreve)
#   5. Uninstall com 'y'
#   6. Uninstall cancelado com 'N'
#   7. Placeholder lint (CLAUDE.md.tmpl)
#   8. Placeholder lint (stubs)
#   9. Hooks PS1 — exit codes
#  10. SKILL.md — referencias de path

$ErrorActionPreference = 'Stop'

$RepoDir = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
$Pass = 0; $Fail = 0; [string[]]$Errors = @()

# ── helpers ──────────────────────────────────────────────────────────────────

function Pass([string]$Label) {
    Write-Host "  OK $Label" -ForegroundColor Green
    $script:Pass++
}
function Fail([string]$Label) {
    Write-Host "  FAIL $Label" -ForegroundColor Red
    $script:Fail++
    $script:Errors += $Label
}
function Section([string]$Title) {
    Write-Host ""
    Write-Host $Title -ForegroundColor White
}

function Assert-File([string]$Path, [string]$Label = '') {
    $lbl = if ($Label) { $Label } else { $Path }
    if (Test-Path $Path -PathType Leaf) { Pass $lbl } else { Fail "$lbl -- arquivo ausente" }
}
function Assert-Dir([string]$Path, [string]$Label = '') {
    $lbl = if ($Label) { $Label } else { $Path }
    if (Test-Path $Path -PathType Container) { Pass $lbl } else { Fail "$lbl -- dir ausente" }
}
function Assert-Gone([string]$Path, [string]$Label) {
    if (-not (Test-Path $Path)) { Pass "$Label removido" } else { Fail "$Label deveria ter sido removido" }
}
function Assert-Has([string]$Path, [string]$Pattern, [string]$Label) {
    if (Select-String -Quiet -Pattern $Pattern -Path $Path -ErrorAction SilentlyContinue) {
        Pass $Label
    } else {
        Fail $Label
    }
}
function Assert-Lacks([string]$Path, [string]$Pattern, [string]$Label) {
    if (-not (Select-String -Quiet -Pattern $Pattern -Path $Path -ErrorAction SilentlyContinue)) {
        Pass $Label
    } else {
        Fail $Label
    }
}

# ── ambiente temporario ───────────────────────────────────────────────────────

$TmpBase   = [IO.Path]::Combine($env:TEMP, [Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $TmpBase | Out-Null

$TestClaude  = Join-Path $TmpBase "claude"
$TestHarness = Join-Path $TmpBase "harness"
$TestRemote  = Join-Path $TmpBase "remote.git"
$MockBin     = Join-Path $TmpBase "bin"

New-Item -ItemType Directory -Force -Path "$TestClaude\templates" | Out-Null
New-Item -ItemType Directory -Force -Path "$TestClaude\skills"    | Out-Null
New-Item -ItemType Directory -Force -Path $MockBin                | Out-Null

# Bare clone local simulando o GitHub remote
git clone --bare --quiet $RepoDir $TestRemote 2>$null
if ($LASTEXITCODE -ne 0) { throw "git clone --bare falhou" }

# ── funcoes de invocacao (sempre em processo filho) ───────────────────────────

function Invoke-Install([switch]$Force, [string]$ProfileArg = "") {
    $env:RN_HARNESS_DIR    = $TestHarness
    $env:CLAUDE_CONFIG_DIR = $TestClaude
    $env:HARNESS_REMOTE    = $TestRemote
    try {
        if ($Force) {
            powershell -NoProfile -File "$RepoDir\install.ps1" -Force *>$null
        } elseif ($ProfileArg) {
            powershell -NoProfile -File "$RepoDir\install.ps1" -Profile $ProfileArg *>$null
        } else {
            powershell -NoProfile -File "$RepoDir\install.ps1" *>$null
        }
        return $LASTEXITCODE
    } finally {
        Remove-Item Env:RN_HARNESS_DIR    -ErrorAction SilentlyContinue
        Remove-Item Env:CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue
        Remove-Item Env:HARNESS_REMOTE    -ErrorAction SilentlyContinue
    }
}

function Invoke-Uninstall([string]$Confirm) {
    $env:RN_HARNESS_DIR    = $TestHarness
    $env:CLAUDE_CONFIG_DIR = $TestClaude
    $env:HARNESS_CONFIRM   = $Confirm
    try {
        powershell -NoProfile -File "$RepoDir\uninstall.ps1" *>$null
        return $LASTEXITCODE
    } finally {
        Remove-Item Env:RN_HARNESS_DIR    -ErrorAction SilentlyContinue
        Remove-Item Env:CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue
        Remove-Item Env:HARNESS_CONFIRM   -ErrorAction SilentlyContinue
    }
}

try {

# ══════════════════════════════════════════════════════════════════════════════
Section "1. Estrutura do repo"

Assert-File "$RepoDir\install.sh"                             "install.sh"
Assert-File "$RepoDir\install.ps1"                            "install.ps1"
Assert-File "$RepoDir\uninstall.sh"                           "uninstall.sh"
Assert-File "$RepoDir\uninstall.ps1"                          "uninstall.ps1"
Assert-File "$RepoDir\README.md"                              "README.md"
Assert-Dir  "$RepoDir\templates"                              "templates\"
Assert-Dir  "$RepoDir\templates\docs"                         "templates\docs\"
Assert-Dir  "$RepoDir\skills\new-rn-project"                  "skills\new-rn-project\"
Assert-Dir  "$RepoDir\hooks"                                  "hooks\"

Assert-File "$RepoDir\templates\CLAUDE.md.tmpl"               "CLAUDE.md.tmpl"
Assert-File "$RepoDir\templates\DECISIONS.md.stub"            "DECISIONS.md.stub"
Assert-File "$RepoDir\templates\TODO.md.stub"                 "TODO.md.stub"
Assert-File "$RepoDir\skills\new-rn-project\SKILL.md"         "SKILL.md"
Assert-File "$RepoDir\hooks\pre-commit.sh"                    "hooks\pre-commit.sh"
Assert-File "$RepoDir\hooks\pre-push.sh"                      "hooks\pre-push.sh"
Assert-File "$RepoDir\hooks\pre-commit.ps1"                   "hooks\pre-commit.ps1"
Assert-File "$RepoDir\hooks\pre-push.ps1"                     "hooks\pre-push.ps1"
Assert-File "$RepoDir\tests\test.ps1"                         "tests\test.ps1"

foreach ($prof in "minimal","standard","strict") {
    Assert-Dir  "$RepoDir\hooks\profiles\$prof"                   "profiles\$prof\"
    Assert-File "$RepoDir\hooks\profiles\$prof\pre-commit.sh"    "profiles\$prof\pre-commit.sh"
    Assert-File "$RepoDir\hooks\profiles\$prof\pre-push.sh"      "profiles\$prof\pre-push.sh"
    Assert-File "$RepoDir\hooks\profiles\$prof\pre-commit.ps1"   "profiles\$prof\pre-commit.ps1"
    Assert-File "$RepoDir\hooks\profiles\$prof\pre-push.ps1"     "profiles\$prof\pre-push.ps1"
}

Assert-Dir  "$RepoDir\templates\rules"                              "templates\\rules\\"
Assert-File "$RepoDir\templates\rules\react-native-reanimated.md"  "rules\\reanimated.md"
Assert-File "$RepoDir\templates\rules\expo-router.md"              "rules\\expo-router.md"
Assert-File "$RepoDir\templates\rules\supabase.md"                 "rules\\supabase.md"
Assert-File "$RepoDir\templates\rules\i18next.md"                  "rules\\i18next.md"
Assert-File "$RepoDir\templates\rules\zustand.md"                  "rules\\zustand.md"
Assert-File "$RepoDir\templates\rules\patterns.md"                 "rules\\patterns.md"
Assert-File "$RepoDir\templates\rules\performance.md"              "rules\\performance.md"
Assert-File "$RepoDir\templates\rules\security.md"                 "rules\\security.md"
Assert-File "$RepoDir\templates\rules\accessibility.md"            "rules\\accessibility.md"
Assert-File "$RepoDir\templates\rules\styling.md"                  "rules\\styling.md"
Assert-File "$RepoDir\templates\rules\react-native-gesture-handler.md" "rules\\gesture-handler.md"

foreach ($prefix in "01","02","03","04","05","06") {
    $found = Get-ChildItem "$RepoDir\templates\docs\${prefix}-*.md" -ErrorAction SilentlyContinue
    if ($found) { Pass "templates\docs\${prefix}-*.md" } else { Fail "templates\docs\${prefix}-*.md ausente" }
}

# ══════════════════════════════════════════════════════════════════════════════
Section "2. Fresh install"

Invoke-Install | Out-Null

Assert-Dir  $TestHarness                                                        "harness clonado"
Assert-Dir  "$TestClaude\templates\rn-20days"                                   "templates dest"
Assert-File "$TestClaude\templates\rn-20days\CLAUDE.md.tmpl"                    "CLAUDE.md.tmpl instalado"
Assert-File "$TestClaude\templates\rn-20days\DECISIONS.md.stub"                 "DECISIONS.md.stub instalado"
Assert-File "$TestClaude\templates\rn-20days\TODO.md.stub"                      "TODO.md.stub instalado"
Assert-Dir  "$TestClaude\templates\rn-20days\docs"                              "docs\ instalado"
Assert-Dir  "$TestClaude\skills\new-rn-project"                                 "skill instalada"
Assert-File "$TestClaude\skills\new-rn-project\SKILL.md"                        "SKILL.md instalado"
Assert-Dir  "$TestClaude\templates\rn-20days\rules"                                   "rules\\ instalado"
Assert-File "$TestClaude\templates\rn-20days\rules\supabase.md"                      "rules\\supabase.md instalado"
Assert-File "$TestClaude\templates\rn-20days\rules\i18next.md"                       "rules\\i18next.md instalado"

foreach ($prefix in "01","02","03","04","05","06") {
    $found = Get-ChildItem "$TestClaude\templates\rn-20days\docs\${prefix}-*.md" -ErrorAction SilentlyContinue
    if ($found) { Pass "docs\${prefix}-*.md instalado" } else { Fail "docs\${prefix}-*.md ausente no destino" }
}

# ══════════════════════════════════════════════════════════════════════════════
Section "3. Idempotencia -- 2a install nao sobrescreve"

Add-Content "$TestClaude\templates\rn-20days\CLAUDE.md.tmpl" "SENTINEL_IDEMPOTENCY"
Invoke-Install | Out-Null

Assert-Has "$TestClaude\templates\rn-20days\CLAUDE.md.tmpl" `
    "SENTINEL_IDEMPOTENCY" `
    "CLAUDE.md.tmpl preservado na 2a install"

# ══════════════════════════════════════════════════════════════════════════════
Section "4. -Force sobrescreve"

Invoke-Install -Force | Out-Null

Assert-Lacks "$TestClaude\templates\rn-20days\CLAUDE.md.tmpl" `
    "SENTINEL_IDEMPOTENCY" `
    "CLAUDE.md.tmpl sobrescrito com -Force"

# ══════════════════════════════════════════════════════════════════════════════
Section "5. Uninstall com 'y'"

Invoke-Uninstall -Confirm 'y' | Out-Null

Assert-Gone "$TestClaude\templates\rn-20days"   "templates\ removido"
Assert-Gone "$TestClaude\skills\new-rn-project" "skill removida"
Assert-Gone $TestHarness                         "harness dir removido"

# ══════════════════════════════════════════════════════════════════════════════
Section "6. Uninstall cancelado com 'N' nao remove"

Invoke-Install | Out-Null  # re-instala para testar cancel
Invoke-Uninstall -Confirm 'N' | Out-Null

Assert-Dir "$TestClaude\templates\rn-20days"    "templates\ preservado apos N"
Assert-Dir "$TestClaude\skills\new-rn-project"  "skill preservada apos N"
Assert-Dir $TestHarness                          "harness dir preservado apos N"

# ══════════════════════════════════════════════════════════════════════════════
Section "7. Placeholder lint -- CLAUDE.md.tmpl"

$TmplPath  = "$RepoDir\templates\CLAUDE.md.tmpl"
$SkillPath = "$RepoDir\skills\new-rn-project\SKILL.md"

$tmplContent = Get-Content $TmplPath -Raw
$keys = [regex]::Matches($tmplContent, '\{\{([A-Z_]+)') |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object -Unique

foreach ($key in $keys) {
    Assert-Has $SkillPath $key "Placeholder {{$key}} referenciado no SKILL.md"
}

$opens  = ([regex]::Matches($tmplContent, '\{\{')).Count
$closes = ([regex]::Matches($tmplContent, '\}\}')).Count
if ($opens -eq $closes) {
    Pass "Placeholders balanceados ($opens abre, $closes fecha)"
} else {
    Fail "Placeholders desbalanceados ($opens abre, $closes fecha)"
}

# ══════════════════════════════════════════════════════════════════════════════
Section "8. Placeholder lint -- stubs"

Get-ChildItem "$RepoDir\templates\*.stub" | ForEach-Object {
    $stubName    = $_.Name
    $stubContent = Get-Content $_.FullName -Raw
    $stubKeys    = [regex]::Matches($stubContent, '\{\{([A-Z_]+)') |
                   ForEach-Object { $_.Groups[1].Value } |
                   Sort-Object -Unique

    foreach ($key in $stubKeys) {
        Assert-Has $SkillPath $key "${stubName}: {{$key}} no SKILL.md"
    }

    $o = ([regex]::Matches($stubContent, '\{\{')).Count
    $c = ([regex]::Matches($stubContent, '\}\}')).Count
    if ($o -eq $c) {
        Pass "${stubName}: placeholders balanceados"
    } else {
        Fail "${stubName}: placeholders desbalanceados ($o//$c)"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
Section "9. Hooks PS1 -- exit codes"

# pnpm falso que sai com 1
@'
exit 1
'@ | Set-Content "$MockBin\pnpm.ps1" -Encoding UTF8

$oldPath = $env:PATH
$env:PATH = "$MockBin;$env:PATH"

powershell -NoProfile -File "$RepoDir\hooks\pre-commit.ps1" *>$null
$exitCode = $LASTEXITCODE
if ($exitCode -eq 1) {
    Pass "pre-commit.ps1 sai 1 quando pnpm falha (exit $exitCode)"
} else {
    Fail "pre-commit.ps1 esperado exit 1, obtido $exitCode"
}

# pnpm falso que sai com 0
@'
exit 0
'@ | Set-Content "$MockBin\pnpm.ps1" -Encoding UTF8

powershell -NoProfile -File "$RepoDir\hooks\pre-commit.ps1" *>$null
$exitCode = $LASTEXITCODE
if ($exitCode -eq 0) {
    Pass "pre-commit.ps1 sai 0 quando pnpm passa (exit $exitCode)"
} else {
    Fail "pre-commit.ps1 esperado exit 0, obtido $exitCode"
}

# pre-push: Android N -> sai 1
$env:HARNESS_ANDROID_OK = 'N'
powershell -NoProfile -File "$RepoDir\hooks\pre-push.ps1" *>$null
$exitCode = $LASTEXITCODE
if ($exitCode -eq 1) {
    Pass "pre-push.ps1 sai 1 com ANDROID_OK=N"
} else {
    Fail "pre-push.ps1 esperado 1 com ANDROID_OK=N, obtido $exitCode"
}
Remove-Item Env:HARNESS_ANDROID_OK -ErrorAction SilentlyContinue

# pre-push: Android y -> sai 0
$env:HARNESS_ANDROID_OK = 'y'
powershell -NoProfile -File "$RepoDir\hooks\pre-push.ps1" *>$null
$exitCode = $LASTEXITCODE
if ($exitCode -eq 0) {
    Pass "pre-push.ps1 sai 0 com ANDROID_OK=y"
} else {
    Fail "pre-push.ps1 esperado 0 com ANDROID_OK=y, obtido $exitCode"
}
Remove-Item Env:HARNESS_ANDROID_OK -ErrorAction SilentlyContinue

$env:PATH = $oldPath

# ══════════════════════════════════════════════════════════════════════════════
Section "9b. Profiles -- install salva .profile e hooks corretos"

# Default install -> .profile = "strict"
Invoke-Install *>$null
$profileVal = if (Test-Path "$TestHarness\.profile") { Get-Content "$TestHarness\.profile" -Raw | ForEach-Object { $_.Trim() } } else { "" }
if ($profileVal -eq "strict") {
    Pass ".profile = strict apos install padrao"
} else {
    Fail ".profile esperado strict, obtido '$profileVal'"
}

# minimal pre-commit nao tem fta
Assert-Lacks "$TestHarness\hooks\profiles\minimal\pre-commit.sh"  "fta"       "minimal/pre-commit.sh sem fta"
Assert-Has   "$TestHarness\hooks\profiles\minimal\pre-commit.sh"  "typecheck" "minimal/pre-commit.sh tem typecheck"
Assert-Has   "$TestHarness\hooks\profiles\strict\pre-commit.sh"   "fta"       "strict/pre-commit.sh tem fta"
Assert-Has   "$TestHarness\hooks\profiles\standard\pre-commit.sh" "lint"      "standard/pre-commit.sh tem lint"
Assert-Lacks "$TestHarness\hooks\profiles\standard\pre-commit.sh" "fta"       "standard/pre-commit.sh sem fta"

# --profile minimal -> .profile = "minimal"
Invoke-Install -ProfileArg "minimal" *>$null
$profileVal = if (Test-Path "$TestHarness\.profile") { Get-Content "$TestHarness\.profile" -Raw | ForEach-Object { $_.Trim() } } else { "" }
if ($profileVal -eq "minimal") { Pass ".profile = minimal apos -Profile minimal" } else { Fail ".profile esperado minimal, obtido '$profileVal'" }

# --profile standard -> .profile = "standard"
Invoke-Install -ProfileArg "standard" *>$null
$profileVal = if (Test-Path "$TestHarness\.profile") { Get-Content "$TestHarness\.profile" -Raw | ForEach-Object { $_.Trim() } } else { "" }
if ($profileVal -eq "standard") { Pass ".profile = standard apos -Profile standard" } else { Fail ".profile esperado standard, obtido '$profileVal'" }

# ══════════════════════════════════════════════════════════════════════════════
Section "10. SKILL.md -- referencias de path"

Assert-Has $SkillPath "~/.claude/templates/rn-20days" `
    "SKILL.md referencia path correto de templates"

Assert-Has $SkillPath "~/.rn-harness/hooks" `
    "SKILL.md referencia path correto de hooks"

Assert-Has $SkillPath "~/.claude/skills/new-rn-project" `
    "SKILL.md referencia path correto da skill"

Assert-Has "$RepoDir\install.ps1" 'HARNESS_REMOTE' `
    "install.ps1 usa variavel HARNESS_REMOTE"

Assert-Lacks "$RepoDir\install.ps1" 'ls-remote git@github' `
    "install.ps1 sem URL hardcoded no ls-remote"

Assert-Has $SkillPath 'package.json' `
    "SKILL.md menciona deteccao via package.json"
Assert-Has $SkillPath 'STATE_MGMT' `
    "SKILL.md tem deteccao de state management"
Assert-Has $SkillPath 'NAVIGATION' `
    "SKILL.md tem deteccao de navigation"
Assert-Has $SkillPath 'BACKEND' `
    "SKILL.md tem deteccao de backend"
Assert-Has $SkillPath 'seletivamente' `
    "SKILL.md copia rules seletivamente"
Assert-Has $SkillPath 'HOOK_PROFILE' `
    "SKILL.md referencia HOOK_PROFILE"
Assert-Has $SkillPath '.rn-harness/.profile' `
    "SKILL.md le .profile do harness"
Assert-Has $SkillPath 'profiles/' `
    "SKILL.md usa hooks/profiles/"

} finally {
    Remove-Item -Recurse -Force $TmpBase -ErrorAction SilentlyContinue
}

# ── sumario ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "----------------------------------------"
$Total = $Pass + $Fail
Write-Host "Resultado: $Pass passed, $Fail failed / $Total total"

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Falhas:" -ForegroundColor Red
    foreach ($e in $Errors) { Write-Host "  * $e" }
}
Write-Host "----------------------------------------"

if ($Fail -gt 0) { exit 1 } else { exit 0 }

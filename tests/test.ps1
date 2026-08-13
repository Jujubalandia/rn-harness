#Requires -Version 5.1
# tests/test.ps1 — suite de testes PowerShell para rn-harness
# Roda: powershell -File tests\test.ps1
#
# Cobre:
#   1. Estrutura do repo (plugin manifests, arquivos)
#   2. Placeholder lint (CLAUDE.md.tmpl)
#   3. Placeholder lint (stubs)
#   4. Hooks PS1 — exit codes
#   5. SKILL.md — referencias de path (${CLAUDE_PLUGIN_ROOT})
#   6. Doctor — estrutura e checks basicos
#
# Instalacao/desinstalacao sao responsabilidade do Claude Code plugin manager
# (/plugin install, /plugin uninstall) — nao ha mais install.ps1/uninstall.ps1
# neste repo para testar.

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

$TmpBase = [IO.Path]::Combine($env:TEMP, [Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $TmpBase | Out-Null

$MockBin = Join-Path $TmpBase "bin"
New-Item -ItemType Directory -Force -Path $MockBin | Out-Null

$SkillPath = "$RepoDir\skills\new-rn-project\SKILL.md"

try {

# ══════════════════════════════════════════════════════════════════════════════
Section "1. Estrutura do repo (plugin)"

Assert-File "$RepoDir\.claude-plugin\plugin.json"             "plugin.json"
Assert-File "$RepoDir\.claude-plugin\marketplace.json"        "marketplace.json"
Assert-Has  "$RepoDir\.claude-plugin\marketplace.json" '"source": "\./"' `
    "marketplace.json aponta source: `"./`" (self-hosted)"

Assert-File "$RepoDir\README.md"                              "README.md"
Assert-Dir  "$RepoDir\templates"                              "templates\"
Assert-Dir  "$RepoDir\templates\docs"                         "templates\docs\"
Assert-Dir  "$RepoDir\skills\new-rn-project"                  "skills\new-rn-project\"
Assert-Dir  "$RepoDir\git-hooks"                               "git-hooks\"

Assert-File "$RepoDir\templates\CLAUDE.md.tmpl"               "CLAUDE.md.tmpl"
Assert-File "$RepoDir\templates\DECISIONS.md.stub"            "DECISIONS.md.stub"
Assert-File "$RepoDir\templates\TODO.md.stub"                 "TODO.md.stub"
Assert-File "$RepoDir\skills\new-rn-project\SKILL.md"         "SKILL.md"
Assert-File "$RepoDir\git-hooks\pre-commit.sh"                 "git-hooks\pre-commit.sh"
Assert-File "$RepoDir\git-hooks\pre-push.sh"                   "git-hooks\pre-push.sh"
Assert-File "$RepoDir\git-hooks\pre-commit.ps1"                "git-hooks\pre-commit.ps1"
Assert-File "$RepoDir\git-hooks\pre-push.ps1"                  "git-hooks\pre-push.ps1"
Assert-File "$RepoDir\tests\test.ps1"                         "tests\test.ps1"

foreach ($prof in "minimal","standard","strict") {
    Assert-Dir  "$RepoDir\git-hooks\profiles\$prof"                "profiles\$prof\"
    Assert-File "$RepoDir\git-hooks\profiles\$prof\pre-commit.sh"    "profiles\$prof\pre-commit.sh"
    Assert-File "$RepoDir\git-hooks\profiles\$prof\pre-push.sh"      "profiles\$prof\pre-push.sh"
    Assert-File "$RepoDir\git-hooks\profiles\$prof\pre-commit.ps1"   "profiles\$prof\pre-commit.ps1"
    Assert-File "$RepoDir\git-hooks\profiles\$prof\pre-push.ps1"     "profiles\$prof\pre-push.ps1"
}

Assert-File "$RepoDir\scripts\doctor.sh"          "scripts\doctor.sh"
Assert-File "$RepoDir\scripts\doctor.ps1"         "scripts\doctor.ps1"
Assert-File "$RepoDir\skills\rn-doctor\SKILL.md"  "skills\rn-doctor\SKILL.md"

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
Assert-File "$RepoDir\templates\rules\forbidden.md"                        "rules\\forbidden.md"
Assert-File "$RepoDir\templates\rules\expo-video.md"                         "rules\\expo-video.md"
Assert-File "$RepoDir\templates\rules\revenue-cat.md"                          "rules\\revenue-cat.md"
Assert-File "$RepoDir\templates\rules\expo-notifications.md"                   "rules\\expo-notifications.md"
Assert-File "$RepoDir\templates\claude\settings.json"                              "claude\\settings.json"
Assert-File "$RepoDir\templates\claude\hooks\pre-tool-use.sh"                     "claude\\hooks\\pre-tool-use.sh"

foreach ($prefix in "01","02","03","04","05","06") {
    $found = Get-ChildItem "$RepoDir\templates\docs\${prefix}-*.md" -ErrorAction SilentlyContinue
    if ($found) { Pass "templates\docs\${prefix}-*.md" } else { Fail "templates\docs\${prefix}-*.md ausente" }
}

# ══════════════════════════════════════════════════════════════════════════════
Section "2. Placeholder lint -- CLAUDE.md.tmpl"

$TmplPath  = "$RepoDir\templates\CLAUDE.md.tmpl"

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
Section "3. Placeholder lint -- stubs"

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
Section "4. Hooks PS1 -- exit codes"

# pnpm falso que sai com 1
@'
exit 1
'@ | Set-Content "$MockBin\pnpm.ps1" -Encoding UTF8

$oldPath = $env:PATH
$env:PATH = "$MockBin;$env:PATH"

powershell -NoProfile -File "$RepoDir\git-hooks\pre-commit.ps1" *>$null
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

powershell -NoProfile -File "$RepoDir\git-hooks\pre-commit.ps1" *>$null
$exitCode = $LASTEXITCODE
if ($exitCode -eq 0) {
    Pass "pre-commit.ps1 sai 0 quando pnpm passa (exit $exitCode)"
} else {
    Fail "pre-commit.ps1 esperado exit 0, obtido $exitCode"
}

# pre-push: Android N -> sai 1
$env:HARNESS_ANDROID_OK = 'N'
powershell -NoProfile -File "$RepoDir\git-hooks\pre-push.ps1" *>$null
$exitCode = $LASTEXITCODE
if ($exitCode -eq 1) {
    Pass "pre-push.ps1 sai 1 com ANDROID_OK=N"
} else {
    Fail "pre-push.ps1 esperado 1 com ANDROID_OK=N, obtido $exitCode"
}
Remove-Item Env:HARNESS_ANDROID_OK -ErrorAction SilentlyContinue

# pre-push: Android y -> sai 0
$env:HARNESS_ANDROID_OK = 'y'
powershell -NoProfile -File "$RepoDir\git-hooks\pre-push.ps1" *>$null
$exitCode = $LASTEXITCODE
if ($exitCode -eq 0) {
    Pass "pre-push.ps1 sai 0 com ANDROID_OK=y"
} else {
    Fail "pre-push.ps1 esperado 0 com ANDROID_OK=y, obtido $exitCode"
}
Remove-Item Env:HARNESS_ANDROID_OK -ErrorAction SilentlyContinue

$env:PATH = $oldPath

# Profiles: minimal sem fta, strict com fta, standard com lint sem fta
Assert-Lacks "$RepoDir\git-hooks\profiles\minimal\pre-commit.sh"  "fta"       "minimal/pre-commit.sh sem fta"
Assert-Has   "$RepoDir\git-hooks\profiles\minimal\pre-commit.sh"  "typecheck" "minimal/pre-commit.sh tem typecheck"
Assert-Has   "$RepoDir\git-hooks\profiles\strict\pre-commit.sh"   "fta"       "strict/pre-commit.sh tem fta"
Assert-Has   "$RepoDir\git-hooks\profiles\standard\pre-commit.sh" "lint"      "standard/pre-commit.sh tem lint"
Assert-Lacks "$RepoDir\git-hooks\profiles\standard\pre-commit.sh" "fta"       "standard/pre-commit.sh sem fta"

# ══════════════════════════════════════════════════════════════════════════════
Section "5. SKILL.md -- referencias de path (plugin)"

Assert-Has $SkillPath 'CLAUDE_PLUGIN_ROOT\}/templates' `
    "SKILL.md referencia templates via `${CLAUDE_PLUGIN_ROOT}"

Assert-Has $SkillPath 'CLAUDE_PLUGIN_ROOT\}/git-hooks' `
    "SKILL.md referencia git-hooks via `${CLAUDE_PLUGIN_ROOT}"

Assert-Lacks $SkillPath '~/\.rn-harness' `
    "SKILL.md sem referencias a ~/.rn-harness (legado)"

Assert-Lacks $SkillPath '~/\.claude/templates' `
    "SKILL.md sem referencias a ~/.claude/templates (legado)"

Assert-Has $SkillPath 'package.json' `
    "SKILL.md menciona deteccao via package.json"
Assert-Has $SkillPath 'STATE_MGMT' `
    "SKILL.md tem deteccao de state management"
Assert-Has $SkillPath 'NAVIGATION' `
    "SKILL.md tem deteccao de navigation"
Assert-Has $SkillPath 'BACKEND' `
    "SKILL.md tem deteccao de backend"
Assert-Has $SkillPath 'VIDEO' `
    "SKILL.md tem deteccao de video"
Assert-Has $SkillPath 'MONETIZATION' `
    "SKILL.md tem deteccao de monetizacao"
Assert-Has $SkillPath 'expo install --fix' `
    "SKILL.md inclui expo install --fix"
Assert-Has $SkillPath 'expo-video.md' `
    "SKILL.md referencia expo-video.md"
Assert-Has $SkillPath 'NOTIFICATIONS' `
    "SKILL.md tem deteccao de notifications"
Assert-Has $SkillPath 'revenue-cat.md' `
    "SKILL.md referencia revenue-cat.md"
Assert-Has $SkillPath 'expo-notifications.md' `
    "SKILL.md referencia expo-notifications.md"
Assert-Has $SkillPath 'settings.json' `
    "SKILL.md referencia settings.json"
Assert-Has $SkillPath 'pre-tool-use.sh' `
    "SKILL.md referencia pre-tool-use.sh"
$SettingsJson = "$RepoDir\templates\claude\settings.json"
Assert-Has $SettingsJson 'eas submit'  "settings.json bloqueia eas submit"
Assert-Has $SettingsJson 'deny'        "settings.json tem secao deny"
$PreHook = "$RepoDir\templates\claude\hooks\pre-tool-use.sh"
Assert-Has $PreHook 'BLOQUEADO'           "pre-tool-use.sh tem mensagem de bloqueio"
Assert-Has $PreHook 'supabase db reset'   "pre-tool-use.sh bloqueia supabase db reset"
Assert-Has $SkillPath 'seletivamente' `
    "SKILL.md copia rules seletivamente"
$RouterRule = "$RepoDir\templates\rules\expo-router.md"
Assert-Has $RouterRule 'NativeTabs'           "expo-router.md tem secao NativeTabs"
Assert-Has $RouterRule 'sfSymbol'             "expo-router.md tem pares SF Symbol"
Assert-Has $RouterRule 'materialIcon'         "expo-router.md tem pares Material Icon"
Assert-Has $RouterRule 'unstable-native-tabs' "expo-router.md usa unstable-native-tabs"

Assert-Has $SkillPath 'HOOK_PROFILE' `
    "SKILL.md referencia HOOK_PROFILE"
Assert-Has $SkillPath 'CLAUDE_PLUGIN_DATA' `
    "SKILL.md le/grava .profile via CLAUDE_PLUGIN_DATA"
Assert-Has $SkillPath 'profiles/' `
    "SKILL.md usa git-hooks/profiles/"

# ══════════════════════════════════════════════════════════════════════════════
Section "6. Doctor -- estrutura e checks basicos"

$DoctorSh   = "$RepoDir\scripts\doctor.sh"
$DoctorPs1  = "$RepoDir\scripts\doctor.ps1"
$DoctorSkill = "$RepoDir\skills\rn-doctor\SKILL.md"

Assert-File $DoctorSh   "scripts\doctor.sh"
Assert-File $DoctorPs1  "scripts\doctor.ps1"
Assert-File $DoctorSkill "skills\rn-doctor\SKILL.md"

Assert-Has $DoctorPs1 'node'                   "doctor.ps1 checa node"
Assert-Has $DoctorPs1 'tsconfig'               "doctor.ps1 checa tsconfig"
Assert-Has $DoctorPs1 'babel'                  "doctor.ps1 checa babel"
Assert-Has $DoctorPs1 'no-color-literals'      "doctor.ps1 checa ESLint no-color-literals"
Assert-Has $DoctorPs1 'expo-secure-store'      "doctor.ps1 checa expo-secure-store"
Assert-Has $DoctorPs1 'core.hooksPath'         "doctor.ps1 checa git hooks"
Assert-Has $DoctorPs1 '\-Json'                 "doctor.ps1 suporta -Json"
Assert-Lacks $DoctorPs1 'expo-doctor'          "doctor.ps1 nao depende de expo-doctor externo"
Assert-Has $DoctorPs1 'lineHeight'             "doctor.ps1 checa lineHeight"
Assert-Has $DoctorPs1 'expo-av'               "doctor.ps1 checa expo-av"
Assert-Has $DoctorSkill '24'                   "rn-doctor SKILL.md menciona 24 checks"
Assert-Has $DoctorSkill 'doctor.sh'            "rn-doctor SKILL.md referencia doctor.sh"
Assert-Has $DoctorSkill 'doctor.ps1'           "rn-doctor SKILL.md referencia doctor.ps1"

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

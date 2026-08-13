#Requires -Version 5.1
# rn-harness doctor — 22 health checks for a React Native project (PowerShell)
# Usage: doctor.ps1 [-Json] [-ProjectDir <path>]
# Exit: 0 = all OK/WARN, 1 = at least one FAIL

[CmdletBinding()]
param(
    [switch]$Json,
    [string]$ProjectDir = "."
)
$ErrorActionPreference = 'Stop'

$OkCount   = 0
$WarnCount = 0
$FailCount = 0
$Results   = [System.Collections.Generic.List[hashtable]]::new()

function Out-Check([int]$N, [string]$Level, [string]$Msg, [string]$Fix = "") {
    switch ($Level) {
        "OK"   { $script:OkCount++ }
        "WARN" { $script:WarnCount++ }
        "FAIL" { $script:FailCount++ }
    }
    $script:Results.Add(@{ n=$N; level=$Level; msg=$Msg; fix=$Fix })
    if (-not $Json) {
        switch ($Level) {
            "OK"   { Write-Host "  [OK]   $Msg" -ForegroundColor Green }
            "WARN" { Write-Host "  [WARN] $Msg" -ForegroundColor Yellow }
            "FAIL" {
                Write-Host "  [FAIL] $Msg" -ForegroundColor Red
                if ($Fix) { Write-Host "         fix: $Fix" -ForegroundColor DarkGray }
            }
        }
    }
}

if (-not $Json) { Write-Host "`nrn-harness doctor`n=================" }

$Pkg = Join-Path $ProjectDir "package.json"

# 1. node >= 20
if (Get-Command node -ErrorAction SilentlyContinue) {
    $v = (node --version 2>$null) -replace 'v',''
    $maj = [int]($v -split '\.')[0]
    if ($maj -ge 20) { Out-Check 1 "OK"   "node v$v >= 20" }
    else             { Out-Check 1 "FAIL" "node v$v < 20" "nvm install 20 && nvm use 20" }
} else {
    Out-Check 1 "FAIL" "node nao encontrado" "https://nodejs.org (LTS 20)"
}

# 2. pnpm
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    $v = pnpm --version 2>$null
    Out-Check 2 "OK" "pnpm $v instalado"
} else {
    Out-Check 2 "FAIL" "pnpm nao encontrado" "npm install -g pnpm"
}

# 3. git
if (Get-Command git -ErrorAction SilentlyContinue) {
    $v = (git --version 2>$null) -replace 'git version ',''
    Out-Check 3 "OK" "git $v instalado"
} else {
    Out-Check 3 "FAIL" "git nao encontrado" "https://git-scm.com"
}

# 4. eas-cli
if (Get-Command eas -ErrorAction SilentlyContinue) {
    $v = eas --version 2>$null | Select-Object -First 1
    Out-Check 4 "OK" "eas-cli $v instalado"
} else {
    Out-Check 4 "WARN" "eas-cli nao encontrado (opcional)" "pnpm install -g eas-cli"
}

# 5. package.json
if (Test-Path $Pkg) { Out-Check 5 "OK" "package.json presente" }
else { Out-Check 5 "FAIL" "package.json nao encontrado" "cd <projeto> && pnpm init" }

# 6. CLAUDE.md
if (Test-Path (Join-Path $ProjectDir "CLAUDE.md")) { Out-Check 6 "OK" "CLAUDE.md presente" }
else { Out-Check 6 "WARN" "CLAUDE.md ausente" "/new-rn-project para criar" }

# 7. .gitignore cobre .env*
$gi = Join-Path $ProjectDir ".gitignore"
if ((Test-Path $gi) -and (Select-String -Quiet -Pattern '^\.(env|env\*)' -Path $gi)) {
    Out-Check 7 "OK" ".gitignore cobre .env*"
} else {
    Out-Check 7 "FAIL" ".gitignore nao cobre .env*" "echo '.env*' >> .gitignore"
}

# 8. nenhum .env* commitado
$gitDir = Join-Path $ProjectDir ".git"
if (Test-Path $gitDir) {
    $envCommitted = git -C $ProjectDir ls-files '*.env' '.env.*' '.env' 2>$null | Select-Object -First 1
    if ($envCommitted) {
        Out-Check 8 "FAIL" ".env* commitado: $envCommitted" "git rm --cached $envCommitted"
    } else {
        Out-Check 8 "OK" "nenhum .env* commitado"
    }
} else {
    Out-Check 8 "WARN" ".git/ ausente — nao e possivel verificar .env*" "git init"
}

# 9. .claude/rules/ presente
$rulesDir = Join-Path $ProjectDir ".claude\rules"
$ruleCount = 0
if (Test-Path $rulesDir) { $ruleCount = (Get-ChildItem $rulesDir -Filter '*.md' -ErrorAction SilentlyContinue).Count }
if ($ruleCount -gt 0) {
    Out-Check 9 "OK" ".claude\rules\ presente ($ruleCount rules)"
} else {
    Out-Check 9 "WARN" ".claude\rules\ ausente" "/rn-harness:new-rn-project ou copiar manualmente do plugin (`$env:CLAUDE_PLUGIN_ROOT\templates\rules\)"
}

# 10. Expo SDK 56
if (Test-Path $Pkg) {
    $pkgRaw = Get-Content $Pkg -Raw
    if ($pkgRaw -match '"expo"\s*:\s*"([^"]+)"') {
        $expoVer = $Matches[1]
        $expoMaj = ($expoVer -replace '[\^~]','') -split '\.' | Select-Object -First 1
        if ($expoMaj -eq "56") { Out-Check 10 "OK" "Expo SDK $expoVer (56)" }
        elseif ($expoMaj)      { Out-Check 10 "FAIL" "Expo SDK $expoVer (alvo: 56)" "npx expo install expo@^56 --fix" }
        else                   { Out-Check 10 "WARN" "expo nao encontrado em package.json" "pnpm add expo@^56" }
    } else {
        Out-Check 10 "WARN" "expo nao encontrado em package.json" "pnpm add expo@^56"
    }
}

# 11. React Native 0.76.x
if (Test-Path $Pkg) {
    $pkgRaw = Get-Content $Pkg -Raw
    if ($pkgRaw -match '"react-native"\s*:\s*"([^"]+)"') {
        $rnVer = $Matches[1]
        $rnMinor = ($rnVer -replace '[\^~]','') -split '\.' | Select-Object -Index 1
        if ($rnMinor -eq "76") { Out-Check 11 "OK" "React Native $rnVer (0.76.x)" }
        elseif ($rnMinor)      { Out-Check 11 "WARN" "React Native $rnVer (alvo: 0.76.x)" "" }
        else                   { Out-Check 11 "WARN" "react-native nao encontrado" "" }
    }
}

# 12. Reanimated v3
if (Test-Path $Pkg) {
    $pkgRaw = Get-Content $Pkg -Raw
    if ($pkgRaw -match '"react-native-reanimated"\s*:\s*"([^"]+)"') {
        $rv = $Matches[1]
        $rmaj = ($rv -replace '[\^~]','') -split '\.' | Select-Object -First 1
        if ($rmaj -eq "3")    { Out-Check 12 "OK" "react-native-reanimated $rv (v3)" }
        elseif ($rmaj -eq "4"){ Out-Check 12 "FAIL" "reanimated $rv (v4 — harness usa v3)" "pnpm add react-native-reanimated@^3" }
        elseif ($rmaj)        { Out-Check 12 "WARN" "reanimated $rv (esperado ^3.x)" "" }
        else                  { Out-Check 12 "WARN" "reanimated nao encontrado" "pnpm add react-native-reanimated@^3" }
    } else {
        Out-Check 12 "WARN" "react-native-reanimated nao encontrado" "pnpm add react-native-reanimated@^3"
    }
}

# 13. tsconfig.json strict:true
$tsconfig = Join-Path $ProjectDir "tsconfig.json"
if (Test-Path $tsconfig) {
    if (Select-String -Quiet -Pattern '"strict"\s*:\s*true' -Path $tsconfig) {
        Out-Check 13 "OK" "tsconfig.json com strict: true"
    } else {
        Out-Check 13 "FAIL" "tsconfig.json sem strict: true" "Adicionar '`"strict`": true' em compilerOptions"
    }
} else {
    Out-Check 13 "FAIL" "tsconfig.json nao encontrado" "npx tsc --init"
}

# 14. babel.config.js tem plugin reanimated
$babelFile = $null
foreach ($b in @("babel.config.js","babel.config.ts")) {
    $p = Join-Path $ProjectDir $b
    if (Test-Path $p) { $babelFile = $p; break }
}
if ($babelFile) {
    if (Select-String -Quiet -Pattern 'react-native-reanimated/plugin' -Path $babelFile) {
        Out-Check 14 "OK" "babel.config.js tem plugin react-native-reanimated"
    } else {
        if ((Test-Path $Pkg) -and (Select-String -Quiet -Pattern '"react-native-reanimated"' -Path $Pkg)) {
            Out-Check 14 "FAIL" "babel.config.js sem plugin reanimated (reanimated instalado)" "Adicionar 'react-native-reanimated/plugin' ao array plugins"
        } else {
            Out-Check 14 "OK" "babel.config.js sem plugin reanimated (reanimated nao instalado)"
        }
    }
} else {
    Out-Check 14 "WARN" "babel.config.js nao encontrado" "criar babel.config.js com preset expo"
}

# 15. ESLint tem no-color-literals
$eslintFile = $null
foreach ($e in @(".eslintrc.js",".eslintrc.cjs",".eslintrc.json",".eslintrc.yaml","eslint.config.js","eslint.config.mjs")) {
    $p = Join-Path $ProjectDir $e
    if (Test-Path $p) { $eslintFile = $p; break }
}
if ($eslintFile) {
    if (Select-String -Quiet -Pattern 'no-color-literals' -Path $eslintFile) {
        Out-Check 15 "OK" "ESLint tem react-native/no-color-literals"
    } else {
        Out-Check 15 "WARN" "ESLint sem react-native/no-color-literals" "Adicionar 'react-native/no-color-literals': 'error'"
    }
} else {
    Out-Check 15 "FAIL" "ESLint config nao encontrado" "pnpm add -D eslint @react-native/eslint-config"
}

# 16. pnpm scripts obrigatorios
if (Test-Path $Pkg) {
    $pkgRaw = Get-Content $Pkg -Raw
    $missing = @()
    foreach ($s in @("typecheck","lint","format:check","fta","quality:full")) {
        if ($pkgRaw -notmatch [regex]::Escape("`"$s`"")) { $missing += $s }
    }
    if ($missing.Count -eq 0) {
        Out-Check 16 "OK" "scripts pnpm: todos presentes"
    } else {
        Out-Check 16 "FAIL" "scripts ausentes: $($missing -join ', ')" "Ver 03-quality-gates.md para template de package.json"
    }
}

# 17. expo-secure-store vs AsyncStorage
if (Test-Path $Pkg) {
    $pkgRaw = Get-Content $Pkg -Raw
    $hasSecure = $pkgRaw -match '"expo-secure-store"'
    $hasAsync  = $pkgRaw -match '"@react-native-async-storage/async-storage"'
    if ($hasSecure -and -not $hasAsync) {
        Out-Check 17 "OK" "expo-secure-store presente, AsyncStorage ausente"
    } elseif ($hasSecure -and $hasAsync) {
        Out-Check 17 "WARN" "expo-secure-store E AsyncStorage presentes — tokens devem usar SecureStore" "Ver rules/security.md"
    } elseif ($hasAsync) {
        Out-Check 17 "FAIL" "AsyncStorage sem expo-secure-store — tokens em texto puro" "pnpm add expo-secure-store && migrar tokens"
    } else {
        Out-Check 17 "WARN" "expo-secure-store nao encontrado" "pnpm add expo-secure-store"
    }
}

# 18. Sem chaves hardcoded
$hardcoded = Get-ChildItem -Path $ProjectDir -Recurse -Include '*.ts','*.tsx' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch 'node_modules|\.test\.' } |
    Select-String -Pattern '(API_KEY|SECRET|PASSWORD|api_key|apiKey)\s*=\s*[''"][A-Za-z0-9_\-]{8,}' -ErrorAction SilentlyContinue |
    Select-Object -First 3
if ($hardcoded) {
    $first = $hardcoded | Select-Object -First 1
    Out-Check 18 "FAIL" "possivel chave hardcoded: $($first.Filename):$($first.LineNumber)" "Mover para .env.local + process.env.EXPO_PUBLIC_*"
} else {
    Out-Check 18 "OK" "sem chaves hardcoded detectadas em .ts/.tsx"
}

# 19. .git/ existe
if (Test-Path (Join-Path $ProjectDir ".git")) {
    Out-Check 19 "OK" "repositorio git inicializado"
} else {
    Out-Check 19 "FAIL" ".git/ nao encontrado" "git init && git add . && git commit -m 'init'"
}

# 20. core.hooksPath
if (Test-Path (Join-Path $ProjectDir ".git")) {
    $hp = git -C $ProjectDir config core.hooksPath 2>$null
    if ($hp -eq ".githooks") {
        Out-Check 20 "OK" "git core.hooksPath = .githooks"
    } elseif ($hp) {
        Out-Check 20 "WARN" "git core.hooksPath = '$hp' (esperado .githooks)" "git config core.hooksPath .githooks"
    } else {
        Out-Check 20 "FAIL" "git core.hooksPath nao configurado — hooks nao vao rodar" "git config core.hooksPath .githooks"
    }
} else {
    Out-Check 20 "WARN" ".git/ ausente — core.hooksPath nao verificavel" "git init"
}

# 21. app.json tem bundleIdentifier + packageName
$appFile = $null
foreach ($a in @("app.json","app.config.ts","app.config.js")) {
    $p = Join-Path $ProjectDir $a
    if (Test-Path $p) { $appFile = $p; break }
}
if ($appFile) {
    $appRaw = Get-Content $appFile -Raw -ErrorAction SilentlyContinue
    $hasBundle = $appRaw -match 'bundleIdentifier'
    $hasPkg    = $appRaw -match '"package"'
    if ($hasBundle -and $hasPkg) {
        Out-Check 21 "OK" "$appFile tem bundleIdentifier e packageName"
    } else {
        Out-Check 21 "WARN" "$appFile sem bundleIdentifier/packageName (obrigatorio para store)" "Preencher ios.bundleIdentifier e android.package"
    }
} else {
    Out-Check 21 "WARN" "app.json / app.config.ts nao encontrado" "npx create-expo-app ou criar app.json"
}

# 22. eas.json
if (Test-Path (Join-Path $ProjectDir "eas.json")) {
    Out-Check 22 "OK" "eas.json presente"
} elseif (Get-Command eas -ErrorAction SilentlyContinue) {
    Out-Check 22 "WARN" "eas.json ausente (eas-cli instalado — store builds nao configurados)" "eas build:configure"
} else {
    Out-Check 22 "WARN" "eas.json ausente (opcional)" "eas build:configure quando pronto para store"
}

# 23. lineHeight em StyleSheet (bug Android)
$lineH = Get-ChildItem -Path $ProjectDir -Recurse -Include '*.ts','*.tsx','*.js' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch 'node_modules|\.test\.|\.d\.ts' } |
    Select-String -Pattern 'lineHeight' -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($lineH) {
    Out-Check 23 "FAIL" "lineHeight detectado: $($lineH.Filename):$($lineH.LineNumber)" "Substituir por paddingVertical/marginVertical (lineHeight corta texto em Android)"
} else {
    Out-Check 23 "OK" "sem lineHeight em StyleSheet (Android-safe)"
}

# 24. expo-av importado (deprecated)
$expoAv = Get-ChildItem -Path $ProjectDir -Recurse -Include '*.ts','*.tsx','*.js' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch 'node_modules|\.test\.' } |
    Select-String -Pattern "from 'expo-av'" -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($expoAv) {
    Out-Check 24 "FAIL" "expo-av importado (deprecated): $($expoAv.Filename)" "Migrar para expo-video (video) e expo-audio (audio)"
} else {
    Out-Check 24 "OK" "expo-av nao usado (usar expo-video + expo-audio)"
}

# ── Summary ──────────────────────────────────────────────────────────────────
$total = $OkCount + $WarnCount + $FailCount

if ($Json) {
    $out = @{
        ok    = $OkCount
        warn  = $WarnCount
        fail  = $FailCount
        total = $total
        results = $Results
    }
    $out | ConvertTo-Json -Depth 3
} else {
    Write-Host ""
    Write-Host "────────────────────────────────────────"
    Write-Host "OK: $OkCount  WARN: $WarnCount  FAIL: $FailCount  / $total total"
    Write-Host "────────────────────────────────────────`n"
}

if ($FailCount -gt 0) { exit 1 } else { exit 0 }

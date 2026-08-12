# Coding Conventions

**Analysis Date:** 2026-08-11

## Naming Patterns

**Files:**
- Shell scripts: lowercase with extensions (`.sh` for POSIX bash, `.ps1` for PowerShell)
- Paired implementations: every functionality has both `.sh` and `.ps1` versions for cross-platform support
  - Example: `install.sh` + `install.ps1`, `hooks/pre-commit.sh` + `hooks/pre-commit.ps1`
- Templates: `*.tmpl` extension for templated files (e.g., `CLAUDE.md.tmpl`)
- Stubs: `*.stub` extension for skeleton files (e.g., `DECISIONS.md.stub`, `TODO.md.stub`)
- Markdown rules: lowercase-kebab-case matching the package name (e.g., `react-native-reanimated.md`, `expo-router.md`)
- Test files: `test.sh` and `test.ps1` (no individual `*.test.sh` pattern; single comprehensive suite per platform)

**Directories:**
- Feature folders: kebab-case (e.g., `skills/new-rn-project`, `hooks/profiles/minimal`)
- Organized by function: `scripts/`, `skills/`, `templates/`, `hooks/`, `tests/`, `.claude/`

**Functions/Variables (Shell):**
- Environment variables: `UPPERCASE_WITH_UNDERSCORES` (e.g., `HARNESS_DIR`, `CLAUDE_CONFIG_DIR`, `TEST_HARNESS`)
- Function names: snake_case (e.g., `run_install`, `assert_file`, `pass`, `fail`)
- Helper functions prefixed with underscore for internal use (e.g., `_out`)

**Functions/Variables (PowerShell):**
- Environment variables: `$env:UPPERCASE_WITH_UNDERSCORES` (system vars) or `[string]$CamelCase` (local params)
- Function names: PascalCase per PowerShell convention (e.g., `Assert-File`, `Assert-Dir`, `Invoke-Install`)
- Parameter names: PascalCase with hyphens (e.g., `-Force`, `-Profile`)

## Code Style

**Shell Scripts (Bash):**
- Shebang: `#!/usr/bin/env bash` (bash) or `#!/bin/sh` (POSIX shell for hooks)
- Error handling: `set -e` at top to exit on first error
- Error handling: `set -uo pipefail` in test files for stricter error handling
- Comments organized in sections using separator lines: `# ── section name ────────────────────`
- Output indicators use arrow symbols:
  - `→` for progress steps (e.g., `echo "→ typecheck..."`)
  - `✅` for success messages
  - `❌` for failure/error messages
- Quotes: prefer `"$var"` over `$var` for safety; use `'...'` for literal strings
- Conditionals: `[ ]` for POSIX, but `[[ ]]` acceptable in bash-specific scripts

**PowerShell Scripts:**
- Requires clause: `#Requires -Version 5.1` at top
- Error handling: `$ErrorActionPreference = 'Stop'` for strict mode
- Error handling: explicit `if ($LASTEXITCODE -ne 0) { ... }` checks after external commands
- Cmdlet parameters: `[CmdletBinding()]` attribute on functions with param block
- Parameter validation: `[ValidateSet("...")]` attributes for enum-like choices
- Output: `Write-Host` for user-facing messages; color support via `-ForegroundColor`
- Variables: `$PascalCase` for local scope, `$env:UPPERCASE` for environment
- File operations: Use `Test-Path` with `-PathType` (Leaf/Container) for type checking
- Quotes: `"..."` for interpolation; `'...'` for literals; backticks for escaping

**Languages in Messages:**
- Code comments: **Portuguese (PT-BR)** as primary language
- Output messages (user-facing): **Portuguese (PT-BR)**
- Actual code symbols and variables: English
- No mixing—keep language consistent within a file

## Import Organization

**Not applicable** — this is shell/PowerShell/Markdown, not a programming language with imports. However, file sourcing follows this pattern:
- Environment variables set first (from `.profile` or passed in)
- Helper functions defined before use
- Main logic at bottom of file

**Path Aliases:**
- Shell: Use `~` for home directory (e.g., `~/.claude/templates/`)
- PowerShell: Use `$env:USERPROFILE` or `$env:TEMP` for system paths
- Relative paths avoided; absolute paths preferred for clarity

## Error Handling

**Patterns:**
- Bash: `set -e` stops on error; explicit `$?` checks for conditional behavior
- PowerShell: `$ErrorActionPreference = 'Stop'` stops on error; `try/finally` for cleanup
- Exit codes: 0 = success, 1 = general error
- User confirmation loops: use `read -r answer` (bash) or `Read-Host` (PowerShell)
- Error messages: always prefixed with `❌` or `ERRO:`/`FAIL`
- Recovery advice: suggested fixes printed as `fix: ...` or in `FAIL` output

**Examples:**
```bash
# Bash pattern
if [ ! -d "$HARNESS_DIR/.git" ]; then
  echo "❌ Directory error"; exit 1
fi
```

```powershell
# PowerShell pattern
if ($LASTEXITCODE -ne 0) { 
  Write-Error "Operation failed"
  exit 1 
}
```

## Logging

**Framework:** Plain `echo` (bash) / `Write-Host` (PowerShell) — no logging library

**Patterns:**
- Progress steps: `echo "→ step name..."` before running command
- Success: `echo "✅ message"` after validation
- Errors: `echo "❌ message"` with optional `exit CODE`
- Warnings: `echo "[WARN] message"` or `Write-Host "..." -ForegroundColor Yellow`
- Info lines: `echo "message"` with no prefix
- Verbose output: pipe stderr to `/dev/null 2>&1` unless debugging

**Test output (special):**
- Test suite uses colored output: `GREEN` for pass, `RED` for fail
- Test results tracked in counters: `$PASS`, `$FAIL`, errors in array `$ERRORS`
- Section headers: `section()` function prints bold header with newline

## Comments

**When to Comment:**
- Section headers using `# ── NAME ────` separator pattern (20 hyphens)
- Algorithm explanations for non-obvious logic
- Function purpose at top: `# description of what this does`
- TODOs: rarely used (not observed in codebase)
- Inline comments: avoided; prefer self-documenting code with clear variable names

**JSDoc/TSDoc:**
- Not applicable (no TypeScript in this codebase)
- Markdown rules files use code comment blocks to explain patterns

## Module Design

**Exports:**
- Shell: Functions sourced or invoked as subshells
- PowerShell: Functions exported implicitly; params defined via `[CmdletBinding()]` and `param(...)`
- Skills: Exported as SKILL.md + referenced paths in ~/ directory notation

**Barrel Files:**
- Not applicable to shell/markdown, but templates use index-like approach:
  - CLAUDE.md.tmpl = main project template
  - DECISIONS.md.stub, TODO.md.stub = supporting stubs
  - rules/*.md = selective knowledge rules loaded as needed

**Template Structure (YAML Frontmatter):**
All markdown rule files use YAML frontmatter:
```markdown
---
name: skill-name                    # SKILL.md only
description: one-line purpose
globs: "**/*.{ts,tsx}"              # rules only
alwaysApply: false                  # rules only
---
```

Placeholder syntax: `{{PLACEHOLDER_NAME}}` with caps and underscores
- All placeholders must be:
  1. Documented in SKILL.md
  2. Balanced (same count of `{{` and `}}`)
  3. Referenced in templates and stubs

## Testing-Related Conventions

**Test File Organization:**
- `tests/test.sh` — primary POSIX test suite (runs on all platforms via bash)
- `tests/test.ps1` — secondary Windows-specific test suite (same 10 sections, PowerShell implementation)
- Both test the same scenarios for parity
- No mocking framework; mock binaries created as temporary files

**Assertion Helpers:**
All follow pattern `assert_X` or `Assert-X`:
- `assert_file / Assert-File` — check file exists
- `assert_dir / Assert-Dir` — check directory exists
- `assert_gone / Assert-Gone` — check file/dir deleted
- `assert_exec` (bash) — check file is executable
- `assert_has / Assert-Has` — grep pattern match required
- `assert_lacks / Assert-Lacks` — grep pattern must NOT match
- `run_exit` (bash) — run command, verify exit code

## Script Patterns

**Argument Parsing (Bash):**
```bash
while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)   FORCE="--force"; shift ;;
    --profile) PROFILE="$2"; shift 2 ;;
    *)         shift ;;
  esac
done
```

**Argument Parsing (PowerShell):**
```powershell
[CmdletBinding()]
param(
    [switch]$Force,
    [ValidateSet("minimal","standard","strict")][string]$Profile = "strict"
)
```

**Environment Variable Mocking:**
Inline env var override for subshell:
```bash
RN_HARNESS_DIR="$TEST_HARNESS" CLAUDE_CONFIG_DIR="$TEST_CLAUDE" bash script.sh
```

PowerShell equivalent:
```powershell
$env:RN_HARNESS_DIR = $TestHarness
& script.ps1
Remove-Item Env:RN_HARNESS_DIR
```

**Temporary Directories:**
- Bash: `TMPBASE="$(mktemp -d)"` + `trap cleanup EXIT`
- PowerShell: `[IO.Path]::Combine($env:TEMP, [Guid]::NewGuid().ToString())`
- Always clean up on exit

## Git Hooks Format

**Hook files** in `hooks/` and `hooks/profiles/<profile>/`:
- Simple, opinionated; no configuration file needed
- Run pnpm commands in order: typecheck → lint → format → fta
- Profile selection controls which commands run:
  - **minimal**: typecheck only (D1-D5, fast iteration)
  - **standard**: typecheck + lint + format + quality:full on push
  - **strict**: all of above + fta (score cap 60) — default for code freeze
- Profile stored in `.profile` file by installer

---

*Convention analysis: 2026-08-11*

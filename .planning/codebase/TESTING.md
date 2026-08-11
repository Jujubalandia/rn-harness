# Testing Patterns

**Analysis Date:** 2026-08-11

## Test Framework

**Runner:**
- Bash: `bash tests/test.sh` (native POSIX shell, no external dependencies)
- PowerShell: `powershell -File tests/test.ps1` (native Windows PowerShell 5.1+)

**Assertion Library:**
- None; custom helper functions built into each test file

**Run Commands:**
```bash
# Bash test suite
bash tests/test.sh                    # Run all tests
# (no watch mode — each run is complete)

# PowerShell test suite
powershell -File tests/test.ps1       # Run all tests
```

**Test Organization:**
- Two separate implementations for parity: `tests/test.sh` and `tests/test.ps1`
- Both test identical scenarios (10 sections, same coverage)
- No framework dependency; all logic inline or via helper functions
- Full run takes ~10-30 seconds; tests actual git operations and file system

## Test File Organization

**Location:**
- `C:/Users/Bruno/rn-harness/tests/test.sh` — POSIX bash suite
- `C:/Users/Bruno/rn-harness/tests/test.ps1` — PowerShell suite

**Naming:**
- Single test file per platform (not split per feature)
- Comprehensive suite: all scenarios in one file

**Structure:**
```
1. Temporary environment setup
   - Create temp directories (TMPBASE)
   - Initialize mock git repos
2. Helper function definitions (assert_*, run_*, etc.)
3. Test sections (10 major sections, each with sub-tests)
4. Cleanup (trap cleanup EXIT in bash)
```

## Test Structure

**Suite Organization (Bash):**
```bash
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0; ERRORS=()

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

# Helper functions
pass()   { echo -e "  ${GREEN}✅${NC} $1"; PASS=$((PASS + 1)); }
fail()   { echo -e "  ${RED}❌${NC} $1"; FAIL=$((FAIL + 1)); ERRORS+=("$1"); }
section(){ echo -e "\n${BOLD}$1${NC}"; }

assert_file()  { [ -f "$1" ] && pass "${2:-$1}" || fail "${2:-$1} — arquivo ausente"; }
assert_dir()   { [ -d "$1" ] && pass "${2:-$1}" || fail "${2:-$1} — dir ausente"; }
# ... more assertions

# Temporary environment
TMPBASE="$(mktemp -d)"
cleanup() { rm -rf "$TMPBASE"; }
trap cleanup EXIT

# Run tests in sections
section "1. Estrutura do repo"
assert_file "$REPO_DIR/install.sh" "install.sh"
# ...

# Summary
echo ""
echo "Resultados: $PASS ✅, $FAIL ❌"
```

**Suite Organization (PowerShell):**
```powershell
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$RepoDir = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
$Pass = 0; $Fail = 0; [string[]]$Errors = @()

# Helper functions
function Pass([string]$Label) {
    Write-Host "  OK $Label" -ForegroundColor Green
    $script:Pass++
}
function Fail([string]$Label) {
    Write-Host "  FAIL $Label" -ForegroundColor Red
    $script:Fail++
    $script:Errors += $Label
}
# ... more helpers

# Temporary environment
$TmpBase = [IO.Path]::Combine($env:TEMP, [Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $TmpBase | Out-Null

try {
    Section "1. Estrutura do repo"
    Assert-File "$RepoDir\install.sh" "install.sh"
    # ...
} finally {
    # Cleanup via try/finally
}

Write-Host "Resultados: $Pass OK, $Fail FAIL"
```

**Patterns:**
- **Setup:** Create isolated temp directories per test run (no state pollution)
- **Setup:** Clone repo to temp location to test installation logic
- **Teardown:** `trap cleanup EXIT` (bash) or `finally` block (PowerShell)
- **Environment isolation:** Mock environment variables, mock binaries, mock git repos
- **Assertion pattern:** Each assert calls `pass()` or `fail()` and increments counters

## Mocking

**Framework:** No framework; manual mock creation

**Patterns:**
```bash
# Create mock binary that fails
cat > "$MOCK_BIN/pnpm" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$MOCK_BIN/pnpm"

# Run with mock in PATH
env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/hooks/pre-commit.sh"
```

**PowerShell mocking:**
```powershell
# Mock by setting environment variables for subshell
$env:RN_HARNESS_DIR = $TestHarness
powershell -NoProfile -File "$RepoDir\install.ps1" *>$null
```

**What to Mock:**
- External commands: `pnpm`, `git` (via mock binaries in PATH)
- Configuration directories: home directory structure (via env vars `$TEST_HARNESS`, `$TEST_CLAUDE`)
- Git repositories: bare clone of repo to test pull/clone logic
- User input: pipe responses to stdin (bash) or use env vars for confirmation

**What NOT to Mock:**
- File system (real temp dirs created; cleaned up after)
- Git operations (real git commands used against test repos)
- Directory creation/deletion (actual filesystem, not mocked)

## Fixtures and Factories

**Test Data:**
- No fixtures directory; data generated inline as needed
- Sentinel values in templates: `echo "SENTINEL_IDEMPOTENCY" >> file` to verify non-overwrite
- Mock git repos: `git clone --bare $REPO_DIR $TEST_REMOTE` creates bare clone for testing

**Location:**
- All in test file itself (`test.sh` or `test.ps1`)
- Temporary directories created via `mktemp -d` (bash) or `[IO.Path]::Combine()` (PowerShell)

**Patterns:**
```bash
# Idempotency test
echo "SENTINEL_VALUE" >> "$TEST_FILE"
run_install  # should NOT overwrite
assert_has "$TEST_FILE" "SENTINEL_VALUE" "file preserved"

# Exit code test
run_exit 1 "expected failure" command_that_fails
```

## Coverage

**Requirements:** None enforced; tests are comprehensive but optional to run

**Test Sections (10 major areas):**

1. **Repo Structure** — 30+ file/directory existence + executable bits
   - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 79-148

2. **Fresh Install** — verify clone, copy, permissions all work from clean state
   - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 151-176

3. **Idempotency** — 2nd install preserves user modifications (cp -rn behavior)
   - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 179-186

4. **Force Flag** — `--force` (bash) or `-Force` (PS) overwrites everything
   - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 189-195

5. **Uninstall (Confirm)** — `echo "y"` removes all installed files
   - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 198-204

6. **Uninstall (Deny)** — `echo "N"` cancels and preserves everything
   - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 207-215

7. **Template Placeholder Lint** — CLAUDE.md.tmpl: balanced `{{}}`, all placeholders documented
   - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 218-236

8. **Stub Placeholder Lint** — DECISIONS.md.stub, TODO.md.stub: same validation
   - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 239-254

9. **Hooks Exit Codes** — pre-commit/pre-push respect pnpm exit codes, handle user input
   - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 257-291

10. **Profiles** — `--profile minimal/standard/strict` selects correct hooks, saves .profile
    - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 294-322

11. **SKILL.md Validation** — paths referenced are correct, placeholders match
    - Tests: `C:/Users/Bruno/rn-harness/tests/test.sh` lines 325-349

## Test Types

**Unit Tests:** Not used explicitly; tests focus on integration

**Integration Tests:**
- Full install workflow in temp directory
- Verify all files in correct locations with correct content
- Test idempotency and force overwrite
- Test hook execution with real pnpm (mocked to fail/pass)
- Uninstall and cleanup workflow

**E2E Tests:** Not used; integration tests cover full flow

## Common Patterns

**Async Testing:** Not applicable (shell scripts are synchronous)

**Error Testing:**
```bash
# Test exit codes
run_exit 1 "pre-commit fails when pnpm fails" \
  env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/hooks/pre-commit.sh"

# Test success
run_exit 0 "pre-commit succeeds when pnpm succeeds" \
  env PATH="$MOCK_BIN:$PATH" sh "$REPO_DIR/hooks/pre-commit.sh"
```

**File Content Testing:**
```bash
assert_has "$FILE" "pattern" "file contains expected text"
assert_lacks "$FILE" "bad_pattern" "file excludes unwanted text"
```

**Directory Testing:**
```bash
assert_file "$REPO_DIR/install.sh" "install.sh exists"
assert_exec "$REPO_DIR/install.sh" "install.sh is executable"
assert_gone "$TEST_CLAUDE/templates/rn-20days" "templates removed after uninstall"
```

## Helper Functions Reference

**Bash Assertion Helpers:**

| Function | Purpose | Usage |
|----------|---------|-------|
| `pass()` | Record pass, increment counter | `pass "description"` |
| `fail()` | Record fail, increment counter | `fail "description"` |
| `section()` | Print bold section header | `section "1. Title"` |
| `assert_file()` | Check file exists | `assert_file "/path/to/file" "label"` |
| `assert_dir()` | Check directory exists | `assert_dir "/path/to/dir" "label"` |
| `assert_gone()` | Check file/dir deleted | `assert_gone "/path" "label"` |
| `assert_exec()` | Check file executable | `assert_exec "/path/script.sh" "label"` |
| `assert_has()` | Check grep pattern found | `assert_has "$FILE" "pattern" "label"` |
| `assert_lacks()` | Check grep pattern NOT found | `assert_lacks "$FILE" "pattern" "label"` |
| `run_exit()` | Run command, verify exit code | `run_exit 0 "label" cmd arg1 arg2` |

**PowerShell Assertion Helpers:**

| Function | Purpose | Usage |
|----------|---------|-------|
| `Pass()` | Record pass, increment counter | `Pass "description"` |
| `Fail()` | Record fail, increment counter | `Fail "description"` |
| `Section()` | Print section header | `Section "1. Title"` |
| `Assert-File()` | Check file exists | `Assert-File "/path/to/file" "label"` |
| `Assert-Dir()` | Check directory exists | `Assert-Dir "/path/to/dir" "label"` |
| `Assert-Gone()` | Check file/dir deleted | `Assert-Gone "/path" "label"` |
| `Assert-Has()` | Check pattern in file | `Assert-Has "/path" "pattern" "label"` |
| `Assert-Lacks()` | Check pattern NOT in file | `Assert-Lacks "/path" "pattern" "label"` |

## Test Execution

**Running tests locally:**
```bash
# On Mac/Linux/WSL
cd C:/Users/Bruno/rn-harness
bash tests/test.sh

# On Windows PowerShell
cd C:\Users\Bruno\rn-harness
powershell -File tests\test.ps1
```

**CI/CD:** Not configured in repo; tests are manual/developer-focused

**Expected output (passing):**
- Green checkmarks for each pass
- Final summary: `Resultados: 50 ✅, 0 ❌`
- Exit code 0

**Expected output (failing):**
- Red X's for failures with error messages
- Final summary: `Resultados: 48 ✅, 2 ❌`
- Exit code 1 if any FAIL

## Coverage Areas

**What IS tested:**
- File system structure (all files present with correct names)
- Executable bit on scripts
- Install functionality (clone, copy, permissions)
- Idempotency (non-destructive second install)
- Force flag behavior (overwrite enabled)
- Uninstall with confirmation
- Uninstall with denial (cancellation)
- Template placeholder validation (balanced, documented)
- Hook exit codes (respect pnpm results, user input)
- Profile selection and .profile persistence
- SKILL.md path references

**What is NOT tested:**
- Actual React Native project creation (beyond installer)
- Actual pnpm command behavior (mocked)
- Network access (git repos are local bare clones)
- User interaction beyond confirmation prompts
- Different OS behaviors beyond bash/PowerShell (both supported)

---

*Testing analysis: 2026-08-11*

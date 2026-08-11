# Codebase Concerns

**Analysis Date:** 2026-08-11

## Tech Debt

### Uninstall Scripts Missing rn-doctor Skill Removal

**Issue:** Both `uninstall.sh` and `uninstall.ps1` only explicitly remove the `new-rn-project` skill, not the `rn-doctor` skill that's installed by `install.sh` (lines 80-91 in both installers loop over both skills).

**Files:** 
- `uninstall.sh` (lines 23-25)
- `uninstall.ps1` (lines 29-33)

**Impact:** Users running uninstall leave `~/.claude/skills/rn-doctor/` orphaned on disk. Repeated installs accumulate duplicate rn-doctor copies. Cleanup requires manual intervention.

**Fix approach:** Update both uninstall scripts to remove both `new-rn-project` and `rn-doctor` in the skills directory loop, matching the install script's approach.

---

### CLAUDE.md Template Syntax Error

**Issue:** Line 58 in `templates/CLAUDE.md.tmpl` has a trailing backslash that creates malformed output:
```
{{REGRAS_DO_DOMINIO — ex: "❌ Nunca exibir dados de outros usuários sem RLS"}}\
```

**Files:** `templates/CLAUDE.md.tmpl` (line 58)

**Impact:** When placeholder substitution occurs, the backslash gets included in generated CLAUDE.md files, breaking markdown rendering in some viewers. Regex replacements in new-rn-project skill may also fail if they don't account for the trailing backslash.

**Fix approach:** Remove trailing backslash from line 58. The line should end cleanly after the closing `}}`.

---

### Doctor Script Check Count Mismatch in Documentation

**Issue:** `scripts/doctor.sh` and `scripts/doctor.ps1` headers claim "22 health checks" but the scripts actually implement 24 checks (checks 23-24 are lineHeight and expo-av validation).

**Files:**
- `scripts/doctor.sh` (line 2)
- `scripts/doctor.ps1` (line 2)
- `skills/rn-doctor/SKILL.md` (line 6)

**Impact:** User confusion when cross-referencing. The SKILL.md documentation lists all 24 checks correctly in the table, but headers are inconsistent. Maintenance risk: future checks risk being numbered wrong.

**Fix approach:** Update both script headers to "24 health checks". Keep check numbers consistent between scripts and documentation.

---

## Shell Scripting Fragility

### Install.sh Missing Explicit Error Handling for git pull

**Issue:** `install.sh` line 41 runs `git pull --ff-only --quiet` within a `set -e` context, but doesn't explicitly validate the exit code. The PowerShell equivalent (`install.ps1` lines 46-47) explicitly checks `$LASTEXITCODE -ne 0`.

**Files:** `install.sh` (line 41)

**Impact:** If git pull fails (network error, merge conflict despite --ff-only), the script silently continues with potentially stale harness code. Users won't see a clear error message explaining the git operation failed.

**Fix approach:** Add explicit error handling:
```bash
if ! git -C "$HARNESS_DIR" pull --ff-only --quiet; then
  echo "❌ git pull falhou — repositório pode estar desatualizado"
  exit 1
fi
```

---

### Pre-push Hook Breaks in Non-Interactive Environments

**Issue:** `hooks/profiles/strict/pre-push.sh` line 10 uses `read -r answer` without checking if stdin is a TTY. This blocks automated/CI workflows, git-gui tools, and IDE integrations that can't provide interactive input.

**Files:** `hooks/profiles/strict/pre-push.sh` (lines 9-14)

**Impact:** CI/CD pipelines and automated deployment systems fail with "read: read error: 0: Invalid argument" or similar. Users on Windows with certain git tools may experience unexpected hangs. The hook is mandatory in the "strict" profile, so there's no workaround besides manual flag disabling.

**Fix approach:** Add TTY detection and skip interactive prompt in non-interactive mode:
```bash
if [ -t 0 ]; then
  printf "Testou no Android físico? [y/N] "
  read -r answer
  case "$answer" in
    y|Y) echo "✅ push liberado" ;;
    *)   echo "❌ Teste no Android físico antes de push."; exit 1 ;;
  esac
else
  echo "⚠️  Non-interactive mode — skipping device test prompt. Ensure tests passed."
fi
```

---

### Install Script Output Formatting Inconsistency

**Issue:** `install.sh` uses emoji checkmarks (✅) and arrows (→) while `install.ps1` uses "OK" and "->". Similar inconsistency in error messages ("❌" vs "ERRO:").

**Files:**
- `install.sh` (lines 96, 40, 49)
- `install.ps1` (lines 100, 45, 56)

**Impact:** Users switching between platforms or scripts get jarring UX. Terminal log aggregation tools may not parse emoji-based markers consistently. Inconsistent messaging undermines confidence in harness reliability.

**Fix approach:** Standardize output format across both scripts — either adopt emoji uniformly or use text-only markers. Document the chosen format in comments.

---

## Missing Stack Detection Dimensions

### No Detection for SQL/ORM Libraries

**Issue:** The stack detection in `skills/new-rn-project/SKILL.md` (lines 27-94) covers backend services (Supabase, Firebase, Convex) but doesn't explicitly detect ORM/query builder choices within those backends.

**Files:** `skills/new-rn-project/SKILL.md`

**Missing dimensions:**
- Drizzle vs Prisma for schema management
- Kysely for query building
- Explicit database client choice

**Impact:** Generated knowledge rules don't include ORM-specific guidance. A project using Drizzle won't auto-copy a theoretical `drizzle.md` rule. Developers must manually create patterns.

**Fix approach:** Add ORM detection dimension:
```
ORM:
  "drizzle-orm"  → Drizzle
  "@prisma/client" → Prisma
  "kysely"       → Kysely
  else           → "(nenhum)"
```

---

### No Detection for Error Tracking/Monitoring

**Issue:** No stack detection for error tracking (Sentry, LogRocket, Bugsnag) or observability platforms. This is a critical production concern, especially for App Store compliance.

**Files:** `skills/new-rn-project/SKILL.md`

**Impact:** Projects shipping to production without explicit error tracking guidance. New developers aren't warned about the importance of crash reporting before D15.

**Fix approach:** Add MONITORING dimension:
```
MONITORING:
  "sentry"       → Sentry
  "bugsnag-react-native" → Bugsnag
  "logrocket"    → LogRocket
  else           → "(nenhum)"
```

---

### No Detection for Form Libraries

**Issue:** `react-hook-form` is mentioned only in EXTRAS (line 92), not as a primary detection dimension. Projects heavily using forms get no automatic guidance.

**Files:** `skills/new-rn-project/SKILL.md`

**Impact:** Projects with complex forms miss form-specific patterns (validation, error display, performance). EXTRAS detection is loose—other libraries in EXTRAS like `expo-haptics` are more peripheral.

**Fix approach:** Elevate FORMS to a dimension:
```
FORMS:
  "react-hook-form" → React Hook Form
  "formik"          → Formik
  "zod"             → Zod (schema validation)
  else              → "(nenhum)"
```

---

### No Detection for AI/LLM Integration

**Issue:** No detection for LLM libraries (LangChain, Anthropic SDK, Ollama, Hugging Face) despite AI integration being increasingly common in modern apps.

**Files:** `skills/new-rn-project/SKILL.md`

**Impact:** Projects integrating Claude/ChatGPT/Ollama locally have no generated guidance. No selective rule copying for LLM-specific concerns (rate limiting, token counting, prompt safety).

**Fix approach:** Add LLM dimension:
```
LLM:
  "@anthropic-ai/sdk"  → Anthropic (Claude)
  "openai"             → OpenAI (ChatGPT)
  "langchain"          → LangChain
  "ollama"             → Ollama (local)
  else                 → "(nenhum)"
```

---

### No Detection for Real-Time/WebSocket Solutions

**Issue:** Stack detection includes Supabase (which implies Realtime) but doesn't explicitly detect WebSocket/real-time libraries like Socket.io, TanStack Query, or SWR subscriptions.

**Files:** `skills/new-rn-project/SKILL.md`

**Impact:** Apps using Socket.io for live features or GraphQL subscriptions lack generated guidance on connection lifecycle, reconnection strategies, and mobile-specific constraints.

**Fix approach:** Add REALTIME dimension:
```
REALTIME:
  "socket.io-client"  → Socket.io
  "graphql-ws"        → GraphQL WebSocket
  "@apollo/client"    → Apollo Subscriptions
  "supabase" (implied) → Supabase Realtime
  else                → "(nenhum)"
```

---

## Platform-Specific Gaps

### Windows Path Validation Missing

**Issue:** `install.ps1` correctly uses `Join-Path` for cross-platform paths, but doesn't validate or escape paths containing spaces or special characters before passing to git commands.

**Files:** `install.ps1` (lines 46, 53)

**Impact:** If `RN_HARNESS_DIR` or `CLAUDE_CONFIG_DIR` contain spaces (e.g., `C:\Users\John Doe\.claude`), git commands may fail silently because PowerShell quoting isn't always applied consistently.

**Fix approach:** Wrap all path variables in quotes in git invocations:
```powershell
git -C "$HarnessDir" pull --ff-only --quiet
# becomes
& git -C "$HarnessDir" pull --ff-only --quiet
```

---

### Pre-push Hook Not Portable to Windows

**Issue:** `hooks/profiles/strict/pre-push.sh` uses `read -r` (bash), not compatible with cmd.exe. While new-rn-project installs bash hooks, Windows developers using WSL may forget to configure core.hooksPath correctly.

**Files:** `hooks/profiles/strict/pre-push.sh`

**Impact:** Windows users on pure PowerShell workflows hit silent hook failures. The pre-push interactive check doesn't run, bypassing the "tested on Android" guardrail.

**Fix approach:** Create Windows-specific hook or add shebang detection to route to PowerShell equivalent. Document in SKILL.md that hooks require bash (WSL on Windows).

---

## Outdated or Hardcoded Versions

### Expo SDK 56 Hardcoded — Will Become Outdated

**Issue:** Multiple references to "SDK 56" as the target version are hardcoded in `doctor.sh`, `doctor.ps1`, `SKILL.md`, and README files. As SDK 57+ releases, these references become stale.

**Files:**
- `scripts/doctor.sh` (lines 112-123)
- `scripts/doctor.ps1` (lines 114-126)
- `skills/new-rn-project/SKILL.md` (line 78)
- `README.md` (lines 98)

**Impact:** Within 6-12 months (when SDK 57 ships), the harness will warn users about "outdated" SDK 56 and suggest upgrades, even though harness infrastructure hasn't been tested against SDK 57. Creates friction.

**Fix approach:** Consider introducing an SDK_VERSION configuration variable read from a `.harness-version` file or environment. Add a maintenance reminder: "Update SDK targets every 4 months."

---

### Node.js LTS Version Hardcoded to 20

**Issue:** `doctor.sh` line 38 checks `NODE_MAJ -ge 20` as minimum. When Node 22+ becomes LTS (late 2025), projects may fail checks despite being on a supported LTS.

**Files:** `scripts/doctor.sh` (lines 37-46), `scripts/doctor.ps1` (lines 42-49)

**Impact:** False failures as Node 24+ becomes mainstream. Maintenance burden to update hard-coded checks quarterly.

**Fix approach:** Instead of hardcoding major version, parse LTS schedule from a config or require >= 18 (safer backward compatibility). Add comment explaining version policy.

---

## Documentation Gaps

### Uninstall Procedure Incomplete

**Issue:** README.md and README.pt-BR.md don't document the complete uninstall procedure. Users may leave orphaned skills or templates behind.

**Files:** `README.md`, `README.pt-BR.md` (no uninstall section)

**Impact:** Repeated installs accumulate files. Developers switching to alternative frameworks can't cleanly remove rn-harness. Confusion about what `uninstall.sh` actually removes.

**Fix approach:** Add FAQ entry documenting the uninstall flow and what files are left behind (existing project files in ~/.claude are not removed).

---

### Hook Profile Switching Not Well Documented

**Issue:** While `install.sh` supports `--profile`, and `README.md` FAQ documents changing profiles, the process of **applying** the new profile to an existing project is under-documented.

**Files:** `README.md` lines 479-485, `install.sh` lines 18-31

**Impact:** Users change harness profile but forget to copy new hooks into existing projects. Pre-commit/pre-push behavior doesn't reflect chosen profile.

**Fix approach:** Add explicit step in FAQ with command to update existing project's hooks after changing profile globally.

---

## Fragile Areas

### Placeholder Substitution in new-rn-project Skill

**Issue:** The new-rn-project skill must perform complex placeholder substitution across multiple template types (CLAUDE.md.tmpl, docs, rules, stubs). Regex edge cases could break substitution.

**Files:** `skills/new-rn-project/` (implementation not in this repo, but SKILL.md describes the behavior)

**Impact:** If a user's APP_NAME contains special characters (e.g., "App & Co."), placeholder replacement may fail silently or create invalid CLAUDE.md. If LIBS_ADICIONAIS contains commas or special formatting, markdown rendering breaks.

**Fix approach:** Add validation in new-rn-project skill:
1. Validate all user inputs (APP_NAME, APP_SLUG, etc.) against safe character sets
2. Escape special characters before substitution
3. Validate generated files' markdown syntax before reporting success

---

### Doctor Script Regex Parsing Fragility

**Issue:** `doctor.sh` lines 114-127 parse version numbers with regex (`sed 's/v//; s/[\^~]//'`). This fails if package.json has comments or if version strings use non-standard formats.

**Files:** `scripts/doctor.sh` (lines 114-127, 140-150)

**Impact:** Misdetected versions (e.g., detecting "5" as major version in "0.5.6") lead to false FAIL results. Users with non-standard package.json formatting get incorrect guidance.

**Fix approach:** Use proper JSON parsing instead of regex. If bash doesn't have built-in JSON parsing, use `jq` (already common in dev environments) or require it.

---

### Interactive Prompts Not Skippable

**Issue:** `uninstall.sh` and `uninstall.ps1` both prompt for confirmation with `read -r answer` / `Read-Host`. In automated scripts, this blocks forever.

**Files:** `uninstall.sh` (lines 16-21), `uninstall.ps1` (lines 18-27)

**Impact:** Automated cleanup scripts (e.g., in CI or container builds) hang indefinitely waiting for user input.

**Fix approach:** Add `--yes` flag to both uninstall scripts to skip confirmation. Document in usage comment.

---

## Security Considerations

### Environment Variable Leakage Risk

**Issue:** While install scripts set HARNESS_REMOTE, CLAUDE_CONFIG_DIR, RN_HARNESS_DIR from environment, they don't validate these values. A malicious actor could set `HARNESS_REMOTE` to a different git URL, causing users to clone a compromised harness.

**Files:** `install.sh` (lines 12-14), `install.ps1` (lines 17-19)

**Impact:** Supply chain risk if environment is compromised. Users running `curl | sh` are especially vulnerable to HARNESS_REMOTE injection.

**Fix approach:** 
1. Document that HARNESS_REMOTE override is only for testing/development
2. Validate HARNESS_REMOTE against a whitelist of known URLs
3. Print a warning if non-default HARNESS_REMOTE is used

---

### No Verification of Copied Files

**Issue:** `install.sh` copies skills and templates without verifying file integrity (no checksums, no signature validation).

**Files:** `install.sh` (lines 63-91)

**Impact:** If a man-in-the-middle attack occurs during git clone, corrupted files are silently installed. Users can't verify that templates/skills match the intended harness version.

**Fix approach:** Generate SHA256 checksums for critical files (SKILL.md, templates, hooks) and verify after copy.

---

## Test Coverage Gaps

### Bash Tests Don't Verify PowerShell Feature Parity

**Issue:** `tests/test.sh` is comprehensive but tests bash scripts in isolation. `tests/test.ps1` has its own tests but may not cover all bash test scenarios.

**Files:** `tests/test.sh` (491 lines), `tests/test.ps1` (479 lines)

**Impact:** PowerShell implementation may have undiscovered bugs (e.g., path quoting, error handling) that bash tests wouldn't catch.

**Fix approach:** Add matrix testing that runs equivalent test cases against both `test.sh` and `test.ps1`, comparing outputs.

---

### No Integration Test for new-rn-project Workflow

**Issue:** Tests verify file structure and install/uninstall mechanics, but don't execute the full `/new-rn-project` wizard end-to-end with mock inputs.

**Files:** `tests/test.sh`, `tests/test.ps1`

**Impact:** A subtle bug in placeholder substitution or rule copying could pass all current tests but break real-world usage.

**Fix approach:** Add end-to-end test that mocks Claude Code environment and runs new-rn-project wizard with predefined inputs, then validates generated CLAUDE.md structure.

---

### Doctor Script Not Tested in Non-Interactive Mode

**Issue:** `doctor.sh` and `doctor.ps1` are designed to work in CI (via `--json` flag) but aren't tested in that mode.

**Files:** `scripts/doctor.sh`, `scripts/doctor.ps1`

**Impact:** A regression in `--json` output format could break CI integration tools silently.

**Fix approach:** Add test cases that run doctor with `--json` and validate JSON schema.

---

## Performance Bottlenecks

### Large Grep Operations in doctor.sh Without Limits

**Issue:** `doctor.sh` line 229 runs a recursive grep across the entire project to find hardcoded keys, with no limit on output. A large project with many matches could slow down the script.

**Files:** `scripts/doctor.sh` (lines 229-237)

**Impact:** On large codebases (100K+ lines), the grep operation takes seconds. The script only uses first 3 matches anyway (`head -3`), so all matches are computed wastefully.

**Fix approach:** Use `grep -m 3` or piped `head -3` earlier to limit search.

---

## Scaling Limits

### No Support for Monorepo Patterns

**Issue:** Doctor checks assume a single project root (checks for `package.json`, `CLAUDE.md` in project root). Monorepos with multiple packages fail or require running doctor in each workspace.

**Files:** `scripts/doctor.sh`, `scripts/doctor.ps1`

**Impact:** Teams using pnpm workspaces or yarn workspaces can't use doctor at the repository root. They must run it in each package directory, losing benefits of centralized checks.

**Fix approach:** Add optional `--workspaces` flag to doctor that auto-detects pnpm/yarn workspaces and runs checks against each package's package.json.

---

### Template Copy Inefficient for Large Projects

**Issue:** `install.sh` line 67-70 copies entire templates directory with `cp -rf` and `cp -rn`. On network filesystems or with many files, this could be slow.

**Files:** `install.sh` (lines 63-71)

**Impact:** First install on slow storage takes noticeably longer. No progress feedback to user during copy.

**Fix approach:** Add progress indicator or use faster copy method if available. Consider lazy-loading templates on first use.

---

---

*Concerns audit: 2026-08-11*

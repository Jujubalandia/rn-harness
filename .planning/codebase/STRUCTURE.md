# Codebase Structure

**Analysis Date:** 2026-08-11

## Directory Layout

```
rn-harness/
├── install.sh                      # Installer (bash)
├── install.ps1                     # Installer (PowerShell)
├── uninstall.sh                    # Remove framework
├── uninstall.ps1                   # Remove framework (Windows)
├── README.md                        # English docs
├── README.pt-BR.md                 # Portuguese docs
│
├── scripts/                        # CLI entry points (non-interactive)
│   ├── doctor.sh                   # 24-check health script (bash)
│   └── doctor.ps1                  # 24-check health script (PowerShell)
│
├── skills/                         # Skill specifications (Claude Code entry points)
│   ├── new-rn-project/
│   │   └── SKILL.md               # Wizard: init, stack detection, rules, hooks
│   └── rn-doctor/
│       └── SKILL.md               # Health check: 24 checks + fixes
│
├── hooks/                          # Git hook reference & profiles
│   ├── pre-commit.sh              # Strict profile reference
│   ├── pre-commit.ps1
│   ├── pre-push.sh                # Strict profile reference
│   ├── pre-push.ps1
│   └── profiles/                  # Profiles copied to projects
│       ├── minimal/
│       │   ├── pre-commit.sh      # Typecheck only
│       │   ├── pre-commit.ps1
│       │   ├── pre-push.sh        # quality:full + Android confirm
│       │   └── pre-push.ps1
│       ├── standard/
│       │   ├── pre-commit.sh      # tsc + lint + format + quality:full at push
│       │   ├── pre-commit.ps1
│       │   ├── pre-push.sh
│       │   └── pre-push.ps1
│       └── strict/                # Default profile
│           ├── pre-commit.sh      # tsc + lint + format + fta (score-cap 60)
│           ├── pre-commit.ps1
│           ├── pre-push.sh        # quality:full + Android confirm
│           └── pre-push.ps1
│
├── templates/                      # Project templates (copied to ~/.claude/templates/rn-20days/)
│   ├── CLAUDE.md.tmpl             # Project spec template with {{PLACEHOLDERS}}
│   ├── DECISIONS.md.stub          # Initial ADR log
│   ├── TODO.md.stub               # Initial backlog
│   │
│   ├── docs/                      # 6-phase documentation templates (no placeholders)
│   │   ├── 01-spec.md             # D1-D2: Problem, market, competitors, viral loop
│   │   ├── 02-dev-plan.md         # D1-D20: Phases, milestones, DoD, blockers
│   │   ├── 03-quality-gates.md    # Ongoing: Quality pyramid (tsc → lint → prettier → fta)
│   │   ├── 04-testing.md          # D13-D15: Test tiers, device matrix, Maestro
│   │   ├── 05-store-launch.md     # D15-D17: Assets, metadata, submission
│   │   └── 06-marketing.md        # D17-D20: Calendar, platform templates, landing
│   │
│   ├── rules/                     # 15 knowledge rules (selectively copied per stack)
│   │   ├── patterns.md            # Component structure, hooks, barrel exports, error boundaries (always)
│   │   ├── performance.md         # FlatList, memoization, bundle size, expo-image (always)
│   │   ├── security.md            # Secure-store, env vars, deep link validation (always)
│   │   ├── accessibility.md       # 44pt targets, t() in labels, screen reader (always)
│   │   ├── forbidden.md           # lineHeight bug, expo-av deprecated, AsyncStorage (always)
│   │   │
│   │   ├── expo-router.md         # File-based routing, deep links, NativeTabs (if Expo Router)
│   │   ├── supabase.md            # Auth + SecureStore, RLS, Edge Functions, realtime (if Supabase)
│   │   ├── i18next.md             # t(), Trans, CLDR plurals, Intl.* (if i18next)
│   │   ├── zustand.md             # Stores per domain, selector pattern, persist (if Zustand)
│   │   ├── react-native-reanimated.md  # Shared values, worklets, runOnJS (if Reanimated v3)
│   │   ├── react-native-gesture-handler.md  # Gesture.Pan/Tap, useMemo (if GH v2)
│   │   ├── styling.md             # StyleSheet.create, design tokens, dark mode (if StyleSheet)
│   │   ├── expo-video.md          # VideoView, useVideoPlayer, cleanup (if expo-video)
│   │   ├── revenue-cat.md         # usePremium hook, paywall, restore (if RevenueCat)
│   │   └── expo-notifications.md  # Push token, handler, listeners (if expo-notifications)
│   │
│   └── claude/                    # Safety configs (copied to project .claude/)
│       ├── settings.json          # Denylist: eas submit, db reset, force push, --no-verify
│       └── hooks/
│           └── pre-tool-use.sh    # Runtime blocker: intercepts destructive patterns
│
├── tests/                          # Framework validation
│   ├── test.sh                    # 164 checks for framework itself (bash)
│   └── test.ps1                   # 164 checks for framework itself (PowerShell)
│
├── .planning/                      # Codebase documentation (this directory)
│   └── codebase/
│       ├── ARCHITECTURE.md
│       └── STRUCTURE.md
│
└── .claude/                        # Framework development configs
    ├── settings.json              # Claude Code permissions for framework dev
    └── rules/                     # If desired, framework-specific rules
```

## Directory Purposes

**`scripts/`:**
- Purpose: Standalone CLI tools for health checks and automation
- Contains: doctor.sh (24 checks, outputs human-readable or JSON), doctor.ps1 (Windows equivalent)
- Key files: 
  - `doctor.sh` (430+ lines) — Implements 24 checks: node, pnpm, git, eas, package.json, CLAUDE.md, .gitignore, .env commits, .claude/rules/, Expo SDK, RN version, Reanimated, tsconfig strict, babel plugin, ESLint rules, pnpm scripts, secure-store, hardcoded keys, .git/, hooks path, app.json bundle/package, eas.json, lineHeight, expo-av
  - `doctor.ps1` — PowerShell equivalent of doctor.sh

**`skills/new-rn-project/`:**
- Purpose: Interactive wizard that initializes React Native projects with rn-harness
- Contains: SKILL.md (implementation spec for Claude Code)
- Key content:
  - Stack detection logic (13 dimensions: state, nav, styling, backend, i18n, animation, gesture, storage, image-gen, testing, video, monetization, notifications)
  - Placeholder substitution rules for CLAUDE.md, DECISIONS.md, TODO.md
  - Selective rule copying based on detected stack
  - Hook profile application
  - Next-steps checklist generation

**`skills/rn-doctor/`:**
- Purpose: Interactive health check skill — runs doctor.sh and explains FAILs
- Contains: SKILL.md (orchestration spec)
- Key content:
  - Parse doctor.sh output
  - For each FAIL: explain root cause, offer fix, execute after confirmation
  - For each WARN: contextualize (e.g., WARN about missing app.json is OK on D1)

**`hooks/`:**
- Purpose: Store git hook implementations and profiles
- Contains: Reference hooks (strict) + 3 profiles (minimal, standard, strict)
- Key files:
  - `hooks/profiles/minimal/pre-commit.sh` — `pnpm typecheck` only (fast for D1-D5 iteration)
  - `hooks/profiles/standard/pre-commit.sh` — `pnpm typecheck && pnpm lint && pnpm format:check`
  - `hooks/profiles/strict/pre-commit.sh` — standard + `pnpm fta` (score-cap 60) — default, recommended
  - All pre-push.sh versions run `pnpm quality:full` + Android device confirmation

**`templates/`:**
- Purpose: Provide skeletons for project structure, documentation, knowledge rules, and safety configs
- Contains:
  - `CLAUDE.md.tmpl` — Project spec with {{APP_NAME}}, {{STACK}}, {{PLACEHOLDERS}} filled by new-rn-project
  - `DECISIONS.md.stub`, `TODO.md.stub` — Initial ADR and backlog stubs
  - `docs/` — 6 phase templates (no substitution, copied as-is)
  - `rules/` — 15 knowledge rules (selective: only relevant to detected stack copied to projects)
  - `claude/` — settings.json (permission denylist) and pre-tool-use.sh (runtime pattern blocker)

**`tests/`:**
- Purpose: Validate the framework itself (not project testing)
- Contains: test.sh, test.ps1 (164 checks each)
- Scope: Checks installer, template presence, skill specs, hook syntax, etc.
- Run by: Contributors before pushing (`bash tests/test.sh`, must finish with 0 failures)

**`.claude/`:**
- Purpose: Framework development configuration (not for projects, which get their own `.claude/` via new-rn-project)
- Contains: settings.json for framework dev, optional rules for working on rn-harness itself

## Key File Locations

**Entry Points:**
- `install.sh` — Initial framework installation (bash)
- `install.ps1` — Initial framework installation (PowerShell)
- `scripts/doctor.sh` — CLI health checks (called by /rn-doctor skill and pre-commit/pre-push hooks)
- `skills/new-rn-project/SKILL.md` — Project wizard invocation point
- `skills/rn-doctor/SKILL.md` — Health check skill invocation point

**Configuration (Installed to Home):**
- `~/.rn-harness/` — Cloned repo (read-only after install)
- `~/.rn-harness/.profile` — User's active hook profile (minimal/standard/strict)
- `~/.rn-harness/scripts/doctor.sh` — CLI doctor (linked from templates/scripts/)
- `~/.claude/templates/rn-20days/` — Installed templates (copied from `templates/`)
- `~/.claude/skills/new-rn-project/` — Installed wizard skill
- `~/.claude/skills/rn-doctor/` — Installed health check skill

**Core Logic:**
- `templates/CLAUDE.md.tmpl` — Project spec template with all {{PLACEHOLDER}} rules
- `templates/docs/` — 6-phase doc templates
- `templates/rules/` — 15 knowledge rules (source of truth; copied selectively to projects)
- `templates/claude/settings.json` — Permission denylist (source of truth)
- `templates/claude/hooks/pre-tool-use.sh` — Runtime blocker (source of truth)
- `hooks/profiles/*/` — Pre-commit/pre-push implementations (copied to project .githooks/)

**Testing & Validation:**
- `tests/test.sh` — Framework validation (164 checks)
- `README.md` — Usage documentation (20-day flow, installation, features)

## Naming Conventions

**Files:**
- **Shell scripts:** `.sh` (bash) and `.ps1` (PowerShell), both in same directory (e.g., `doctor.sh` + `doctor.ps1`)
- **Templates:** `.tmpl` for fill-in templates (e.g., `CLAUDE.md.tmpl`), `.stub` for initial content (e.g., `TODO.md.stub`)
- **Skill specs:** `SKILL.md` (required by Claude Code framework)
- **Knowledge rules:** `rule-name.md` (e.g., `supabase.md`, `patterns.md`) with frontmatter `---` metadata
- **Git hooks:** `pre-commit.sh`, `pre-push.sh` (no `.git/` prefix; copied to `.githooks/`)

**Directories:**
- **Feature-scoped:** `skills/skill-name/`, `hooks/profiles/profile-name/`
- **Template-scoped:** `templates/docs/`, `templates/rules/`, `templates/claude/`
- **Platform-specific:** Scripts are dual bash + PowerShell (e.g., `install.sh` + `install.ps1`, both in root)

## Where to Add New Code

**New Quality Check (add to doctor.sh):**
- File: `scripts/doctor.sh`
- Pattern: Add check after line 300 (after check 24, before summary), call `_out` function
- Example: `_out FAIL 25 "description" "fix: command"` or `_out OK 25 "description"`
- Test: Run `bash tests/test.sh` to ensure 165 total checks
- Also update: `skills/rn-doctor/SKILL.md` (add to "The 24 checks" table if customer-facing)

**New Knowledge Rule (add to templates/rules/):**
- File: Create `templates/rules/my-feature.md`
- Pattern: Start with frontmatter:
  ```yaml
  ---
  description: Brief description of what this rule covers
  globs: "**/*.{ts,tsx}"  # Glob pattern for Claude to auto-load
  alwaysApply: false
  ---
  ```
- Content: Use markdown with code examples, patterns, anti-patterns
- Conditional copying: Add logic to `skills/new-rn-project/SKILL.md:Passo 4I` if stack-dependent (e.g., "if BACKEND == MyTech then copy my-feature.md")
- Always copy: If relevant to all projects, it will be auto-copied in step 4I (add to "sempre" list)

**New Phase Doc (add to templates/docs/):**
- File: Create `templates/docs/07-post-launch.md` (following numbering)
- Pattern: Follow existing doc structure (headings, checklists, timeline markers like D18-D20)
- Copy logic: Already auto-copied by new-rn-project step 4D (no need to add conditional)
- Test: Create a test project, verify doc appears

**New Hook Profile (add to hooks/profiles/):**
- Scenario: Want a "ultra-strict" profile (tsc + lint + format + FTA + tests at pre-commit, security audit at pre-push)
- Files:
  - `hooks/profiles/ultra-strict/pre-commit.sh` — runs all checks
  - `hooks/profiles/ultra-strict/pre-commit.ps1` — PowerShell equivalent
  - `hooks/profiles/ultra-strict/pre-push.sh` — adds security checks
  - `hooks/profiles/ultra-strict/pre-push.ps1` — PowerShell equivalent
- Update: `install.sh` and `install.ps1` to accept `--profile ultra-strict`
- Validate: Test with `bash tests/test.sh`

**New Destructive Op Block (add to pre-tool-use.sh or settings.json):**
- Declarative: Add pattern to `templates/claude/settings.json` deny array (for static blocking)
  - Example: `"Bash(rm -rf /projects/*)"`
- Runtime: Add regex to `templates/claude/hooks/pre-tool-use.sh` BLOCKED array
  - Example: `"rm -rf /projects"`
- Choose:
  - Use settings.json for stable, known patterns (eas submit, force push, etc.)
  - Use pre-tool-use.sh for complex patterns (SQL injections, variable interpolations)

**New Installer Feature (add to install.sh):**
- File: `install.sh` and `install.ps1`
- Pattern: Add new argument handling before line 20 (`while [ "$#" -gt 0 ]`), new logic before the summary at end
- Guideline: Keep installer minimal — mostly copying files, not complex logic
- Test: Manual run and `bash tests/test.sh`

## Special Directories

**`~/.claude/templates/rn-20days/` (Installed):**
- Purpose: Source of truth for project templates (copied from repo `templates/`)
- Generated: No — manually created by repo maintainers
- Committed: Yes — part of repo `templates/`
- Lifecycle: Updated when `install.sh --force` is run
- Modification: Users should not edit; if changes needed, update repo `templates/` and re-run installer

**`~/.rn-harness/` (Cloned Repo):**
- Purpose: Local clone of rn-harness repository
- Generated: Yes — by `install.sh` via `git clone`
- Committed: N/A — entire directory is git repo
- Lifecycle: Updated by `git pull --ff-only` in subsequent `install.sh` runs
- Modification: Can edit locally for testing; changes lost on next install

**`project/.claude/` (Copied from Templates):**
- Purpose: Per-project safety configs and knowledge rules
- Generated: Yes — by `/new-rn-project` from `~/.claude/templates/rn-20days/claude/`
- Committed: Yes — should be committed to project git repo
- Lifecycle: Created once at project init; can be manually edited afterwards
- Modification: Users commonly edit `project/.claude/rules/` to customize knowledge or remove irrelevant rules

**`project/.githooks/` (Copied from Profiles):**
- Purpose: Per-project quality gates (git hooks)
- Generated: Yes — by `/new-rn-project` from `~/.rn-harness/hooks/profiles/$PROFILE/`
- Committed: Yes — should be committed (they're executable scripts)
- Lifecycle: Created once; can be swapped by copying new profile hooks
- Modification: Users can edit to adjust strictness (e.g., change score-cap in FTA call)

**`project/docs/` (Copied from Templates):**
- Purpose: 20-day phase documentation
- Generated: Yes — by `/new-rn-project` from `~/.claude/templates/rn-20days/docs/`
- Committed: Yes — essential project documentation
- Lifecycle: Created once; users fill in as project progresses
- Modification: Users edit to track spec, dev plan, quality gates, testing, store launch, marketing

---

*Structure analysis: 2026-08-11*

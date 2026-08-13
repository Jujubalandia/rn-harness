# rn-harness

[🇧🇷 Português](README.pt-BR.md) | **🇺🇸 English**

Development framework to ship React Native apps to the App Store + Play Store in ≤20 days.

Built on Claude Code with specialized skills, quality gates, and a project initialization wizard.

New here? See [Getting Started](docs/GETTING_STARTED.md) for the condensed empty-folder → shipped-app walkthrough.

---

## What it is

A set of templates, skills, and hooks that standardize the full flow:

```
Spec → UX → Dev → QA → Store → Marketing
```

The core is the `/rn-harness:new-rn-project` skill: open a directory (new or existing), type the command, and Claude automatically detects the stack via `package.json`, configures the project, and creates the full structure — filled CLAUDE.md, docs/, git hooks from the selected profile, and selective knowledge rules.

---

## Prerequisites

| Tool | Min version | Install |
|------|-------------|---------|
| Node.js | 20 LTS | `nvm install 20` |
| pnpm | any | `npm i -g pnpm` |
| Claude Code | latest | `npm i -g @anthropic-ai/claude-code` |
| Git | any | system |

---

## Installation

Installed as a Claude Code plugin — same commands on every OS, no clone, no shell script.

```
/plugin marketplace add Jujubalandia/rn-harness
/plugin install rn-harness@rn-harness
```

That's it. Skills, templates, doctor scripts, and hook profiles ship inside the plugin — nothing to place manually. `.sh` git hooks installed later work as-is via Git for Windows' built-in bash on Windows.

Update with `/plugin update rn-harness`, remove with `/plugin uninstall rn-harness`. See [Claude Code plugin docs](https://code.claude.com/docs/en/plugins) if `/plugin` commands are unfamiliar.

---

## Usage — New Project

```bash
mkdir ~/projects/my-app && cd ~/projects/my-app
claude    # opens Claude Code
```

In Claude Code:

```
/rn-harness:new-rn-project
```

### What the wizard does

**1. Auto-detects the stack via `package.json`** (if present) across 13 dimensions:

| Dimension | What it detects |
|-----------|----------------|
| State management | Zustand · Redux Toolkit · Jotai |
| Navigation | Expo Router · React Navigation |
| Styling | NativeWind · Tamagui · StyleSheet.create |
| Backend | Supabase · Firebase · Convex |
| i18n | i18next + expo-localization |
| Animation | Reanimated v3 |
| Gesture | Gesture Handler v2 |
| Storage | expo-secure-store only (OK) · both present (WARNING) · AsyncStorage only (FAIL) |
| Image gen | Skia · react-native-view-shot |
| Testing | RNTL · Detox |
| Video | expo-video (OK) · expo-av (WARNING: deprecated) |
| Monetization | RevenueCat · react-native-iap |
| Notifications | expo-notifications |

Shows detection table and asks for confirmation before proceeding.

**2. Only asks what it can't detect:** name, description, languages, monetization, hook profile.

**3. Creates the structure:**
- `CLAUDE.md` filled in (no placeholders)
- `DECISIONS.md` + `TODO.md` initialized
- `docs/` with the 6 phase templates
- `.githooks/pre-commit` and `pre-push` from the selected profile
- `.claude/rules/` with **selective** knowledge rules (only those relevant to the detected stack)

**4. Generates a next-steps checklist** tailored to the stack — only suggests installing dependencies not already in `package.json`, and runs `npx expo install --fix` to fix versions incompatible with SDK 56.

---

## Doctor — Health Check

24 project health checks. Runs on any existing project.

```
/rn-harness:rn-doctor
```

Explains each FAIL and runs the suggested fix after confirmation. The underlying scripts (`scripts/doctor.sh` / `.ps1`) ship inside the installed plugin — for CI or manual runs outside Claude Code, find the plugin's install path with `claude plugin list` and invoke the script directly, or pass `--json` for structured output.

### What it checks

| Category | Checks |
|----------|--------|
| Environment | node >= 20, pnpm, git, eas-cli |
| Structure | package.json, CLAUDE.md, .gitignore covers .env*, .claude/rules/ |
| Security | .env* not committed, no hardcoded keys in .ts/.tsx |
| SDK versions | Expo 56, RN 0.76.x, Reanimated v3 (not v4) |
| Config | tsconfig strict, babel plugin reanimated, ESLint no-color-literals, pnpm scripts |
| Dep security | expo-secure-store present, AsyncStorage absent from direct deps |
| Git/Hooks | .git/ initialized, core.hooksPath = .githooks |
| Store | app.json bundleIdentifier + packageName, eas.json |
| Forbidden patterns | `lineHeight` in StyleSheet (Android bug), `expo-av` imported (deprecated) |

### Output

```
  [OK]   node v22.x >= 20
  [WARN] CLAUDE.md missing (rn-harness not initialized)
  [FAIL] tsconfig.json missing "strict": true
         fix: Add '"strict": true' to compilerOptions
  ...
  OK: 20  WARN: 2  FAIL: 2  / 24 total
```

Exit 0 = no FAILs (OK and WARN pass). Exit 1 = at least one FAIL.

### When to run

- D1: right after `/rn-harness:new-rn-project`
- After cloning on a new machine
- When pre-commit hook fails without a clear reason
- Before `eas build --profile production`

---

## Claude Code Security

Two complementary mechanisms block destructive operations before execution:

### `settings.json` — declarative allowlist/denylist

Created at `.claude/settings.json` by `/rn-harness:new-rn-project`. Blocks without prompt:

```json
{ "permissions": { "deny": [
  "Bash(eas submit*)",
  "Bash(supabase db reset*)",
  "Bash(git push --force*)",
  "Bash(git commit *--no-verify*)",
  "Bash(rm -rf /*)"
]}}
```

### `.claude/hooks/pre-tool-use.sh` — runtime blocking

Script executed by Claude Code before each tool call. Intercepts destructive patterns not covered by `settings.json` (e.g., command variants, SQL):

```
🚫 BLOCKED: 'supabase db reset' requires explicit confirmation.
   Run manually in the terminal if you're sure.
```

Blocked patterns: `eas submit`, `supabase db reset`, `git push --force`, `git commit --no-verify`, `rm -rf /`, `git reset --hard`, `DROP TABLE`, `truncate cascade`, `npx expo publish`.

Both files are copied by `/rn-harness:new-rn-project` from the plugin's own `templates/claude/` directory.

---

## Hook Profiles

Three quality gate levels, selectable per project by the `/rn-harness:new-rn-project` wizard:

| Profile | pre-commit | pre-push |
|---------|-----------|---------|
| `minimal` | typecheck | Android confirmation |
| `standard` | typecheck + lint + format | quality:full + Android confirmation |
| `strict` *(default)* | typecheck + lint + format + fta | quality:full + Android confirmation |

The wizard asks which profile to use, remembers your choice for next time (stored in the plugin's persistent data dir), and copies the corresponding hooks from `git-hooks/profiles/<profile>/` into the new project's `.githooks/`.

**Switch profile on an existing project:** re-run `/rn-harness:new-rn-project` and pick a different profile when asked, or copy the hooks manually — find the plugin's install path with `claude plugin list`, then:

```bash
cp <plugin-path>/git-hooks/profiles/strict/pre-commit.sh .githooks/pre-commit
cp <plugin-path>/git-hooks/profiles/strict/pre-push.sh   .githooks/pre-push
```

---

## Knowledge Rules

15 `.md` files that Claude loads automatically based on files being edited (`globs`). Installed at `.claude/rules/` in each new project by `/rn-harness:new-rn-project`.

**Rules are selective:** the wizard copies only those relevant to the detected stack. A project without Supabase won't get `supabase.md`. A project without expo-video won't get `expo-video.md`.

| Rule | Copied when | Covers |
|------|-------------|--------|
| `patterns.md` | always | folder structure, custom hooks, barrel exports, error boundaries |
| `performance.md` | always | FlatList, memoization, bundle size, expo-image |
| `security.md` | always | expo-secure-store, env vars, deep link validation |
| `accessibility.md` | always | 44pt targets, t() in accessibilityLabel, screen reader |
| `forbidden.md` | always | lineHeight (Android bug), expo-av deprecated, AsyncStorage for secrets |
| `expo-router.md` | Navigation = Expo Router | file-based routing, NativeTabs, SF Symbols/MD icons, deep links |
| `supabase.md` | Backend = Supabase | auth + SecureStore, RLS, Edge Functions, realtime |
| `i18next.md` | i18n = i18next | t(), Trans, CLDR plurals, Intl.* dates/numbers |
| `zustand.md` | State = Zustand | stores per domain, selector pattern, persist + SecureStore |
| `react-native-reanimated.md` | Animation = Reanimated v3 | v3: shared values, worklets, runOnJS, layout animations |
| `react-native-gesture-handler.md` | Gesture = GH v2 | v2 Builder API: Gesture.Pan/Tap, mandatory useMemo |
| `styling.md` | Styling = StyleSheet.create | StyleSheet.create, design tokens, dark mode |
| `expo-video.md` | Video = expo-video | VideoView, useVideoPlayer, cleanup, expo-audio |
| `revenue-cat.md` | Monetization = RevenueCat | usePremium hook, paywall, restore, sandbox testing |
| `expo-notifications.md` | Notifications = expo-notifications | push token, handler, listeners, local scheduling |

**Target versions:** Expo SDK 56 · RN 0.76 · Reanimated v3 · GH v2 · React 18

> Difference from ERNE: rules here are **specific to the harness stack** (Supabase, i18next, Expo SDK 56), not generic for any RN project.

---

## Windows Notes

Extra PowerShell-specific details not already covered in Installation above.

### Test PowerShell suite (contributors)

Run from a local clone of this repo:

```powershell
powershell -File tests\test.ps1
```

### Environment variables

| Variable | Effect |
|----------|--------|
| `HARNESS_ANDROID_OK` | `$env:HARNESS_ANDROID_OK` — skip the interactive "tested on physical Android?" prompt in the pre-push hook |

---

## Update

```
/plugin update rn-harness
```

---

## Repo structure

```
rn-harness/
├── .claude-plugin/
│   ├── plugin.json           ← plugin manifest
│   └── marketplace.json      ← self-hosted marketplace listing (source: "./")
├── scripts/
│   ├── doctor.sh              ← 24 health checks (bash)
│   └── doctor.ps1             ← 24 health checks (PowerShell)
├── templates/
│   ├── CLAUDE.md.tmpl        ← project template (with {{PLACEHOLDERS}})
│   ├── DECISIONS.md.stub     ← initial ADR log
│   ├── TODO.md.stub          ← initial backlog
│   ├── docs/
│   │   ├── 01-spec.md        ← spec + market research (D1-D2)
│   │   ├── 02-dev-plan.md    ← 20-day plan + milestones
│   │   ├── 03-quality-gates.md  ← quality pyramid
│   │   ├── 04-testing.md     ← test tiers + device matrix
│   │   ├── 05-store-launch.md   ← App Store + Play Store checklist
│   │   └── 06-marketing.md   ← D-7→D+14 calendar
│   ├── rules/                ← 15 knowledge rules (selectively copied)
│   └── claude/
│       ├── settings.json         ← destructive ops denylist
│       └── hooks/
│           └── pre-tool-use.sh   ← runtime blocking by pattern
├── skills/
│   ├── new-rn-project/       ← wizard: init, stack detection, rules, hooks
│   └── rn-doctor/            ← health check: 24 checks + fixes
├── git-hooks/
│   ├── pre-commit.sh / .ps1  ← strict (reference)
│   ├── pre-push.sh / .ps1    ← strict (reference)
│   └── profiles/
│       ├── minimal/          ← pre-commit: typecheck only
│       ├── standard/         ← pre-commit: typecheck+lint+format
│       └── strict/           ← pre-commit: +fta (default)
└── tests/
    ├── test.sh               ← checks (bash)
    └── test.ps1              ← PowerShell equivalent
```

---

## Templates — What each doc does

| Doc | Phase | Purpose |
|-----|-------|---------|
| `01-spec.md` | D1-D2 | Problem, market, competitors, Cut/Keep, viral loop |
| `02-dev-plan.md` | D1-D20 | Phases, milestones, DoD, common blockers |
| `03-quality-gates.md` | ongoing | tsc→ESLint→Prettier→FTA→Golden Paths pyramid |
| `04-testing.md` | D13-D15 | Test tiers, device matrix, Maestro setup |
| `05-store-launch.md` | D15-D17 | Assets, metadata, submission checklist |
| `06-marketing.md` | D17-D20 | Calendar, platform templates, landing page |

---

## 20-Day Timeline

| Phase | Days | Focus | Main doc |
|-------|------|-------|---------|
| Spec + Setup | D1-D3 | Specification + running environment | 01-spec |
| Core Dev | D4-D10 | MVP features (1/day) | 02-dev-plan |
| Polish | D11-D13 | i18n, a11y, loading states | 03-quality-gates |
| QA + Store Prep | D14-D15 | Production build + assets | 04-testing + 05-store-launch |
| Submission | D16-D17 | Upload AAB/IPA + review | 05-store-launch |
| Marketing | D18-D20 | Launch posts + landing page | 06-marketing |

---

## D1→D20 Step-by-Step

Operational table: each command/step in the flow, which day it belongs to, its classification, input/output artifacts, and the next step.

**Classification:**
- **Internal Claude** — native Claude Code tool action executed automatically in the session (Read/Edit/Write), not a command typed by the user.
- **External** — terminal/shell command or third-party tool outside Claude Code (npm, pnpm, eas, git, curl, store consoles).
- **Skill** — `/command` or subagent invoked inside Claude Code (bundled or marketplace).
- **Manual Edit** — manual content editing by the user in a file/doc, no command executed.

| Day | Command | Classification | Artifact(s) touched/created | Resulting/modified artifact(s) | Next step |
|-----|---------|-----------------|------------------------------|----------------------------------|-----------|
| D1 | `nvm install 20` | External | Node.js (machine) | Node 20 LTS active | install pnpm |
| D1 | `npm i -g pnpm` | External | — | pnpm CLI available | install Claude Code |
| D1 | `npm i -g @anthropic-ai/claude-code` | External | — | Claude Code CLI installed | install rn-harness plugin |
| D1 | `/plugin marketplace add Jujubalandia/rn-harness` + `/plugin install rn-harness@rn-harness` | External | remote rn-harness repo | plugin installed (skills, templates, scripts, git-hooks bundled inside) | create project folder |
| D1 | `mkdir ~/projects/my-app && cd ...` | External | filesystem | project directory | open Claude Code |
| D1 | `claude` | External | — | Claude Code session open | run wizard |
| D1 | `/rn-harness:new-rn-project` | Skill | `package.json` (if present) | `CLAUDE.md`, `DECISIONS.md`, `TODO.md`, `docs/01-spec.md`…`06-marketing.md`, `.githooks/`, `.claude/rules/`, `.claude/settings.json`, `.claude/hooks/pre-tool-use.sh` | run `/rn-harness:rn-doctor` |
| D1 | `/rn-harness:rn-doctor` | Skill | CLAUDE.md, package.json, tsconfig.json, .env*, .git/, app.json, eas.json | 24-check report (OK/WARN/FAIL) | fix reported FAILs |
| D1 | Fill prep checklist (problem, audience, competitors, differentiator, cut/keep, monetization, viral loop, risks) | Manual Edit | `docs/01-spec.md` (empty) | `docs/01-spec.md` with draft answers | research competitors (D2) |
| D1 | `npx expo install --fix` | External | package.json / node_modules | versions compatible w/ SDK 56 | fix remaining doctor FAILs |
| D2 | `/firecrawl-search` | Skill (marketplace) | search query | list of competitors | pick top 3 |
| D2 | `/firecrawl-scrape` | Skill (marketplace) | competitor URL | extracted content | fill competitor table |
| D2 | Fill competitors + Cut/Keep + diff + viral loop | Manual Edit | `docs/01-spec.md` | `docs/01-spec.md` complete (ready to approve before D3 — not a formal DoD/Milestone) | approve spec, move to D3 |
| D3 | Define design system (colors, typography, 8pt grid) | Manual Edit | `docs/01-spec.md` | design system section filled | map screen flow |
| D3 | Map screen flow (text) | Manual Edit | `docs/01-spec.md` | screen flow documented | create Expo project + Supabase |
| D3 | `npx create-expo-app` + Supabase config | External | filesystem / Supabase dashboard | Expo project + Supabase client configured | implement auth |
| D3 | Implement auth (Google/Apple/email) | Internal Claude | auth files/hooks | working login | implement navigation |
| D3 | `design-token-guardian` (before committing styles) | Skill (subagent) | new style/screen files | hardcoded-color flag | fix, commit |
| D3 | Implement navigation between screens | Internal Claude | route files | 2+ navigable screens | validate DoD D3 |
| D3 | Test on physical Android (login + nav) | External (manual) | dev build on device | **DoD D3 / Milestone M1 confirmed:** app opens on physical Android, login works, 2+ navigable screens | start D4 |
| D4 | Implement core feature 1 | Internal Claude | feature code | feature 1 working | `/code-review` |
| D4 | `/code-review` | Skill (marketplace) | feature 1 diff | findings report | fix, commit |
| D5 | Implement core feature 2 | Internal Claude | feature code | feature 2 working | `/code-review` |
| D5 | `/code-review` | Skill | feature 2 diff | findings | fix, commit |
| D6 | Implement core feature 3 | Internal Claude | feature code | feature 3 working | `/code-review` |
| D6 | `/code-review` | Skill | feature 3 diff | findings | fix, commit |
| D7 | Implement core feature 4 | Internal Claude | feature code | feature 4 working | `/code-review` |
| D7 | `/code-review` | Skill | feature 4 diff | findings | fix, commit |
| D7 | Confirm Milestone M2 (main flow functionally complete) | External (manual) | core features 1-4 working | **Milestone M2 confirmed** | start D8 |
| D8 | Implement core feature 5 | Internal Claude | feature code | feature 5 working | `/code-review` |
| D8 | `/code-review` | Skill | feature 5 diff | findings | fix, commit |
| D9 | Implement core feature 6 | Internal Claude | feature code | feature 6 working | `/code-review` |
| D9 | `/code-review` | Skill | feature 6 diff | findings | fix, commit |
| D4-D9 | `/auth-assessment` (when implementing/changing auth) | Skill (marketplace) | auth flow | gaps report | fix findings |
| D4-D9 | `/secure-storage-audit` (when storing sensitive data) | Skill (marketplace) | storage code | compliance report | migrate to SecureStore if needed |
| D4-D9 | `supabase-migrator` (new migration) | Skill (subagent) | SQL migration file | reviewed migration | apply on Supabase |
| D4-D9 | `expo-debugger` (EAS build/Metro stuck) | Skill (subagent) | build/Metro logs | root cause + suggested fix | apply fix, re-run |
| D10 | Buffer/catchup on delayed features | Internal Claude / Manual Edit | pending code | features complete | test e2e flow |
| D10 | Test main flow end-to-end (physical Android) | External (manual) | dev build | **DoD D10 / Milestone M3 confirmed:** user completes the main flow start-to-finish with no crash | start D11 |
| D11 | Complete i18n (PT-BR + extra languages) | Internal Claude | strings/screens | text using `t()` | `i18n-validator` |
| D11 | `i18n-validator` (UI text w/o `t()`) | Skill (subagent) | screen files | hardcoded-strings report | fix remaining strings |
| D12 | Add `accessibilityLabel` to interactive elements | Internal Claude | UI components | a11y labels present | loading/error states |
| D12 | Implement loading + error states on all screens | Internal Claude | screens | loading/error UX | haptic feedback |
| D13 | Haptic feedback on main interactions | Internal Claude | interactive components | haptics applied | tune performance |
| D13 | Tune performance (bundle <3MB, TTI <2s) + splash/icon | Internal Claude / Manual Edit (assets) | bundle config, assets/icon.png | optimized app + icon/splash ready | run quality gates |
| D13 | `pnpm quality:full` | External | project code | zero-error report (or failures) | fix failures, preflight |
| D13 | `pnpm preflight` | External | local production build | preflight OK | validate Golden Paths |
| D13 | Validate Golden Paths GP-1..GP-5 (physical Android) | External (manual) | app on device | **DoD D13 confirmed:** `quality:full` zero errors, `preflight` passes, Golden Paths GP-1..GP-5 validated on physical Android | start D14 |
| D14 | `eas build --profile production` (Android + iOS) | External | eas.json / code | production AAB/IPA | test Golden Paths on prod build |
| D14 | Test Golden Paths on production build | External (manual) | installed AAB/IPA | crash-free validation | capture screenshots |
| D14 | Capture store screenshots | External (manual) | running app | images for `05-store-launch.md` | fill metadata |
| D15 | Fill store metadata | Manual Edit | `docs/05-store-launch.md` | complete metadata | publish privacy policy |
| D15 | Publish Privacy Policy (URL) | External | privacy policy page | public URL | run store-metadata-reviewer |
| D15 | `store-metadata-reviewer` | Skill (subagent) | metadata + screenshots | compliance report | fix findings |
| D15 | `/rn-harness:rn-doctor` (before final build) | Skill | project (24 checks) | report with no FAILs | validate DoD D15 |
| D15 | Confirm DoD D15 / Milestone M4 | External (manual) | production build installed | **DoD D15 / Milestone M4 confirmed:** production build installed on physical Android, no crash on Golden Paths | start D16 |
| D16 | Upload AAB → internal track (Google Play Console) | External (irreversible) | production AAB | release on internal track | promote to production |
| D16 | Promote release to production (Google Play) | External (irreversible) | internal track release | app in review on Play Store | answer compliance |
| D17 | Xcode Archive → upload to TestFlight | External (irreversible) | iOS build | build on TestFlight | submit for review |
| D17 | App Store submission (App Store Connect) | External (irreversible) | TestFlight build | app in review on App Store | answer compliance |
| D17 | Answer compliance questions (both stores) | Manual Edit/External | store forms | compliance answered | log build number |
| D17 | Log build number/status in DECISIONS.md | Manual Edit | `DECISIONS.md` | record saved — **DoD D17 / Milestone M5 confirmed:** both submissions confirmed, build number logged | start D18 |
| D18 | Publish landing page (GitHub Pages/Vercel) | External | 1 static page | landing page live | prepare posts |
| D18 | `marketing-copywriter` | Skill (subagent) | app briefing | per-platform copy | review/schedule posts |
| D18 | `viral-content-strategist` | Skill (subagent) | app/audience context | viral content concept | create D-1/D0 posts |
| D19 | Publish D-1/D0 posts (Reddit, social) | External (manual) | ready copy | posts published | monitor reaction |
| D20 | Create Product Hunt listing | External (manual) | assets + copy | listing published | track metrics |
| D20 | Publish D+3/D+7 posts (scheduled) | External (manual) | ready copy | posts published | log metrics |
| D20 | Log D+7 metrics in DECISIONS.md | Manual Edit | `DECISIONS.md` | metrics logged — **DoD D20 confirmed:** app approved on both stores, landing page live, ≥1 marketing channel active | close milestone / v1.1 |

---

## Skills — When to use which

| Phase | Trigger | Skill | How to invoke |
|-------|---------|-------|---------------|
| D1 | After `/rn-harness:new-rn-project` or clone on new machine | `rn-doctor` | `/rn-harness:rn-doctor` |
| D1-D2 | Competitor research | `firecrawl-search` | `/firecrawl-search` |
| D1-D2 | Scrape competitor page | `firecrawl-scrape` | `/firecrawl-scrape` |
| D3+ | New screen with hardcoded colors | `design-token-guardian` | subagent |
| D3+ | UI text without `t()` | `i18n-validator` | subagent |
| D4+ | EAS build / Metro stuck | `expo-debugger` | subagent |
| D4+ | Auth flow | `auth-assessment` | `/auth-assessment` |
| D4+ | Sensitive data in storage | `secure-storage-audit` | `/secure-storage-audit` |
| D4+ | New Supabase migration | `supabase-migrator` | subagent |
| Pre-commit | Any diff | `code-review` | `/code-review` |
| D13-D15 | Complete feature for QA | `qa-tester` | subagent |
| D15 | App Store/Play metadata | `store-metadata-reviewer` | subagent |
| D15 | Before production build | `rn-doctor` | `/rn-harness:rn-doctor` |
| D17 | Post copy per platform | `marketing-copywriter` | subagent |
| D18 | Viral concept | `viral-content-strategist` | subagent |
| Post-D20 | Privacy audit | `privacy-audit` | `/privacy-audit` |

### Bundled skills (installed by rn-harness)

| Skill | What it does |
|-------|-------------|
| `new-rn-project` | Init wizard: detects stack, creates structure, configures hooks and rules |
| `rn-doctor` | 24 health checks + explains FAILs + runs fixes |

### Marketplace skills (install separately)

| Skill | Provider | When |
|-------|----------|------|
| `firecrawl-search` / `firecrawl-scrape` | firecrawl MCP | D1-D2 |
| `design-token-guardian` | plugin | D3+ |
| `i18n-validator` | plugin | D3+ |
| `expo-debugger` | callstack | D4+ |
| `auth-assessment` | plugin | D4+ |
| `secure-storage-audit` | plugin | D4+ |
| `supabase-migrator` | plugin | D4+ |
| `code-review` | plugin | pre-commit |
| `qa-tester` | plugin | D13-D15 |
| `store-metadata-reviewer` | plugin | D15 |
| `marketing-copywriter` | plugin | D17 |
| `viral-content-strategist` | plugin | D18 |
| `privacy-audit` | plugin | post-D20 |

---

## Quality Gates

Pre-commit blocks based on the **active profile** (see Hook Profiles):

| Profile | Blocks if failing |
|---------|------------------|
| `minimal` | tsc --noEmit |
| `standard` | tsc + eslint + prettier |
| `strict` *(default)* | tsc + eslint + prettier + fta score ≥ 60 |

Before push (all profiles): `pnpm quality:full` (typecheck + lint + format + fta + tests).

Before production build: `pnpm preflight` + manual Golden Paths (5 critical flows, defined in `docs/03-quality-gates.md`) + `/rn-harness:rn-doctor` with no FAILs.

**FTA ≥ 60?** Refactor: extract sub-components, custom hooks, lookup tables. **Never** raise the score_cap.

---

## Device Matrix

| Device | Platform | Use |
|--------|----------|-----|
| Own physical Android | Android | Main iteration (real haptic, share, deeplink) |
| Android Studio AVD | Android | Quick visual + multi-user |
| Appetize.io (free 30min) | iOS | Weekly smoke (UI, navigation, i18n) |
| Borrowed iPhone | iOS | TestFlight D17+ (1-2h) |

**iOS Plan B:** BrowserStack App Live (30 min free) or MacInCloud (~$1/h).

> **D1 Action:** Schedule iPhone borrow for D17-D18. Log in TODO.md.

---

## FAQ

**How to start a project without overwriting existing files?**
`/rn-harness:new-rn-project` checks each file before creating. Existing ones are skipped with a warning.

**How to force overwrite a file?**
Delete it manually and run `/rn-harness:new-rn-project` again, or edit directly.

**Are all knowledge rules always copied?**
No — they're selective. The wizard copies only those relevant to the detected stack. A project without Supabase won't get `supabase.md`, without expo-video won't get `expo-video.md`. To get all 15: run `/rn-harness:new-rn-project` in a project without `package.json`.

**How to change the hook profile after installing?**
Re-run `/rn-harness:new-rn-project` in the project and pick a different profile when asked — it updates `.githooks/` and remembers the choice for next time.

**Can I use this without Supabase?**
Yes — during stack detection the wizard won't copy `supabase.md` or suggest `@supabase/supabase-js`. Just confirm backend as "(none)" or Firebase.

**I don't have a Mac for iOS.**
Flow documented in `04-testing.md`: Appetize.io for smoke + borrowed iPhone for TestFlight. The wizard includes this instruction in TODO.md.

**How to update the harness without breaking existing projects?**
`/plugin update rn-harness` only touches the plugin's own installed files. Existing generated projects are not affected — templates and rules only apply to projects created *after* the update.

**Does `/rn-harness:rn-doctor` modify files?**
No — it only reads and reports. Fixes are suggested and executed only when invoked via `/rn-harness:rn-doctor` in Claude Code, with user confirmation.

**What is the D1→D20 Step-by-Step table?**
It's the operational reference in the [D1→D20 Step-by-Step](#d1d20-step-by-step) section: one row per command/step across the full 20-day flow, tagged with day, classification (Internal Claude / External / Skill / Manual Edit), input/output artifacts, and next step.

**How does the PR workflow work (branch before main)?**
Create a feature branch (`git checkout -b <name>`), commit there, push, and open a PR (`gh pr create`) for review before merging into `main`. Don't commit directly to `main`.

**Is `/rn-harness:rn-doctor --json` reliable for CI?**
Not yet — `tests/test.sh` currently has a known failing check ("doctor.sh --json nao produz JSON valido"). Treat `--json` output as unverified until that test passes; use the human-readable output for now.

---

## Contributing

Private repo. For improvements:
1. Clone the repo and edit files locally
2. Run test suite: `bash tests/test.sh` (must finish with 0 failures)
3. Test skills against your local clone: `/plugin marketplace add /path/to/local/rn-harness` then `/plugin install rn-harness@rn-harness`, or `claude plugin validate .` to check the manifests without installing
4. Test skill manually: `/rn-harness:new-rn-project` or `/rn-harness:rn-doctor` in a test project
5. Commit and push

Template and rule changes take effect in **future** created projects. Existing projects are not affected.

---

## Uninstall

```
/plugin uninstall rn-harness
```

Removes the plugin (skills, templates, scripts, git hook profiles). Existing generated projects are not affected.

# Technology Stack

**Analysis Date:** 2026-08-11

## Overview

rn-harness is a CLI tooling framework (not a React Native app itself) that scaffolds, validates, and standardizes React Native projects. It provides installation scripts, git hooks, skills for Claude Code, and configuration templates.

## Languages

**Primary:**
- **Shell (Bash/PowerShell)** — Install scripts (`install.sh`, `install.ps1`), health check scripts (`doctor.sh`, `doctor.ps1`), git hooks (`pre-commit.sh`, `pre-push.sh` in multiple profiles)
- **Markdown** — Skills documentation (SKILL.md), templates (CLAUDE.md.tmpl, docs/*.md), knowledge rules (rules/*.md)

**Secondary:**
- **JSON** — Configuration (`settings.json`, app.json manifests)
- **TypeScript** — Generated types for Supabase projects (template-only)

## Runtime

**Environment:**
- Node.js >= 20 LTS (required by scaffolded projects)
- pnpm (required package manager for scaffolded projects)

**Platform Support:**
- macOS / Linux (Bash scripts primary)
- Windows (PowerShell equivalents for all scripts)

## Build & Installation Tools

**Execution Engines:**
- **Bash** — Primary shell scripts for Unix-like systems
- **PowerShell** — Windows equivalents (version 5.1+)
- **Git** — Version control and hook installation via `git config core.hooksPath`

**Package Manager:**
- **pnpm** — Enforced for all scaffolded projects (faster, smaller disk footprint)
- Lockfile: Not applicable to rn-harness itself; projects use `pnpm-lock.yaml`

## Key Frameworks & Tools for Scaffolded Projects

**Core Mobile Stack (templates target):**
- React Native (0.76.x recommended)
- Expo SDK 56 (core framework)
- Expo Router (file-based routing, default)
- TypeScript (strict mode enforced)

**State Management (auto-detected and configured):**
- Zustand (default)
- Redux Toolkit (alternative)
- Jotai (alternative)

**Styling (auto-detected):**
- StyleSheet.create (default)
- NativeWind (CSS-based alternative)
- Tamagui (component library alternative)
- Gluestack UI (alternative)

**Animation & Gestures:**
- react-native-reanimated v3 (enforced when present)
- react-native-gesture-handler v2

**Internationalization (i18n):**
- i18next + react-i18next
- expo-localization (device locale detection)

**Backend Integration (auto-detected):**
- Supabase (PostgreSQL, auth, Edge Functions, RLS)
- Firebase (alternative)
- Convex (alternative)

**Storage & Security:**
- expo-secure-store (enforced for auth tokens)
- AsyncStorage (detected, triggers WARN if used for sensitive data)

**Development & Testing:**
- TypeScript Compiler (typecheck)
- ESLint (linting)
- Prettier (formatting)
- FTA (Function complexity analyzer, score cap 60)
- Testing Library for React Native (optional)
- Detox (optional E2E testing)

## Quality Gates & Validation

**Pre-commit Hook (configurable by profile):**
- **minimal:** `pnpm typecheck` only
- **standard:** typecheck + lint + format:check + quality:full check
- **strict** (default): typecheck + lint + format:check + fta (score cap 60)

**Pre-push Hook:**
- Android build confirmation prompt
- quality:full check + fta

**Health Check Script (`doctor.sh / doctor.ps1`):**
- 24 automated checks across environment, SDK versions, security, git config, forbidden patterns

## Configuration

**Environment:**
- Environment variables via `.env` and `.env.local` (not committed)
- EAS Secrets for production builds (via EAS CLI)
- `.env.example` as template (committed)

**Project Configuration Files (templates provide):**
- `CLAUDE.md` — Project context, stack details, conventions, quality gates
- `app.json` / `app.config.ts` — Expo configuration
- `eas.json` — EAS build profiles for iOS/Android
- `.env` — Local secrets (git-ignored)
- `tsconfig.json` — TypeScript configuration (strict: true enforced)
- `babel.config.js` — Babel plugins (reanimated plugin required if using it)
- `.eslintrc.json` — ESLint rules (includes react-native/no-color-literals)
- `.prettierrc` — Code formatting
- `jest.config.js` / `vitest.config.ts` — Test configuration (optional)

**Claude Code Configuration:**
- `.claude/settings.json` — Permission denylist/allowlist (destructive operations blocked)
- `.claude/hooks/pre-tool-use.sh` — Runtime command validation hook (SQL, force-push, etc. blocked)
- `.claude/rules/` — Markdown-based knowledge rules (selective, stack-aware)

## Platform Requirements

**Development:**
- Node.js 20+ LTS (enforced by doctor check)
- pnpm (enforced by doctor check)
- Git (enforced by doctor check)
- EAS CLI optional (for production builds)
- Text editor with TypeScript support

**Production:**
- iOS 13+ (Expo target)
- Android 6.0+ (API level 21+)
- App Store + Google Play Store distribution

## External Tools & Services

**Build & Distribution:**
- **Expo Application Services (EAS)** — Building, signing, submitting to stores
  - EAS Build (compile and sign)
  - EAS Submit (submit to App Store/Play Store)
  - EAS Update (OTA updates)
  - EAS Secrets (environment variables in production)

**Cloud Backend (via templates & rules):**
- **Supabase PostgreSQL** — Primary database target
- **Supabase Auth** — Authentication provider
- **Supabase Edge Functions** — Backend logic (AI prompts, etc.)
- **Supabase Realtime** — Live subscriptions

## Dependencies Checked by Doctor Script

**Required:**
- node >= 20.x
- pnpm (any version)
- git (any version)
- Expo SDK = ^56 (in package.json)
- TypeScript with strict: true

**Recommended:**
- eas-cli (for production builds)
- react-native-reanimated = ^3.x (if animation is used)
- expo-secure-store (for auth token storage)
- babel.config.js with reanimated plugin (if animation is used)

**Deprecated/Blocked:**
- expo-av (replaced by expo-video + expo-audio)
- AsyncStorage (for tokens; use expo-secure-store)
- Color literals in StyleSheet (use design tokens)

## Marketplace Skills Recommended

**Data & Research:**
- firecrawl-search, firecrawl-scrape (MCP — web scraping)

**Design & Localization:**
- design-token-guardian
- i18n-validator

**Expo & Backend:**
- expo-debugger
- auth-assessment
- secure-storage-audit
- supabase-migrator

**Quality:**
- code-review (pre-commit integration)

**Testing:**
- qa-tester
- store-metadata-reviewer

**Marketing:**
- marketing-copywriter
- viral-content-strategist

**Security:**
- privacy-audit (post-launch)

---

*Stack analysis: 2026-08-11*

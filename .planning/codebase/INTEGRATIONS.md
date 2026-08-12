# External Integrations

**Analysis Date:** 2026-08-11

## APIs & External Services

**Backend Platforms (auto-detected via `new-rn-project`):**
- **Supabase** — PostgreSQL database, authentication, Edge Functions, Realtime subscriptions, RLS security
  - SDK: `@supabase/supabase-js`
  - Auth: `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_ANON_KEY` (in `.env`)
  - Template rule: `templates/rules/supabase.md`

- **Firebase** — Alternative backend (auto-detected; alternative to Supabase)
  - SDK: `firebase` or `@firebase/*`
  - Auth: `FIREBASE_CONFIG` environment variables
  - Alternative to Supabase rule

- **Convex** — Alternative backend (serverless functions)
  - SDK: `convex`
  - Auth: `CONVEX_URL` environment variable
  - Alternative to Supabase/Firebase

**Web Scraping & Search (Marketplace):**
- **Firecrawl MCP** — Web scraping and search API
  - Skills: `firecrawl-search`, `firecrawl-scrape`
  - Suggested for: D1-D2 research phases

**Monetization Platforms (auto-detected):**
- **RevenueCat** — In-app purchase management, subscription handling
  - SDK: `react-native-purchases`
  - Environment: RevenueCat API key in `.env`
  - Template rule: `templates/rules/revenue-cat.md`

- **react-native-iap** — Native IAP alternative (auto-detected)
  - SDK: `react-native-iap`
  - Alternative to RevenueCat

## Data Storage

**Databases:**
- **PostgreSQL (via Supabase)**
  - Connection: `EXPO_PUBLIC_SUPABASE_URL` + `EXPO_PUBLIC_SUPABASE_ANON_KEY`
  - Client: `@supabase/supabase-js`
  - Features: RLS (Row-Level Security), Realtime, Edge Functions
  - Rule file: `templates/rules/supabase.md`

- **Firestore/Firebase Realtime Database (alternative)**
  - Connection: Firebase config in environment
  - Client: `firebase` or `@firebase/database`

- **Convex Database (alternative)**
  - Connection: `CONVEX_URL`
  - Client: `convex/react`

**File Storage:**
- **Supabase Storage** (if using Supabase)
  - Accessible via `@supabase/supabase-js` client
  - Bucket access via RLS policies
  - Not explicitly configured in default templates

- **Firebase Cloud Storage (if using Firebase)**
  - Alternative storage option

**Local Storage:**
- **expo-secure-store** — Encrypted local storage for sensitive data (auth tokens)
  - SDK: `expo-secure-store`
  - Used by: `templates/rules/supabase.md` (mandatory for tokens)
  - **Enforced:** doctor check #17 ensures tokens are NOT in AsyncStorage

- **AsyncStorage** — Plain key-value storage (NOT for sensitive data)
  - SDK: `@react-native-async-storage/async-storage`
  - Status: Detected with warning if used for tokens
  - Doctor check #17 warns if AsyncStorage is sole storage option

**Caching:**
- Not configured in templates
- Supabase Realtime provides live subscriptions
- Client-side caching via Zustand/Redux state management

## Authentication & Identity

**Auth Provider:**
- **Supabase Auth** (default, auto-detected)
  - Implementation: OAuth2, magic link, password auth via Supabase
  - Token storage: `expo-secure-store` (enforced)
  - Hook pattern: `templates/rules/supabase.md` provides `useAuth()` hook example
  - Session persistence: auto-refresh via `autoRefreshToken: true`

- **Firebase Auth (alternative)**
  - Auto-detected if Firebase SDK present
  - Marketplace skill: `auth-assessment`

**Multi-factor Authentication (optional):**
- Supabase MFA support
- Marketplace skill: `auth-assessment` (audits auth setup)

**Secure Storage:**
- **expo-secure-store** — Mandatory for auth tokens
  - Replaces AsyncStorage for sensitive data
  - Marketplace skill: `secure-storage-audit` (validates implementation)

## Monitoring & Observability

**Error Tracking:**
- Not detected or configured in default templates
- Recommendation: Add Sentry, LogRocket, or similar

**Logs:**
- Console logging (development)
- No centralized logging configured by default
- Supabase Edge Function logs available in Supabase dashboard

**Performance:**
- FTA (Function complexity analyzer) enforced in pre-commit hooks (score cap 60)
- ESLint rules checked for performance anti-patterns
- Marketplace skill: `claude-debug-optimize-lcp` (available via chrome-devtools MCP)

## CI/CD & Deployment

**Hosting Platform:**
- **Expo Application Services (EAS)**
  - EAS Build: Compile and sign binaries
  - EAS Submit: Submit to App Store / Play Store
  - EAS Update: Over-the-air updates
  - EAS Secrets: Environment variables for production builds

**CI Pipeline:**
- No CI/CD automation configured by rn-harness itself
- Doctor script supports `--json` output for CI integration (`templates/rules/security.md` mentions manual quality gates)
- Suggested: GitHub Actions, GitLab CI, or Expo CI integration

**Pre-deployment Checks:**
- `pnpm typecheck` — TypeScript validation
- `pnpm lint` — ESLint rules
- `pnpm format:check` — Prettier formatting
- `pnpm fta` — Function complexity (score cap 60)
- `pnpm quality:full` — Full quality suite
- Doctor script: 24 health checks (includes SDK version, dependency security, git config)

**Store Configuration:**
- **app.json / app.config.ts** — Expo config
  - Required: `bundleIdentifier` (iOS), `packageName` (Android)
  - Doctor check #21 verifies presence

- **eas.json** — EAS build profiles
  - Profiles: `development`, `preview`, `production`
  - Secrets: Stored in EAS Secrets (not in repo)
  - Doctor check #22 verifies presence

## Environment Configuration

**Required Environment Variables:**
- `EXPO_PUBLIC_SUPABASE_URL` — Supabase instance URL
- `EXPO_PUBLIC_SUPABASE_ANON_KEY` — Supabase anonymous key (public)
- `EXPO_PUBLIC_*` — Any public-facing config (Expo bundles these into the app)

**Development Variables:**
- `.env` and `.env.local` (git-ignored)
- `.env.example` (committed as template)

**Production Variables:**
- Stored in EAS Secrets (via `eas secret:create`)
- Never committed to git
- Referenced in `eas.json` via `"extra"` section

**Secrets Location:**
- **Local development:** `.env` file (git-ignored, created from `.env.example`)
- **Production:** EAS Secrets (via `eas secret:create` command)
- **Safe storage:** `expo-secure-store` for runtime auth tokens (mandatory per doctor check #17)
- **Dangerous:** AsyncStorage (triggers warning), hardcoded keys (triggers FAIL in doctor check #18)

## Webhooks & Callbacks

**Incoming:**
- None detected or configured by default
- Supabase Edge Functions can receive webhooks
- Marketplace skill: `supabase-migrator` (handles database migration patterns)

**Outgoing:**
- Supabase Realtime subscriptions (push updates to client)
- EAS Update notifications (OTA update status)
- Marketplace skill: `code-review` integrates with git workflow (pre-commit hook)

## API Security

**Permission Model (Claude Code):**
Declared in `.claude/settings.json`, created by `/new-rn-project`:

```json
{
  "permissions": {
    "deny": [
      "Bash(eas submit*)",        // Prevent accidental store submission
      "Bash(supabase db reset*)", // Prevent data loss
      "Bash(git push --force*)",  // Prevent rewriting history
      "Bash(git commit *--no-verify*)", // Enforce hooks
      "Bash(rm -rf /*)"           // Prevent filesystem damage
    ]
  }
}
```

**Runtime Blocking Hook (`.claude/hooks/pre-tool-use.sh`):**
Additional patterns blocked before execution:
- `eas submit`, `supabase db reset` — Destructive operations
- `git push --force`, `git reset --hard` — Rewriting history
- `DROP TABLE`, `truncate cascade` — SQL data loss
- `npx expo publish` — Deprecated publish command
- Requires manual execution if developer confirms need

## Database Migrations

**Supabase Migrations:**
- Location: `supabase/migrations/` (version-controlled)
- Tool: Supabase CLI for local development
- RLS Policies: Defined per table (mandatory per `CLAUDE.md` template)
- Marketplace skill: `supabase-migrator` (assists with migration planning)

## Integrations by Development Phase

| Phase | Integration Focus | Marketplace Skills |
|-------|-------------------|-------------------|
| D1-D2 | Research, data collection | firecrawl-search, firecrawl-scrape |
| D3+ | Design tokens, localization | design-token-guardian, i18n-validator |
| D4+ | Backend, auth, storage | expo-debugger, auth-assessment, secure-storage-audit, supabase-migrator |
| Pre-commit | Code quality | code-review |
| D13-D15 | Testing, store metadata | qa-tester, store-metadata-reviewer |
| D17-D18 | Marketing copy | marketing-copywriter, viral-content-strategist |
| Post-D20 | Privacy/compliance | privacy-audit |

---

*Integration audit: 2026-08-11*

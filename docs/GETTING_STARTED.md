# Getting Started (personal notes)

Empty folder → shipped app, new-repo path only. Written to kill two specific confusions: "what do I even fill in for app requirements" and "what do I actually *do* on day 5".

Full reference stays in [README.md](../README.md) — this is the condensed walk order.

---

## 0. Prereqs (once per machine)

```bash
nvm install 20              # Node 20 LTS
npm i -g pnpm
npm i -g @anthropic-ai/claude-code
```

```
/plugin marketplace add Jujubalandia/rn-harness
/plugin install rn-harness@rn-harness
```

Everything (templates, skills, doctor scripts, git hook profiles) ships inside the plugin — nothing to place manually. Your hook profile choice, once picked in the wizard, is remembered across projects (defaults to `strict` if you skip choosing one).

---

## 1. Prep checklist — fill this BEFORE running the wizard

This is answer-first prep. It maps 1:1 to `docs/01-spec.md`, which the wizard doesn't fill for you — you fill it D1-D2. Answering these now means D1-D2 is copy-paste, not a blank page.

- [ ] **Problem** — one paragraph: who suffers, from what
- [ ] **Target audience** — primary profile, rough size, location, main pain
- [ ] **Top 3 competitors** — downloads, strengths, weaknesses, what you'll do differently
- [ ] **Unique differentiator** — one sentence: "Unlike [competitor], our app [does X] for [who]"
- [ ] **MVP features — cut/keep** — rule: if it's not required for the first user's main flow, cut it
- [ ] **Monetization** — model, activation date, rough revenue estimate
- [ ] **Viral loop** — how it spreads organically (can be "none yet")
- [ ] **Top 3 risks** — probability + mitigation each

Don't overthink these — they're drafts. `01-spec.md`'s own DoD (D1-D2) is just: problem statement + 3 competitors + cut/keep approved + 1-sentence diff + viral loop. Good enough beats perfect here.

---

## 2. Run the wizard

```bash
mkdir ~/projects/my-app && cd ~/projects/my-app
claude
```

Inside Claude Code:

```
/rn-harness:new-rn-project
```

What it does, in order:

1. **Detects stack** from `package.json` (if one exists) across 13 dims — state mgmt, nav, styling, backend, i18n, animation, gesture, storage, image-gen, testing, video, monetization, notifications. Shows a table, asks you to confirm.
   - No tie-breaker documented if two conflicting libs are both present (e.g. Zustand + Redux both installed) — if that happens, just tell it which one is real.
2. **Asks what it couldn't detect**: `APP_NAME`, description, languages, monetization model, hook profile (`strict` / `quality:full` / lighter — pick `strict` if unsure).
3. **Creates**: filled `CLAUDE.md` (no `{{PLACEHOLDER}}` tokens left — if you see any, it's a bug, fill manually), `DECISIONS.md`, `TODO.md`, `docs/01-spec.md` … `docs/06-marketing.md` (empty templates, you fill these later — this is where your prep checklist answers go), `.githooks/`, `.claude/rules/` (selective, based on detected stack), `.claude/settings.json`, `.claude/hooks/pre-tool-use.sh`.
4. **Prints a next-steps checklist** in the chat output (not a file) — usually: install missing deps, run `npx expo install --fix`.

Then:

```
/rn-harness:rn-doctor
```

24 checks, must exit clean (no FAILs) before moving on. Storage check (#17) is 3-tier: secure-store only = OK, secure-store + AsyncStorage both present = WARN, AsyncStorage alone (no secure-store) = FAIL.

---

## 3. The D1→D20 map

The literal day-by-day already lives in **`docs/02-dev-plan.md`** (created by the wizard, in your project) — don't duplicate it here, open it. It's a real checklist with milestones and DoD gates: **you don't advance past a milestone until its DoD passes.**

Phase shape, so you know where you are:

| Days | Phase | File to edit | Gate |
|------|-------|---------------|------|
| D1–D3 | Spec + UX + Setup | `01-spec.md` | app running, auth, nav working |
| D4–D10 | Core features | `02-dev-plan.md` | ~1 feature/day; stuck >4h → log blocker, move on, don't spiral |
| D11–D13 | Polish, i18n, a11y | — | PT-BR required, a11y labels, perf targets |
| D14–D15 | QA + store prep | `04-testing.md` | production build, Golden Paths pass |
| D16–D17 | Store submission | `05-store-launch.md` | irreversible — AAB/IPA upload, double check before submit |
| D18–D20 | Marketing launch | `06-marketing.md` | landing page, launch posts |

Marketplace skills are NOT bundled by the rn-harness plugin — install separately when a phase needs one (`firecrawl-search` D1-2, `design-token-guardian`/`i18n-validator` D3+, `auth-assessment`/`secure-storage-audit`/`supabase-migrator` D4+, `qa-tester` D13-15, `store-metadata-reviewer` D15, `marketing-copywriter`/`viral-content-strategist` D17-18, `privacy-audit` post-D20). If a slash command 404s, this is why — go install it first.

---

## 4. Known sharp edges (don't re-debug these)

- **"FTA ≥ 60"** (quality gate, D11-13) — FTA = code complexity score from the `fta` tool; the rule is "never raise the ceiling to make a failing check pass, fix the code instead."
- **`/rn-harness:new-rn-project` has no `--force` flag** — to re-run the wizard on a dir it already touched: delete `CLAUDE.md` manually first, per README FAQ.
- **Destructive-op blocking** (`.claude/settings.json` + `.claude/hooks/pre-tool-use.sh`) — to allow a currently-blocked pattern (e.g. a specific `git push --force`), edit `.claude/hooks/pre-tool-use.sh` directly in your project, not the plugin's copy.
- **Windows** — hooks are `.sh`, run via Git Bash. If you're on WSL instead, no documented fallback yet — test before relying on hooks.

---

*Source: grilled 2026-08-11, cross-checked against `README.md`, `.planning/codebase/{STRUCTURE,ARCHITECTURE}.md`, `templates/docs/{01-spec,02-dev-plan}.md`.*

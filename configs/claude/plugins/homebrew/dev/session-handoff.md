# Session Handoff: Homebrew Plugin

> **Created:** 2026-02-02
> **Purpose:** Context for continuing homebrew plugin development

## Current State

**Phase Status:**
- [x] Phase 1: Foundation (research, architecture)
- [x] Phase 2: Scripts (download-checksum.sh, test-cask.sh - both tested)
- [x] Phase 3: Agents (all 5 created)
- [~] Phase 4: Integration (orchestrating skill written, NOT tested)
- [ ] Phase 5: Polish

**Files Created:**
```
homebrew/
├── agents/
│   ├── pre-flight-checker.md   (sonnet)
│   ├── app-inspector.md        (sonnet)
│   ├── livecheck-advisor.md    (sonnet)
│   ├── cask-writer.md          (sonnet)
│   └── pr-submitter.md         (haiku)
├── scripts/
│   ├── download-checksum.sh    ✓ tested
│   └── test-cask.sh            ✓ tested
├── skills/
│   └── new-cask/SKILL.md       (orchestrator, NOT tested)
└── references/
    ├── design.md
    ├── tool-permissions-research.md
    └── session-handoff.md      (this file)
```

## Test Case

**Codex App** (OpenAI's GUI desktop app):
- URL: `https://persistent.oaistatic.com/codex-app-prod/Codex.dmg`
- Token collision: `codex` CLI exists → would be `codex-app`
- Unversioned URL → `sha256 :no_check`
- Downloaded SHA256: `665656a6da3d2c537a42d2c75413e899772bba76ada5628f8d427e96f7a9b7b8`

---

## Atomic Testing Plan

Test each agent in isolation before running end-to-end. After each test, note what works and what needs adjustment.

### 1. Test pre-flight-checker

```
Task tool with subagent_type: homebrew:pre-flight-checker

Prompt: Check if "Codex App" at https://persistent.oaistatic.com/codex-app-prod/Codex.dmg
is suitable for homebrew-cask submission.
Homepage: https://openai.com/codex/
```

**Expected output:**
- Should detect token collision with `codex` CLI
- Should recommend `codex-app` as token
- Should return PROCEED (app is notable, not rejected)

**Verify it checks:**
- [ ] `brew search codex`
- [ ] `brew info --cask codex` (sees it's the CLI)
- [ ] `gh pr list` for open PRs
- [ ] `gh issue list` for rejection history
- [ ] Website for maintenance status

### 2. Test app-inspector

First, ensure the DMG is downloaded:
```bash
~/.config/nix-config/configs/claude/plugins/homebrew/scripts/download-checksum.sh \
  "https://persistent.oaistatic.com/codex-app-prod/Codex.dmg" "Codex.dmg"
```

Then test the agent:
```
Task tool with subagent_type: homebrew:app-inspector

Prompt: Inspect the app at /tmp/Codex.dmg
Homepage: https://openai.com/codex/
Extract: version, bundle ID, app name, min macOS, auto-updates, Sparkle URL, architecture.
```

**Expected output:**
- Version extracted from Info.plist
- Bundle ID for `uninstall quit:`
- Sparkle framework presence and SUFeedURL if exists
- Architecture (arm64/intel/universal)
- Min macOS if set

**Verify it:**
- [ ] Mounts the DMG correctly
- [ ] Finds the .app bundle
- [ ] Reads Info.plist with `defaults read`
- [ ] Checks for Sparkle framework
- [ ] Unmounts when done

### 3. Test livecheck-advisor

```
Task tool with subagent_type: homebrew:livecheck-advisor

Prompt: Recommend a livecheck strategy for Codex App.
Download URL: https://persistent.oaistatic.com/codex-app-prod/Codex.dmg
Homepage: https://openai.com/codex/
Sparkle URL: <from app-inspector, or "not found">
Current version: <from app-inspector>
```

**Expected output:**
- Strategy recommendation with reasoning
- Ruby livecheck block
- Validation notes

**Things to verify:**
- [ ] If Sparkle URL found, recommends `:sparkle`
- [ ] Tests URL with curl to verify it works
- [ ] Uses `brew livecheck --debug` for validation
- [ ] Notes if URL is unversioned

### 4. Test cask-writer

```
Task tool with subagent_type: homebrew:cask-writer

Prompt: Write a cask for Codex App with this metadata:
Token: codex-app
Version: <from inspector>
SHA256: :no_check (unversioned URL)
URL: https://persistent.oaistatic.com/codex-app-prod/Codex.dmg
Name: Codex
Description: AI coding assistant from OpenAI
Homepage: https://openai.com/codex/
Bundle ID: <from inspector>
App bundle: Codex.app
Min macOS: <from inspector or none>
Auto-updates: <from inspector>
Livecheck: <from livecheck-advisor>
Zap paths: (to be discovered later)
```

**Expected output:**
- Cask file at correct location
- Proper stanza order
- URL verification if needed

### 5. Test test-cask.sh

After cask is written:
```bash
~/.config/nix-config/configs/claude/plugins/homebrew/scripts/test-cask.sh codex-app
```

### 6. Test pr-submitter

Only after all tests pass and user has done manual testing.

---

## Design Pattern: Reference Docs for Ambiguity

All agents now include guidance to consult official Homebrew docs for ambiguous cases rather than having overly prescriptive rules baked in. This keeps agents current as Homebrew policies evolve.

Key doc locations:
- `/opt/homebrew/docs/Acceptable-Casks.md` - Acceptance criteria
- `/opt/homebrew/docs/Cask-Cookbook.md` - Stanzas, token naming
- `/opt/homebrew/docs/Brew-Livecheck.md` - Livecheck strategies
- `/opt/homebrew/docs/Adding-Software-to-Homebrew.md` - Contribution process

---

## Wisdom from v1 to Verify/Incorporate

Review these items during atomic testing and update agents as needed:

### In pre-flight-checker
- [ ] Handles various URL types (direct, product page, GitHub, none)
- [ ] Token collision guidance is complete

### In app-inspector
- [ ] Uses `brew find-appcast` command to find Sparkle URLs
- [ ] Checks architecture patterns in URLs (arm64, aarch64, x64, intel)
- [ ] Notes if SUFeedURL isn't in plist but Sparkle framework exists

### In livecheck-advisor
- [ ] Decision tree matches v1 (Sparkle → GitHub → header_match → json → page_match → extract_plist)
- [ ] Tries common appcast filenames (appcast.xml, updates.xml, sparkle.xml, feed.xml)
- [ ] Uses `brew livecheck --debug` for validation
- [ ] Handles architecture-specific livecheck URLs
- [ ] Documents `skip` option for impossible cases

### In cask-writer
- [ ] `uninstall quit:` stanza included by default
- [ ] Zap path uses glob `*` instead of specific versions
- [ ] Shared config directory check guidance
- [ ] URL `verified:` when domains differ

### In pr-submitter
- [x] ~~Correct branch is `master` not `main` for homebrew-cask~~ (verified: default branch is `main`)

### Reference material to migrate
- [x] Copy `livecheck-strategies.md` from v1 to v2 references
- [ ] **Review `livecheck-strategies.md`** - Copied from v1, ~365 lines of patterns. Needs review to ensure it's accurate and up-to-date with current Homebrew practices. Compare against `/opt/homebrew/docs/Brew-Livecheck.md` for any discrepancies.
- [ ] Add "Common Issues and Solutions" section somewhere

---

## Prompt for Next Session

```
I'm continuing work on the Homebrew plugin v2 for Claude Code.

**Start by reading:**
1. `configs/claude/plugins/homebrew/dev/session-handoff.md` - Full context
2. `configs/claude/plugins/homebrew/dev/design.md` - Architecture

**Where we left off:**
- All components built (scripts, agents, orchestrating skill)
- Need atomic testing of each agent before end-to-end
- Should verify v1 wisdom is incorporated

**Test case:** Codex App at https://persistent.oaistatic.com/codex-app-prod/Codex.dmg

**Next steps:**
1. Test pre-flight-checker agent in isolation
2. If issues found, fix before moving to next agent
3. Work through the atomic testing plan sequentially
4. Verify v1 wisdom items are working
5. End-to-end test when all agents validated
```

---

## Notes for Testing

- Plugin cache was cleared: `rm -rf ~/.claude/plugins/cache/malos-plugins/homebrew`
- Restart Claude Code to pick up plugin changes
- Agents are invoked as `homebrew:<agent-name>` via Task tool
- Scripts use `${CLAUDE_PLUGIN_ROOT}/scripts/` path

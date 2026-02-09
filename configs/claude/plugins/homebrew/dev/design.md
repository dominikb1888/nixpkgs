# Homebrew Plugin: Design Document

> **Status:** Phase 4 In Progress - Orchestrating Skill Written, Testing Next
> **Created:** 2026-02-02
> **Purpose:** Persistent design doc for the homebrew plugin rewrite, serving as shared context across sessions.

## Goals

1. **Modular architecture** - Break the monolithic skill into testable, composable components
2. **Minimal permission friction** - Design around the `allowed-tools` bug (#14956) using scripts and smart patterns
3. **Reusable by others** - No dependency on personal settings.json; self-contained plugin
4. **Incremental testability** - Each component works in isolation before integration

## Background

The v1 plugin (`homebrew-v1/`) had a comprehensive 430-line skill that covered the entire cask creation workflow. Problems:
- Permission prompts for every Bash command despite 54-line `allowed-tools` list
- Monolithic design with no ability to test individual phases
- If something failed partway, restart from scratch

See `tool-permissions-research.md` for detailed findings on the permission system bug.

---

## Research Findings (2026-02-02)

### Critical Constraint: Subagents Cannot Spawn Subagents

From the official docs:
> "Subagents cannot spawn other subagents. If your workflow requires nested delegation, use Skills or chain subagents from the main conversation."

**Implications:**
- A skill with `context: fork` runs in a subagent and CANNOT spawn further agents
- Orchestration must happen from the main conversation context
- The main skill must NOT use `context: fork` if it needs to delegate to agents

### Skills

Key capabilities:
- `context: fork` - Runs skill in isolated subagent context (inherits CLAUDE.md)
- `agent` field - Specifies which agent type: `Explore`, `Plan`, `general-purpose`, or custom
- `allowed-tools` - Grants tool access without per-use approval when skill is active (buggy for Bash)
- `disable-model-invocation: true` - Only user can invoke (prevents auto-triggering)
- `!`command`` syntax - Dynamic context injection (runs before Claude sees the prompt)
- `$ARGUMENTS` - User input passed to skill

**Skill invocation modes:**
| Frontmatter | User can invoke | Claude can invoke |
|-------------|-----------------|-------------------|
| (default) | Yes | Yes |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes |

### Subagents

Key capabilities:
- Built-in agents: `Explore` (read-only, Haiku), `Plan` (read-only), `general-purpose` (all tools)
- Custom agents in `.claude/agents/` or plugin `agents/` directory
- `tools` / `disallowedTools` - Control tool access
- `skills` field - Preloads skill content into agent's system prompt
- `permissionMode` - `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`
- `hooks` - Lifecycle hooks in frontmatter (PreToolUse, PostToolUse, Stop)
- `model` - Can specify `sonnet`, `opus`, `haiku`, or `inherit`

**Important:** Subagents do NOT inherit skills from parent conversation - must list explicitly in `skills` field.

### Hooks

- PreToolUse hooks can validate/block tool calls
- Exit code 0: approve/continue
- Exit code 2: block (returns stderr to Claude)
- Can be defined in settings.json, skill frontmatter, or agent frontmatter
- Hooks receive JSON input via stdin with tool details

### Permission Inheritance

When a skill is active:
- `allowed-tools` should grant access without prompts (but Bash is buggy)
- Subagents inherit permission context from parent but can override via `permissionMode`
- `context: fork` creates isolated context - doesn't share conversation history

### Permission Pattern Syntax (from IAM docs)

**Evaluation order:** deny → ask → allow. First matching rule wins.

**Bash patterns:**
- `Bash(brew audit *)` - space before `*` enforces word boundary (matches `brew audit foo`, not `brew auditor`)
- `Bash(brew*)` - no space means no word boundary (matches `brew`, `brewx`)
- Claude is aware of shell operators - `Bash(brew *)` won't match `brew foo && rm -rf /`
- Patterns are fragile for URLs - variables, extra spaces, redirects can bypass

**Read/Edit patterns (gitignore style):**
- `//path` - Absolute from filesystem root (double slash!)
- `~/path` - From home directory
- `/path` - Relative to settings file (NOT absolute)
- `path` - Relative to current directory
- `*` matches single dir, `**` matches recursively

**Examples:**
```
Bash(brew audit *)           # brew audit with any args
Bash(brew style *)           # brew style with any args
Read(//Volumes/**)           # Absolute path to mounted volumes
Read(/opt/homebrew/**)       # Relative to settings file
Edit(*/homebrew-cask/**)     # Any path containing homebrew-cask
```

---

## Architecture Decision

### Recommended Pattern: Orchestrating Skill + Chained Agents

Given the constraint that subagents cannot spawn subagents:

```
User invokes: /homebrew:new-cask <url>
        │
        ▼
┌─────────────────────────────────────────────┐
│  Orchestrating Skill (runs in MAIN context) │
│  - NOT context: fork                        │
│  - Uses Task tool to spawn agents           │
│  - Tracks progress via task list            │
│  - Chains agent calls sequentially          │
└─────────────────────────────────────────────┘
        │
        ├──► Agent: pre-flight-checker
        │         └──► Returns: duplicate check results, acceptability
        │
        ├──► Script: download-and-checksum.sh
        │         └──► Returns: checksum, downloaded file path
        │
        ├──► Agent: app-inspector
        │         └──► Returns: version, bundle-id, min-macos, auto-updates, sparkle URL
        │
        ├──► Agent: livecheck-advisor
        │         └──► Returns: recommended livecheck stanza
        │
        ├──► Agent: cask-writer
        │         └──► Returns: written cask file path
        │
        ├──► Script: test-cask.sh (with retry on failure)
        │         └──► Returns: pass/fail, error details
        │
        └──► Agent: pr-submitter
                  └──► Returns: PR URL
```

### Why This Pattern

1. **Main context orchestration** - Skill runs in user's conversation, can use Task tool to spawn agents
2. **Sequential chaining** - Each agent returns results, skill passes to next step
3. **Progress tracking** - Use task list to track which steps completed (resumable)
4. **Scripts for deterministic work** - Checksum, testing - predictable I/O, one permission each
5. **Agents for judgment work** - App inspection, livecheck selection - need exploration

### Component Decisions

| Component | Type | Rationale |
|-----------|------|-----------|
| **Pre-flight checker** | Agent | Needs judgment for edge cases (similar names, rejection reasons) |
| **Download & checksum** | Script | Deterministic: curl + shasum, single permission |
| **App inspector** | Agent | DMG structures vary, plist locations vary, needs exploration |
| **Livecheck advisor** | Agent | Must analyze app behavior, try multiple strategies |
| **Cask writer** | Agent | Needs to synthesize gathered info, handle edge cases |
| **Test runner** | Script | Deterministic: brew audit/style/livecheck, retry logic |
| **PR submitter** | Agent | Some judgment for commit messages, handling git state |

### Permission Strategy

**For scripts:** Bundle related commands, accept single permission prompt per script.

**For agents:** Accept prompts during exploratory work. Each agent will prompt for its tools, but:
- Agents run once per cask creation (not repeatedly)
- User can approve "for this session" to reduce friction
- When bug #14956 is fixed, can add `allowed-tools` to agents

**Future improvement:** When the bug is fixed, add `allowed-tools` to each agent's definition and the orchestrating skill.

---

## Implementation Plan

### Phase 1: Foundation
- [x] Archive v1 plugin
- [x] Create v2 scaffold
- [x] Research Claude Code capabilities
- [x] Document architecture decision
- [x] Create test case(s) for validation

### Phase 2: Scripts
- [x] `scripts/download-checksum.sh` - Download file, calculate SHA256
- [x] `scripts/test-cask.sh` - Run audit, style, livecheck with structured output
- [x] Test scripts in isolation

### Phase 3: Agents
Build and test each agent independently:
- [x] `agents/pre-flight-checker.md` (sonnet - judgment-heavy research)
- [x] `agents/app-inspector.md` (sonnet - metadata extraction)
- [x] `agents/livecheck-advisor.md` (sonnet - strategy selection)
- [x] `agents/cask-writer.md` (sonnet - template synthesis)
- [x] `agents/pr-submitter.md` (haiku - git operations)

**Homebrew docs to reference** (at `/opt/homebrew/docs/`):

| Agent | Primary Docs |
|-------|--------------|
| pre-flight-checker | `Acceptable-Casks.md` |
| app-inspector | `Cask-Cookbook.md` (stanza reference) |
| livecheck-advisor | `Brew-Livecheck.md` |
| cask-writer | `Cask-Cookbook.md` |
| pr-submitter | `Adding-Software-to-Homebrew.md` |

### Phase 4: Integration
- [x] `skills/new-cask/SKILL.md` - Orchestrating skill
- [ ] End-to-end test on real cask submission
- [ ] Handle error cases and edge cases

### Phase 5: Polish
- [ ] README documentation
- [ ] Reference docs (migrate useful content from v1)
- [ ] Re-enable in settings.json

---

## Test Cases

Collect real apps to test against:

| App | URL | Complexity | Notes |
|-----|-----|------------|-------|
| Codex App | `https://persistent.oaistatic.com/codex-app-prod/Codex.dmg` | Simple | DMG, unversioned URL → `sha256 :no_check`, token collision with `codex` CLI |
| TBD | | Medium | Dual-arch, Sparkle |
| TBD | | Complex | PKG installer or edge case |

---

## Session Log

### 2026-02-02: Initial Setup + Research
- Archived v1 plugin to `homebrew-v1/`
- Created v2 plugin scaffold with references
- Scraped official Claude Code docs (skills, subagents, plugins)
- **Key finding:** Subagents cannot spawn subagents
- Decided on orchestrating skill + chained agents pattern
- Updated this design document with findings

### 2026-02-02: Phase 2 Scripts
- Selected test case: **Codex App** (OpenAI's GUI desktop app, distinct from `codex` CLI cask)
  - URL: `https://persistent.oaistatic.com/codex-app-prod/Codex.dmg`
  - Unversioned URL → `sha256 :no_check` scenario
  - Token collision → would be named `codex-app`
- Created `scripts/download-checksum.sh`:
  - Downloads to /tmp, calculates SHA256
  - Structured output: `path:`, `sha256:`, `size:`
  - Tested successfully with Codex App (147MB, checksum: `665656a6...`)
- Created `scripts/test-cask.sh`:
  - Runs audit, style, livecheck (all checks, doesn't stop on first failure)
  - Structured output with pass/fail status per check
  - `--skip-livecheck` flag for unversioned URL casks
  - Tested on existing cask (1password) and failure case
### 2026-02-02: Phase 3 Agents
- Created all 5 agents with appropriate model choices:
  - **pre-flight-checker** (sonnet): Duplicate detection, rejection history, acceptability checks
    - Tools: Bash, Read, Grep, Glob, WebFetch, WebSearch
    - References Acceptable-Casks.md for rejection criteria
  - **app-inspector** (sonnet): Extract metadata from mounted DMG/app
    - Extracts: version, bundle ID, min macOS, auto-updates, Sparkle URL, architecture
    - Uses defaults read, plutil, file/lipo commands
  - **livecheck-advisor** (sonnet): Recommend optimal livecheck strategy
    - Strategy priority: Sparkle > HeaderMatch > JSON > Git > PageMatch > ExtractPlist
    - References Brew-Livecheck.md for strategy details
  - **cask-writer** (sonnet): Synthesize gathered info into cask file
    - Follows official stanza order from Cask-Cookbook.md
    - Handles: URL verification, architecture blocks, zap paths
  - **pr-submitter** (haiku): Git branch, commit, push, create PR
    - Uses PR template from homebrew-cask repo
    - Includes AI disclosure section
- Model selection rationale: sonnet for most agents, haiku for pr-submitter (mechanical git operations)
### 2026-02-02: Phase 4 Orchestrating Skill
- Created `skills/new-cask/SKILL.md`:
  - Runs in main context (NOT `context: fork`) to enable Task tool usage
  - Accepts URL via $ARGUMENTS, prompts if not provided
  - Chains agents sequentially: pre-flight → download → inspect → livecheck → write → test → PR
  - Uses scripts for deterministic work (download-checksum.sh, test-cask.sh)
  - Includes manual testing pause for user to install/test/createzap
  - References `${CLAUDE_PLUGIN_ROOT}` for script paths
- Plugin structure complete:
  - 5 agents in `agents/`
  - 1 skill in `skills/new-cask/`
  - 2 scripts in `scripts/`
  - Auto-discovery enabled (no explicit registration needed)
- **Next:** Nuke plugin cache, end-to-end test with Codex App

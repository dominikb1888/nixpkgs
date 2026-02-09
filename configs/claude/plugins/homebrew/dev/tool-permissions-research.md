# Tool Permissions in Claude Code: Research & Findings

> **Context:** This document captures research from February 2026 on how `allowed-tools` works (and doesn't work) in Claude Code skills. Created to inform a planned refactor of the `new-cask` skill into a multi-agent architecture.

## Executive Summary

The `allowed-tools` field in skill frontmatter is **documented to auto-approve tools** but has a **confirmed bug** that prevents this from working reliably for Bash commands. Until fixed, workarounds include: global settings.json permissions, wrapper scripts, or PreToolUse hooks.

---

## How `allowed-tools` Is Supposed to Work

### Documentation Claims

From [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills):

> "Use the `allowed-tools` field to limit which tools Claude can use when a skill is active."

> "Skills that define `allowed-tools` grant Claude access to those tools **without per-use approval** when the skill is active. Your permission settings still govern baseline approval behavior for all other tools."

The frontmatter reference table describes it as:
> "Tools Claude can use without asking permission when this skill is active."

### Intended Behavior

1. When a skill is invoked, its `allowed-tools` become active
2. Tools matching those patterns should execute without permission prompts
3. Tools NOT in `allowed-tools` still follow normal permission rules
4. The field both **grants** (auto-approve listed tools) and **restricts** (only listed tools available)

### Supported Syntax

From documentation and working examples:

```yaml
# Simple tool names (allow all uses of that tool)
allowed-tools: Read, Grep, Glob

# Tool with any arguments
allowed-tools: Bash(*)

# Tool with specific command prefix
allowed-tools: Bash(git *)

# Tool with exact command
allowed-tools: Bash(npm run build)

# Multiple patterns (comma-separated)
allowed-tools: >-
  Bash(brew *),
  Bash(git *),
  Read(/opt/homebrew/**),
  Edit(*/Casks/**/*.rb)
```

### Pattern Matching Rules

From [code.claude.com/docs/en/iam#tool-specific-permission-rules](https://code.claude.com/docs/en/iam#tool-specific-permission-rules):

**Bash patterns:**
- `Bash(npm run build)` - Exact match
- `Bash(npm run test *)` - Commands starting with `npm run test ` (space before `*` = word boundary)
- `Bash(npm*)` - Matches `npm`, `npmx`, etc. (no space = no word boundary)
- `Bash(* --help)` - Commands ending with ` --help`

**Read/Edit/Write patterns** (gitignore-style):

| Pattern | Meaning | Example |
|---------|---------|---------|
| `//path` | Absolute from filesystem root | `Read(//Users/alice/secrets/**)` |
| `~/path` | From home directory | `Read(~/Documents/*.pdf)` |
| `/path` | Relative to settings file | `Edit(/src/**/*.ts)` |
| `path` | Relative to cwd | `Read(*.env)` |

**Important:** `/Users/alice/file` is NOT absolute - it's relative to your settings file. Use `//Users/alice/file` for absolute paths.

---

## The Bug: `allowed-tools` Doesn't Grant Bash Permissions

### Confirmed Issue

**GitHub Issue #14956** (opened Dec 21, 2025, still open as of Jan 28, 2026):
[github.com/anthropics/claude-code/issues/14956](https://github.com/anthropics/claude-code/issues/14956)

**Symptoms:**
- Skill correctly reports `"allowedTools": ["Bash(pattern)"]` in metadata
- Subsequent Bash calls matching the pattern still trigger permission prompts
- Affects macOS, WSL2, and other platforms
- Multiple users confirm the issue

**Example from issue:**
```yaml
allowed-tools: Bash(say -v "Samantha":*)
```
The skill shows the tool is "allowed" but running `say -v "Samantha" "hello"` still prompts for permission.

### Related Issues

- **#18837** (Jan 17, 2026): `allowed-tools` not enforced - closed as duplicate of #14956
- **#1271** (May 23, 2025, 32+ reactions): Piped commands (`|`, `&&`, `;`) always prompt even when components are allowed - marked "in progress"
- **#13340** (Dec 7, 2025, 17+ reactions): `settings.json` allow permissions not respected for piped commands

### Root Cause (Hypothesized)

The permission system uses **prefix matching** on the entire command string. Complex commands (pipes, redirects, environment variables) don't match simple patterns.

Example: `Bash(curl *)` won't match:
- `URL=http://example.com && curl $URL` (variable expansion)
- `curl http://example.com | jq .` (pipe)
- `curl -L http://example.com > file.txt` (redirect)

---

## Permission System Architecture

### Evaluation Order (as of v2.1.27, Jan 30, 2026)

```
Hooks (PreToolUse)
    ↓
Permission Rules (evaluated in order: deny → ask → allow)
    ↓
Permission Mode (default, acceptEdits, plan, dontAsk, bypassPermissions)
    ↓
canUseTool callback
```

**Key insight:** "Ask" rules take precedence over "allow" rules. If a tool is in both lists, you'll still be prompted.

### Settings Hierarchy (highest to lowest precedence)

1. **Managed settings** (`managed-settings.json`) - organization policies
2. **Command line arguments** - flags like `--dangerously-skip-permissions`
3. **Local project settings** (`.claude/settings.local.json`)
4. **Shared project settings** (`.claude/settings.json`)
5. **User settings** (`~/.claude/settings.json`)

Higher levels cannot be overridden by lower levels.

### Where Skill `allowed-tools` Fits

Unclear. Documentation doesn't specify how skill-level `allowed-tools` interact with:
- Global deny rules in settings.json
- The evaluation order above
- `context: fork` subagent execution

This ambiguity may be part of why the feature doesn't work as expected.

---

## Workarounds

### Option 1: Global settings.json

Add permissions to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(defaults read *)",
      "Bash(hdiutil attach *)",
      "Bash(hdiutil detach *)",
      "Bash(ls /Volumes/*)",
      "Bash(shasum *)",
      "Bash(curl -Lo /tmp/*)"
    ]
  }
}
```

**Pros:** Simple, works immediately
**Cons:** Not scoped to skill, clutters global config

### Option 2: Wrapper Scripts

Create scripts in the skill's `scripts/` directory that wrap multiple commands:

```bash
#!/bin/bash
# scripts/app-info.sh - Get all app metadata at once
APP_PATH="$1"
PLIST="$APP_PATH/Contents/Info.plist"

echo "Version: $(defaults read "$PLIST" CFBundleShortVersionString 2>/dev/null)"
echo "Bundle ID: $(defaults read "$PLIST" CFBundleIdentifier 2>/dev/null)"
echo "Min macOS: $(defaults read "$PLIST" LSMinimumSystemVersion 2>/dev/null || echo 'Not specified')"
# etc.
```

Then allow the script: `Bash(*/new-cask/scripts/*)`

**Pros:** Scoped to skill, cleaner allowed-tools list
**Cons:** Inflexible for exploratory workflows, more files to maintain

**Best for:** Predictable, repeatable operations (not ad-hoc exploration)

### Option 3: PreToolUse Hook

Create a hook that auto-approves commands during skill execution:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/skill-permission-helper.sh"
          }
        ]
      }
    ]
  }
}
```

The hook script would need to:
1. Detect if a relevant skill is active (unclear how to do this reliably)
2. Check if the command matches allowed patterns
3. Return exit code 0 (approve), 1 (continue normal flow), or 2 (deny)

**Pros:** Most flexible, truly scoped to skill execution
**Cons:** Complex to implement, skill-active detection is unclear

### Option 4: Accept Prompts, Wait for Fix

The bug should be fixed eventually. Add a comment/upvote to GitHub #14956.

**Pros:** No workaround maintenance
**Cons:** Friction in the meantime

---

## Considerations for Multi-Agent Refactor

### Why Agents Might Help

Breaking the skill into specialized agents could:

1. **Isolate permission scopes** - Each agent has narrow, testable permissions
2. **Enable incremental testing** - Verify each agent works before combining
3. **Simplify debugging** - Identify which agent/step has permission issues
4. **Support `context: fork`** - Agents run in isolated contexts with their own tool access

### Potential Agent Structure

```
/new-cask (orchestrator skill)
    │
    ├── preflight-checker (agent)
    │   Tools: Bash(brew search *), Bash(brew info *), Bash(gh *)
    │   Task: Check duplicates, rejection history, acceptability
    │
    ├── app-inspector (agent)
    │   Tools: Bash(hdiutil *), Bash(defaults read *), Read(/Volumes/**)
    │   Task: Mount DMG, extract version/bundle-id/min-macos/sparkle info
    │
    ├── download-checksummer (agent)
    │   Tools: Bash(curl *), Bash(shasum *)
    │   Task: Download installer, calculate SHA256
    │
    ├── cask-writer (agent)
    │   Tools: Read(/opt/homebrew/**), Write(*/Casks/**/*.rb)
    │   Task: Generate the .rb cask file
    │
    ├── cask-tester (agent)
    │   Tools: Bash(brew audit *), Bash(brew style *), Bash(brew livecheck *)
    │   Task: Run audit, style, livecheck checks
    │
    └── pr-submitter (agent)
        Tools: Bash(git *), Bash(gh pr create *)
        Task: Create branch, commit, push, open PR
```

### Questions to Resolve

1. **Does `allowed-tools` work in agent definitions?**
   - Agents use similar frontmatter to skills
   - Need to test if the bug affects agents too

2. **How do agents inherit/override permissions?**
   - Does `context: fork` reset permissions?
   - Can parent skill's `allowed-tools` flow to child agents?

3. **Script vs. direct command for each agent?**
   - Some agents (like app-inspector) might benefit from scripts
   - Others (like cask-writer) need flexibility

4. **How to pass data between agents?**
   - Structured output from each agent
   - Orchestrator skill collects and passes to next agent

### Testing Strategy

For each agent:
1. Create minimal agent with narrow `allowed-tools`
2. Test in isolation - does it run without prompts?
3. If prompts appear, try:
   - Script wrapper for that agent's commands
   - Different permission syntax
   - Global settings.json as baseline comparison
4. Document what works/doesn't for each agent
5. Combine working agents into orchestrated workflow

---

## References

### Official Documentation
- [Skills documentation](https://code.claude.com/docs/en/skills)
- [IAM / Tool permissions](https://code.claude.com/docs/en/iam#tool-specific-permission-rules)
- [Settings reference](https://code.claude.com/docs/en/settings)
- [Hooks guide](https://code.claude.com/docs/en/hooks)
- [Subagents](https://code.claude.com/docs/en/sub-agents)

### GitHub Issues
- [#14956 - Skill allowed-tools doesn't grant Bash permissions](https://github.com/anthropics/claude-code/issues/14956) (OPEN)
- [#18837 - allowed-tools not enforced](https://github.com/anthropics/claude-code/issues/18837) (duplicate)
- [#1271 - Piped commands bypass restrictions](https://github.com/anthropics/claude-code/issues/1271) (in progress)
- [#13340 - settings.json allow not respected](https://github.com/anthropics/claude-code/issues/13340) (OPEN)

### Community Resources
- [Egghead: Build Better Tools with Scripts](https://egghead.io/lessons/build-better-tools-in-claude-skills-with-scripts~0oa34) - John Lindquist
- [Instructa: How to use Allowed Tools](https://www.instructa.ai/blog/claude-code/how-to-use-allowed-tools-in-claude-code)

---

## Changelog

- **2026-02-02:** Initial research compiled from deep-research session. Confirmed bug #14956, documented workarounds, outlined multi-agent refactor considerations.

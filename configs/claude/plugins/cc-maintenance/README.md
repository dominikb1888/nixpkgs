# CC Maintenance

Claude Code maintenance utilities for keeping your configuration healthy.

## Requirements

- [fd](https://github.com/sharkdp/fd) - fast `find` alternative (`brew install fd`)
- Python 3

## Skills

### audit-permissions

Scan project-local Claude Code settings files, aggregate permission patterns, and recommend promotions to global configuration.

**Trigger phrases:** "audit claude permissions", "audit permissions", "review local claude settings", "promote permissions to global", "clean up claude settings"

**What it does:**

1. **Discover** - Finds all `settings.local.json` files across your home directory
2. **Analyze** - Aggregates permissions, identifies patterns appearing in multiple projects
3. **Promote** - Recommends safe permissions for global config (with your approval)
4. **Clean up** - Removes redundant local permissions now covered by global
5. **Security hygiene** - Flags risky or stale permissions for review

**Example:**

```
> audit my claude permissions

[Scans projects, presents findings]

## Promotion Candidates

### Strong Recommendations
| Permission        | Projects | Suggested Global Pattern |
| ----------------- | -------- | ------------------------ |
| Bash(cargo test)  | 5        | Bash(cargo test:*)       |
| Bash(npm run build) | 3      | Bash(npm run build:*)    |

[Asks which to add, then cleans up redundant local entries]
```

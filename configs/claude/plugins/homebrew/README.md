# homebrew

A Claude Code plugin for working with Homebrew - cask creation, package management, and more.

## Skills

### new-cask

Guided workflow for creating and submitting Homebrew casks for macOS applications.

**Features:**

- **Pre-flight checks**: Duplicate detection, rejection history, acceptability verification
- **Information gathering**: Download URLs, version discovery, checksum calculation, auto-update detection, zap path discovery
- **Cask creation**: Templates for basic casks, architecture-specific versions, unversioned URLs
- **Livecheck configuration**: Strategy selection with detailed patterns for Sparkle, JSON, GitHub, etc.
- **Testing workflow**: Audit, style, livecheck, install/uninstall verification
- **PR submission**: Git workflow, PR template usage, AI disclosure format

## Prerequisites

- Homebrew installed
- GitHub CLI (`gh`) authenticated
- A fork of `Homebrew/homebrew-cask` with remote configured
- `nrlquaker/createzap` tap for zap path discovery:
  ```bash
  brew tap nrlquaker/createzap
  ```

## Usage

Invoke with `/homebrew:new-cask <download-url>` or ask Claude to create a Homebrew cask for an app.

Example:

```
/homebrew:new-cask https://example.com/downloads/MyApp.dmg
```

Or conversationally:

```
Create a homebrew cask for MyApp
```

## Contents

- `skills/new-cask/SKILL.md` - Main workflow guide
- `skills/new-cask/references/livecheck-strategies.md` - Detailed livecheck patterns
- `skills/new-cask/scripts/test-cask` - Automated testing script

## Notes

- The skill handles token collisions (e.g., when CLI and GUI app share a name)
- Shared configuration directories (like `~/.appname`) are flagged to prevent breaking related casks
- PR workflow includes proper fork handling and AI disclosure format

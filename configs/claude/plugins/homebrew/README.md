# homebrew

A Claude Code plugin for creating and submitting Homebrew casks for macOS applications.

> **Experimental.** This plugin's architecture and agent design are still evolving and subject to significant change.

## Usage

```
/homebrew:new-cask <download-url>
```

Or conversationally: "Create a homebrew cask for MyApp"

## Architecture

An orchestrating skill (`new-cask`) coordinates specialist agents through a multi-step workflow:

1. **Pre-flight checks** (agent) - Duplicate detection, rejection history, acceptability
2. **App inspection** (agent) - Download, mount/extract, extract metadata
3. **Livecheck strategy** (agent) - Recommend version tracking approach
4. **Cask writing** (agent) - Write the .rb file with proper stanzas
5. **Testing** (script) - Audit, style, livecheck checks
6. **PR submission** (agent) - Branch, commit, push, create PR

See `dev/design.md` for design rationale and progress tracking.

## Prerequisites

- Homebrew installed
- GitHub CLI (`gh`) authenticated
- A fork of `Homebrew/homebrew-cask` with remote configured

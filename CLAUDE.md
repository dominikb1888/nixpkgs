# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build and switch to the macOS nix-darwin configuration
nh darwin switch --no-nom

# Build without switching (for testing)
nh darwin build --no-nom

# Update all flake inputs
nix flake update

# Update a specific input
nix flake update nixpkgs-unstable
```

## Architecture

This is a Nix flake that manages system configuration for macOS (via nix-darwin) and Linux (via home-manager).

### Key Structure

- **`flake.nix`** - Main entry point defining inputs, outputs, overlays, and system configurations
- **`darwin/`** - nix-darwin modules for macOS system-level configuration
- **`home/`** - home-manager modules for user-level configuration
- **`modules/`** - Reusable modules (both darwin and home-manager)
- **`lib/`** - Helper functions including `mkDarwinSystem`
- **`configs/`** - Application configs (Claude Code) symlinked for live editing
- **`overlays/`** - Nixpkgs overlays

### System Configurations

- **`darwinConfigurations.MaloBookPro`** - Primary macOS config, built with `lib.mkDarwinSystem`
- **`darwinConfigurations.githubCI`** - CI variant with homebrew disabled
- **`homeConfigurations.malo`** - Standalone home-manager config for Linux

### User Info Pattern

User info is defined once and referenced throughout:

1. Passed to `lib.mkDarwinSystem` as `username`, `fullName`, `email`, `nixConfigDirectory`
2. Set on `users.primaryUser` in darwin config
3. Available as `config.home.user-info` in all home-manager modules

Example usage in a home module:
```nix
{ config, ... }:
let
  inherit (config.home.user-info) email nixConfigDirectory;
in { ... }
```

### Live-Editable Configs

Files in `configs/` are symlinked via `mkOutOfStoreSymlink`, allowing edits without rebuild:
- `configs/claude/` → `~/.claude/` (CLAUDE-USER.md → CLAUDE.md, settings.json, commands, plugins, etc.)

**Claude Code settings** use a hybrid approach:
- **`managed-settings.json`** (Nix-generated at `/Library/Application Support/ClaudeCode/`):
  Has highest precedence. Contains only path-dependent settings needing `nixConfigDirectory`
  interpolation (`additionalDirectories`, nix-config permissions, `extraKnownMarketplaces`).
  Created by `darwin/claude-managed-settings.nix`.
- **`settings.json`** (user-editable symlink from `configs/claude/`):
  All other settings using portable `~` paths. Edit directly without rebuild.

**MCP architecture:** Uses 1MCP to aggregate all MCP servers. Server definitions are in
`configs/claude/1mcp.json` (symlinked to `~/.config/1mcp/mcp.json`). The Nix-generated
`~/.claude/mcp.json` just points CLI to 1MCP on localhost:3050. 1MCP runs as a LaunchAgent
(`com.malo.1mcp`, defined in `home/claude.nix`). After editing `1mcp.json`, restart it:
```bash
launchctl kickstart -k gui/$(id -u)/com.malo.1mcp
```

### Package Version Overlays

Access packages from different nixpkgs channels via overlays:
```nix
pkgs.pkgs-master.some-package    # bleeding edge
pkgs.pkgs-unstable.some-package  # nixpkgs-unstable
pkgs.pkgs-stable.some-package    # stable release
pkgs.pkgs-x86.some-package       # x86 version (Apple Silicon only)
```

## Common Tasks

**Add a package:** Edit `home/packages.nix`, add to the appropriate category's `inherit` block.

**Add a new home-manager module:**
1. Create `home/tool.nix` with the module configuration
2. Add `malo-tool = import ./home/tool.nix;` to `homeManagerModules` in `flake.nix`
3. The module is automatically included via `attrValues self.homeManagerModules`

**Add a darwin module:** Same pattern in `darwin/` directory and `darwinModules` in flake.nix.

**Add an external Claude Code skill:** Add to `externalSkills` in `home/claude.nix`, then rebuild.
Custom skills go in `configs/claude/skills/<malo-prefix>/` as regular directories (committed to git).
External skills are symlinks managed by the activation script (gitignored).

**Iterate on Claude Code plugins:** Plugins in `configs/claude/plugins/` are symlinked but cached by Claude. After making changes, nuke the cache and restart:
```bash
rm -rf ~/.claude/plugins/cache/malos-plugins/<plugin-name>
# Then restart Claude Code
```

## Conventions

- Follow nixpkgs code style
- Line length: 100 columns
- Section banners: `# Section name` followed by dashes to column 100, with a blank line before and after
- Module files named for their purpose (e.g., `git.nix`, `fish.nix`)
- Home-manager modules prefixed with `malo-` in flake outputs
- Use `inherit` for clarity when pulling from attribute sets
- Extract repeated deep paths into `let`/`inherit` at the top of each file. If a dotted path like
  `config.home.homeDirectory`, `pkgs.stdenv.isDarwin`, or `lib.mkIf` appears two or more times in
  a file body, pull it into the `let` block (e.g., `inherit (config.home) homeDirectory;`). Single-use
  paths are fine inline — the goal is compactness when repetition adds noise

## Gotchas

- **Home-manager activation PATH:** Activation scripts run with a minimal PATH (bash, coreutils,
  findutils, etc.) — no `node`, `git`, or user-profile binaries. Use full nix store paths
  (e.g. `${pkgs.nodejs}/bin/npx`) or prepend to PATH explicitly.
- **`run --silence` hides errors:** Home-manager's `run --silence` redirects both stdout and
  stderr to `/dev/null`. When debugging activation scripts, temporarily remove `--silence` or
  use `run` without flags to see output. The generated script is at
  `~/.local/state/home-manager/gcroots/current-home/activate`.

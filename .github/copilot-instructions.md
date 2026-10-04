# Copilot instructions for this repository

## Project overview

This repository is a flake-based Nix configuration for my macOS and Linux setup. Most real behavior is declared in Nix modules rather than shell scripts or application code. The repo is organized around a small set of design centers:

- `flake.nix` defines the flake inputs, overlays, reusable modules, and outputs.
- `darwin/*.nix` contains system-level macOS configuration (bootstrap, system defaults, general settings, Homebrew setup).
- `home/*.nix` contains user-level configuration for shells, git, tmux, Neovim, packages, colors, and other app settings.
- `modules/` holds reusable modules that can be imported into both Darwin and Home Manager setups.
- `lib/` contains helper functions used to build system configurations.
- `overlays/` adds package sets and helper behavior for the Nix package graph.
- `configs/` holds app config files (for example Neovim Lua config) that are consumed by the Nix modules.

## Build, test, and lint commands

This repo is not a conventional application codebase with unit tests. Validation is done by evaluating and building the Nix flake or specific configurations.

- Format Nix files:
  - `nix fmt`
- Validate the flake and evaluate configurations:
  - `nix flake check`
- Build the main macOS system config:
  - `nix build .#darwinConfigurations.Dominiks-MBP.system`
- Build the Linux home-manager config used for non-NixOS systems:
  - `nix build .#homeConfigurations.malo.activationPackage`
- Start a developer shell defined in the flake:
  - `nix develop .#python`
- Apply the current macOS system config from the repo root:
  - `darwin-rebuild switch --flake .`
- Apply the current Home Manager config from the repo root:
  - `home-manager switch --flake .`

When making a focused change, prefer a targeted `nix build` or `nix flake check` over a broad rebuild of the entire config graph.

## High-level architecture

The main architectural pattern is: compose reusable Nix modules into system and user configurations using the flake outputs.

- `flake.nix` uses a shared `nixpkgsDefaults` block with `allowUnfree = true` and overlays for `nixpkgs-master`, `nixpkgs-stable`, and `nixpkgs-unstable`.
- `lib/mkDarwinSystem.nix` wires together a `nix-darwin` system config and a matching `home-manager` config in one place, including the primary user and home-manager imports.
- `darwinConfigurations` define actual machine configs, such as the Apple Silicon laptop config and a CI-specific override.
- `homeConfigurations.malo` defines the Linux home-manager setup used outside of a full NixOS or nix-darwin machine.
- `homeManagerModules` and `darwinModules` are the extension points for new features or app configuration; prefer adding or extending these before creating ad hoc scripts.
- This repo relies on flake inputs for external tools and utilities; avoid adding direct package sources outside the flake-managed pattern unless there is a clear reason.

## Key conventions

- Keep system-level settings in `darwin/*.nix` and user-level settings in `home/*.nix`; do not mix them in one module unless it is truly shared.
- Prefer declarative Nix module composition over imperative shell setup. If a tool can be configured through `home-manager` or a Darwin module, that is the project’s default pattern.
- Reuse the existing module structure (`attrValues self.darwinModules`, `attrValues self.homeManagerModules`) rather than duplicating configuration blocks.
- Match the repo’s naming and state conventions: `primaryUserDefaults`, `homeStateVersion`, and `home.user-info` are used across the config and should be preserved when extending the setup.
- Use the repo’s flake input versioning pattern instead of pinning packages manually. The flake intentionally tracks `nixpkgs-master`, `nixpkgs-stable`, `nixpkgs-unstable`, and other flake inputs.
- For machine-specific tweaks, prefer overriding an existing configuration (`.override`) or adding a small module instead of copying an entire configuration.

## Working effectively in this repo

- Start by looking at `flake.nix` for the top-level wiring and outputs before editing individual modules.
- When debugging config drift, inspect the relevant module under `darwin/` or `home/` and then check whether the feature is also exposed through a reusable module under `modules/`.
- When adding new tools or packages, prefer extending the correct module and the flake’s overlay/input pattern rather than doing manual installation steps.
- Keep changes aligned with the repository’s declarative style: configuration should be expressible as Nix modules and evaluated by Nix, not by runtime shell commands.

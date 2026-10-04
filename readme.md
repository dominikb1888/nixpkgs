# My Nix Configs

![Build Nix envs](https://github.com/malob/nixpkgs/workflows/Build%20Nix%20envs/badge.svg)

This repo contains my Nix configs for macOS and Linux and by extension, configuration for most tools/programs I use, at least in the terminal.

I'm continuously tweaking/improving my setup, trying to find ways to make more of my configuration declarative, and I like experimenting with bleeding edge updates/features, so this repo sees a lot of changes. I do try to ensure that `master` always builds and doesn't have any bad bugs (at least in my workflow), and keep the code fairly well documented.

Feel free to file an [issue](https://github.com/malob/nixpkgs/issues) or start a [discussion](https://github.com/malob/nixpkgs/discussions) if you find a bug, or think something is broken, or think I'm doing something in a dumb/clumsy way and have a suggestion for a more elegant alternative, or try to crib something from my config but just can't get it working, or are looking at my config and think to yourself "does this guy know about X, cause I bet he'd be into it", or have some other type of feedback/comment. (Issues, are better for things that are actually issues, while discussions are better for ideas, questions, etc.)

I make no promises that I'll respond quickly, or fix the bug (especially if I'm not experiencing it), or whatever, but you definitely shouldn't feel like you're imposing in any way, and I probably will respond within a few days.

Below, I've highlighted stuff that I'm particularly happy with or think others might find helpful/useful.

## Highlights

In no particular order:

* [Flakes](./flake.nix)!
  * All external dependencies managed through flakes for easy updating.
  * Outputs for [`nix-darwin`](https://github.com/LnL7/nix-darwin) macOS system configurations (using `home-manager` as a `nix-darwin` module) and a [`home-manager`](https://github.com/nix-community/home-manager) user configuration for Linux.
  * `darwinModules` output for `nix-darwin` modules that are pending upstream:
    * [`security-pam`](./modules/darwin/security/pam.nix) that provides an option, `enableSudoTouchIdAuth`, which enables using Touch ID for `sudo` authentication. (Pending upstream PR [#228](https://github.com/LnL7/nix-darwin/pull/228).)
    * [`programs-nix-index`](./modules/darwin/programs/nix-index.nix) that augments `nix-darwins`'s `programs.nix-index` module with a command not found handler for Fish. (Pending upstream PR [#272](https://github.com/LnL7/nix-darwin/pull/272).)
  * `homeManagerModules` output for `home-manager` modules with additional functionality and prepackaged configuration:
    * [`malo-git-aliases`](./home/git-aliases.nix)
    * [`malo-gh-aliases`](./home/gh-aliases.nix)
    * [`malo-startship-symbols`](./home/starship-symbols.nix) that provides predefined configuration of symbols for [Starship](https://starship.rs) prompt using NerdFont symbols.
  * Support for non-flake compatible versions of Nix and legacy workflows through [`flake-compat`](https://nixos.wiki/wiki/Flakes#Using_flakes_project_from_a_legacy_Nix):
    * [`default.nix`](./default.nix), allows traditional Nix commands like `nix-build` to operate on the flake inputs/outputs.
    * [`nixpkgs.nix`](./nixpkgs.nix), functions as a wrapper for the `nixpkgs` input of the flake. This can be used for things like setting `<nixpkgs>` by, e.g., setting `nix.nixPath = { nixpkgs = "$HOME/.config/nixpkgs/nixpkgs.nix"; };` in `nix-darwin`.
* Support for Macs with Apple Silicon including ability to easily overlay in x86 version of packages, when they don't build on arm. Search `pkgs-x86` in [`flake.nix`](./flake.nix) and see `nix.extraOptions` in [`darwin/bootstrap.nix`](./darwin/bootstrap.nix) for details.
* A GitHub [workflow](./.github/workflows/ci.yml) that builds the my macOS system `nix-darwin` config and `home-manager` Linux user config, and updates a Cachix cache. Also, once a week it updates all the flake inputs before building, and if the build succeeds, it commits the changes.
* [Git config](./home/git.nix) with a bunch of handy aliases and better diffs using [`delta`](https://github.com/dandavison/delta),
* A slick Neovim 0.6 [config](./configs/nvim) in Lua (some bugs probably exist due to recent update to 0.6). See also: [`neovim.nix`](./home/neovim.nix).
* Unified colorscheme (based on [Solarized](https://ethanschoonover.com/solarized/)) with light and dark variant for [Kitty terminal](https://sw.kovidgoyal.net/kitty), [Fish shell](https://fishshell.com), [Neovim](https://neovim.io), and other tools, where toggling between light and dark can be done for all of them simultaneously by calling a Fish function. This is achieved by:
  * adding Solarized colors to `pkgs` via an [overlay](./overlays/colors.nix);
  * using my `programs-kitty-extras` `home-manager` module (see above);
  * using a self-made WIP Solarized based [colorscheme](./configs/nvim/lua/malo/theme.lua) with Neovim; and
  * a [Fish shell config](./home/fish.nix), which provides a `toggle-background` function (and an alias `tb`) which toggles a universal environment variable (`$term_background`) between the values `"light"` and `"dark"`, along with `set-shell-colors` function which trigger automatically when `$term_background` changes.
* A nice [shell prompt config](./home/starship.nix) for Fish using Starship.

## Herdev

`herdev` starts or reuses the local Ollama and LiteLLM services, then opens a
project-named Herdr session with OMP's `openai/local` model pointed at LiteLLM.
The default Ollama model is `qwen3-coder:30b-a3b-q8_0`; select another installed
model with `HERDEV_OLLAMA_MODEL`. LiteLLM binds to loopback and uses a local-only
development key. Other OMP providers (including Copilot and Antigravity) remain
available as direct alternatives. Firstmate is an instruction/context directory,
not a process: the launcher adds `~/Firstmate` to OMP with `--add-dir` and sets
`FM_HOME` to that directory.

Run `herdev` from a project directory to start or attach to its Herdr session.
Use `herdev stop` from the same directory to stop the named session and its
project-local LiteLLM proxy. Ollama stays available while any other named
Herdr session is running.
To launch it automatically from a project using devenv and direnv, add this to
the project's `devenv.nix`:

```nix
{
  enterShell = ''
    if [ -t 0 ] && [ -t 1 ]; then
      herdev
    fi
  '';
}
```

Then add `use devenv` to `.envrc` and run `direnv allow`. This launches the
interactive Herdr session when entering the project's devenv shell. LiteLLM
uses a project-specific loopback port by default; set
`HERDEV_LITELLM_PORT` to override it. Services started by `herdev` stay up after
detaching so the persistent Herdr session continues to work, and are stopped by
`herdev stop` (services that were already running are left untouched). Set
`HERDEV_SESSION_NAME` to override the generated Herdr session name.

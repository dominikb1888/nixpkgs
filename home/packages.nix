{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isDarwin;

  # Wrap a package's main binary with `op run`, injecting 1Password secret URIs as env vars.
  # Uses symlinkJoin to preserve shell completions, man pages, etc. from the original package.
  mkOpRunWrapper =
    pkg: env:
    let
      mainProgram = pkg.meta.mainProgram or pkg.pname;
      envExports = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}='${v}'") env);
      wrapper = pkgs.writeShellScriptBin mainProgram ''
        ${envExports}
        exec op run -- ${lib.getExe pkg} "$@"
      '';
    in
    pkgs.symlinkJoin {
      name = "${mainProgram}-op-wrapped";
      paths = [
        wrapper
        pkg
      ];
    };

in

{
  # Link apps to ~/Applications/Home Manager Apps
  # Unlike Spotlight, Raycast can find symlinked apps so copying isn't needed
  targets.darwin.copyApps.enable = mkIf isDarwin false;
  targets.darwin.linkApps.enable = mkIf isDarwin true;

  # 1Password CLI plugin integration
  # https://developer.1password.com/docs/cli/shell-plugins/nix
  programs._1password-shell-plugins.enable = true;
  programs._1password-shell-plugins.plugins = attrValues {
    inherit (pkgs) cachix;
  };
  home.sessionVariables = {
    # Fix Nerd Font icons in less/bat (PUA characters not displayed by default in less 632+)
    # https://github.com/ryanoasis/nerd-fonts/wiki/FAQ-and-Troubleshooting#less-settings
    LESSUTFCHARDEF = "E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p";
  };

  # Programs ---------------------------------------------------------------------------------------

  # Bat, a substitute for cat.
  # https://github.com/sharkdp/bat
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.bat.enable
  programs.bat.enable = true;
  programs.bat.config = {
    style = "plain";
  };

  # Btop, a fancy version of `top`.
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.btop.enable
  programs.btop.enable = true;

  # Direnv, load and unload environment variables depending on the current directory.
  # https://direnv.net
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.direnv.enable
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # Eza, a modern, maintained replacement for ls, written in rust
  # https://eza.rocks
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.eza.enable
  programs.eza.enable = true;
  programs.eza.git = true;
  programs.eza.icons = "auto";
  programs.eza.extraOptions = [ "--group-directories-first" ];
  home.sessionVariables.EZA_COLORS = "xx=0"; # https://github.com/eza-community/eza/issues/994
  home.sessionVariables.EZA_ICON_SPACING = 2;

  # SSH
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ssh.enable
  # Some options also set in `../darwin/homebrew.nix`.
  programs.ssh.enable = true;
  programs.ssh.enableDefaultConfig = false;
  programs.ssh.matchBlocks."*".controlPath = "~/.ssh/%C"; # ensures the path is unique but also fixed length

  # nh, a Nix CLI helper with nice output
  # https://github.com/nix-community/nh
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.nh.enable
  programs.nh.enable = true;
  programs.nh.flake = config.home.user-info.nixConfigDirectory;

  # nix-index, a file database for nixpkgs (with pre-built database from nix-index-database)
  # https://github.com/nix-community/nix-index-database
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.nix-index.enable
  programs.nix-index.enable = true;
  programs.nix-index.enableFishIntegration = true;
  programs.nix-index-database.comma.enable = true;

  # Yazi, a blazing fast terminal file manager
  # https://github.com/sxyazi/yazi
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.yazi.enable
  programs.yazi.enable = true;
  programs.yazi.settings = {
    mgr = {
      ratio = [
        1
        3
        4
      ];
      show_hidden = true;
      show_symlink = true;
      linemode = "size";
    };
    preview.wrap = "yes";
  };

  # Zoxide, a faster way to navigate the filesystem
  # https://github.com/ajeetdsouza/zoxide
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zoxide.enable
  programs.zoxide.enable = true;

  # Zsh
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zsh.enable
  programs.zsh.enable = true;
  programs.zsh.dotDir = "${config.xdg.configHome}/zsh";
  programs.zsh.history.path = "${config.xdg.stateHome}/zsh_history";

  # Packages ---------------------------------------------------------------------------------------

  home.packages = attrValues (
    {
      # Some basics
      inherit (pkgs)
        abduco # lightweight session management
        bandwhich # display current network utilization by process
        bottom # fancy version of `top` with ASCII graphs
        coreutils
        curl
        dust # fancy version of `du`
        eza # fancy version of `ls`
        fd # fancy version of `find`
        hyperfine # benchmarking tool
        mosh # wrapper for `ssh` that better and not dropping connections
        parallel # runs commands in parallel
        ripgrep # better version of `grep`
        tealdeer # rust implementation of `tldr`
        # thefuck
        unrar # extract RAR archives
        upterm # secure terminal sharing
        wget
        xz # extract XZ archives
        ;

      # Dev stuff
      inherit (pkgs)
        bun # JavaScript runtime & package manager
        cloc # source code line counter
        colima # container runtime (Docker alternative)
        docker-client # Docker CLI
        google-cloud-sdk
        jq
        nixd # Nix language server
        nodejs
        pnpm
        prettier
        pyright # Python type checker / language server
        s3cmd
        shellcheck
        stack
        typescript
        uv
        ;
      inherit (pkgs.nodePackages)
        vscode-json-languageserver # JSON language server
        ;
      inherit (pkgs.haskellPackages)
        cabal-install
        hoogle
        hpack
        implicit-hie
        ;

      # Useful nix related tools
      inherit (pkgs)
        cachix # adding/managing alternative binary caches hosted by Cachix
        nix-output-monitor # get additional information while building packages
        nix-tree # interactively browse dependency graphs of Nix derivations
        node2nix # generate Nix expressions to build NPM packages
        statix # lints and suggestions for the Nix programming language
        ;

      # Wrapped with `op run` to inject 1Password secrets
      nix-update = mkOpRunWrapper pkgs.nix-update {
        GITHUB_TOKEN = "op://Personal/GitHub Personal Access Token/credential";
      };
      nixpkgs-review = mkOpRunWrapper pkgs.nixpkgs-review {
        GITHUB_TOKEN = "op://Personal/GitHub Personal Access Token/credential";
      };

    }
    // lib.optionalAttrs isDarwin {
      inherit (pkgs)
        cocoapods
        m-cli # useful macOS CLI commands
        mas # macOS App Store CLI
        prefmanager # tool for working with macOS defaults
        # swift-format
        swiftlint
        ;
    }
  );
}

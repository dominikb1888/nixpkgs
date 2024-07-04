{ config, lib, pkgs, ... }:

{
  # Bat, a substitute for cat.
  # https://github.com/sharkdp/bat
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.bat.enable
  programs.bat.enable = true;
  programs.bat.config = {
    style = "plain";
  };

  # Disable manpages until https://github.com/nix-community/home-manager/issues/3342 is fixed
  manual.manpages.enable = false;

  # Direnv, load and unload environment variables depending on the current directory.
  # https://direnv.net
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.direnv.enable
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # Htop
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.htop.enable
  programs.htop.enable = true;
  programs.htop.settings.show_program_path = true;

  # SSH
  # https://nix-community.github.io/home-manager/options.html#opt-programs.ssh.enable
  # Some options also set in `../darwin/homebrew.nix`.
  programs.ssh.enable = true;
  programs.ssh.controlPath = "~/.ssh/%C"; # ensures the path is unique but also fixed length

  # Zoxide, a faster way to navigate the filesystem
  # https://github.com/ajeetdsouza/zoxide
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.zoxide.enable
  programs.zoxide.enable = true;

  home.sessionPath = [
    "$HOME/.local/bin"
  ];
  home.enableNixpkgsReleaseCheck = false;
  home.packages = with pkgs; [
    # Some basics
    bind # DNS Tools
    coreutils
    curl
    fzf # fuzzy commandline finder
    eza # fancy version of `ls`
    fd # fancy version of `find`
    ripgrep-all
    ffmpeg
    ffmpeg-normalize # Audio normalization for ffmpeg
    git-lfs
    btop # fancy version of `top`
    hyperfine # benchmarking tool
    #marp # cli presentation tool -- currently insecure installed via brew
    neofetch
    ngrok
    ripgrep # better version of `grep`
    unrar # extract RAR archives
    wget
    tmate

    # Dev stuff
    exercism
    jq
    nodejs
    podman
    podman-compose

    #VPN
    openconnect
    gnupg

    # Useful nix related tools
    cachix # adding/managing alternative binary caches hosted by Cachix
    comma # run software from without installing it
    devenv # Integrated solution for managing dev environments with nix
    lorri
    niv # easy dependency management for nix projects
    linuxkit # build linux binaries on macos
    nix-tree # interactively browse dependency graphs of Nix derivations
    nix-update # swiss-knife for updating nix packages
    nixpkgs-review # review pull-requests on nixpkgs
    nodePackages.node2nix
    statix # lints and suggestions for the Nix programming language
    # research tools
    # zotero
  ] ++ lib.optionals stdenv.isDarwin [
    hugo # static page builder for blog --current issue with maocs SDK, seems to be fixed by PR github/nixos/nixpakgs#176661
    m-cli # useful macOS CLI commands
    pandoc
    prefmanager # tool for working with macOS defaults
    slides
    texliveSmall
    texlivePackages.tcolorbox
    pandoc-fignos
    xquartz
  ];
}

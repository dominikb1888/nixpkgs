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

  # Zoxide, a faster way to navigate the filesystem
  # https://github.com/ajeetdsouza/zoxide
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.zoxide.enable
  programs.zoxide.enable = true;

  home.packages = with pkgs; [
    # Some basics
    abduco # lightweight session management
    bandwhich # display current network utilization by process
    bottom # fancy version of `top` with ASCII graphs
    # browsh # in terminal browser
    coreutils
    curl
    du-dust # fancy version of `du`
    fzf # fuzzy commandline finder
    exa # fancy version of `ls`
    fd # fancy version of `find`
    ffmpeg
    ffmpeg-normalize # Audio normalization for ffmpeg
    git-lfs
    htop # fancy version of `top`
    hyperfine # benchmarking tool
    # marp # cli presentation tool -- currently insecure installed via brew
    imagemagick
    kind # kubernetes in local docker image
    mosh # wrapper for `ssh` that better and not dropping connections
    miller # command-line data analysis
    ngrok
    nodePackages.speed-test # nice speed-test tool
    parallel # runs commands in parallel
    # python3Packages.shell-functools # a collection of functional programming tools for the shell
    ripgrep # better version of `grep`
    swiProlog
    thefuck
    unrar # extract RAR archives
    wget
    xz # extract XZ archives
    yank
    xsel # get contents of clipboard to STDOUT
    # Dev stuff
    # (agda.withPackages (p: [ p.standard-library ]))
    cloc # source code line counter
    jq
    nodejs-slim-14_x
    nodePackages.node-pre-gyp
    nodePackages.typescript
    nodejs
    visidata

    # node-canvas deps
    # libuuid
    pkg-config
    cairo
    pango
    libpng
    libjpeg
    giflib
    librsvg

    # Useful nix related tools
    cachix # adding/managing alternative binary caches hosted by Cachix
    comma # run software from without installing it
    lorri
    niv # easy dependency management for nix projects
    # linuxkit # build linux binaries on macos
    nix-tree # interactively browse dependency graphs of Nix derivations
    nix-update # swiss-knife for updating nix packages
    nixpkgs-review # review pull-requests on nixpkgs
    nodePackages.node2nix
    statix # lints and suggestions for the Nix programming language

    # research tools
    # zotero
  ] ++ lib.optionals stdenv.isDarwin [
    cocoapods
    hugo # static page builder for blog --current issue with maocs SDK, seems to be fixed by PR github/nixos/nixpakgs#176661
    m-cli # useful macOS CLI commands
    pandoc
    prefmanager # tool for working with macOS defaults
    slides
    tealdeer # rust implementation of `tldr`
    termdown
    texlive.combined.scheme-full
  ];
}

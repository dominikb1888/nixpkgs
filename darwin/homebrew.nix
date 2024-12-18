{ config, lib, ... }:

let
  inherit (lib) mkIf;
  mkIfCaskPresent = cask: mkIf (lib.any (x: x.name == cask) config.homebrew.casks);
  brewEnabled = config.homebrew.enable;
in

{
  environment.shellInit = mkIf brewEnabled ''
    eval "$(${config.homebrew.brewPrefix}/brew shellenv)"
  '';

  # https://docs.brew.sh/Shell-Completion#configuring-completions-in-fish
  # For some reason if the Fish completions are added at the end of `fish_complete_path` they don't
  # seem to work, but they do work if added at the start.
  programs.fish.interactiveShellInit = mkIf brewEnabled ''
    if test -d (brew --prefix)"/share/fish/completions"
      set -p fish_complete_path (brew --prefix)/share/fish/completions
    end

    if test -d (brew --prefix)"/share/fish/vendor_completions.d"
      set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
    end
  '';

  homebrew.enable = true;
  homebrew.onActivation.autoUpdate = true;
  homebrew.onActivation.cleanup = "zap";
  homebrew.global.brewfile = true;

  homebrew.taps = [
  #  "homebrew/cask-fonts"
  #  "homebrew/cask-versions"
    "homebrew/services"
    "nrlquaker/createzap"
    "muesli/homebrew-tap"
    "linuxkit/linuxkit"
  ];

  # Prefer installing application from the Mac App Store
  #
  # Commented apps suffer continual update issue:
  # https://github.com/malob/nixpkgs/issues/9
  homebrew.masApps = {
    #eduVPN = 1317704208;
    #Slack = 803453959; # Error on downloading via app store
    #Xcode = 497799835; # Very slow download via app store - deactivated
  };

  # If an app isn't available in the Mac App Store, or the version in the App Store has
  # limitiations, e.g., Transmit, install the Homebrew Cask.
  homebrew.casks = [
    "alfred"
    "burp-suite"
    "gpg-suite"
    "google-chrome"
    "onedrive"
    "notunes"
    "protege"
    "r"
    "rstudio"
    "microsoft-teams"
    "visual-studio-code"
    "vlc"
  ];

  # For cli packages that aren't currently available for macOS in `nixpkgs`.Packages should be
  # installed in `../home/default.nix` whenever possible.
  homebrew.brews = [
    "marp-cli"
    "slides"
  ];
}

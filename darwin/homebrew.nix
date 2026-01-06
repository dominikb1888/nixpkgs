{ config, lib, ... }:

let
  inherit (lib) mkIf;
  mkIfCaskPresent = cask: mkIf (lib.any (x: x.name == cask) config.homebrew.casks);
  brewEnabled = config.homebrew.enable;
  caskPresent = cask: lib.any (x: x.name == cask) config.homebrew.casks;
  brewShellInit = mkIf brewEnabled ''
    eval "$(${config.homebrew.brewPrefix}/brew shellenv)"
  '';
in
{
  environment.shellInit = brewShellInit;
  programs.zsh.shellInit = brewShellInit; # `zsh` doesn't inherit `environment.shellInit`

  # https://docs.brew.sh/Shell-Completion#configuring-completions-in-fish
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
    "ghostty"
    "r-app"
    "rstudio"
    "microsoft-teams"
    "visual-studio-code"
    "vlc"
    "zap"
  ];

  # Hack: https://github.com/ghostty-org/ghostty/discussions/2832
  environment.variables.XDG_DATA_DIRS =
    mkIf (caskPresent "ghostty") ["$GHOSTTY_SHELL_INTEGRATION_XDG_DIR"];

  # For cli packages that aren't currently available for macOS in `nixpkgs`.Packages should be
  # installed in `../home/default.nix` whenever possible.
  homebrew.brews = [
    "mole"
    "marp-cli"
    "slides"
  ];
}

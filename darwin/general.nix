{ pkgs, ... }:

{
  # Apps
  # `home-manager` currently has issues adding them to `~/Applications`
  # Issue: https://github.com/nix-community/home-manager/issues/1341
  environment.systemPackages = with pkgs; [
    terminal-notifier
  ];

  # Fonts
  # TODO: Re-enable once https://github.com/LnL7/nix-darwin/issues/485 is resolved
  fonts.packages = with pkgs; [
     recursive
     nerd-fonts.jetbrains-mono
   ];

  # Keyboard
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  #system.stateVersion = 4;

  # Disable documentation until https://github.com/LnL7/nix-darwin/issues/217 is fixed.
  documentation.enable = false;

  # Store management
  nix.gc.automatic = true;
  nix.gc.interval.Hour = 3;
  nix.gc.options = "--delete-older-than 15d";
  nix.optimise.automatic = true;
  nix.optimise.interval.Hour = 4;
}

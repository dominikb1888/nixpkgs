{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) elem;
  inherit (config.home.user-info) nixConfigDirectory;
in

{
  # Fish Shell
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.fish.enable
  programs.fish.enable = true;

  # Fish theme file (auto-switches on terminal background change via OSC detection)
  xdg.configFile."fish/themes/ok-solar.theme".text = ''
    # name: OK Solar
    # url: https://meat.io/oksolar

    [light]
    ${config.colors.malo-ok-solar.light.fishThemeSection}

    [dark]
    ${config.colors.malo-ok-solar.dark.fishThemeSection}
  '';

  # Fish functions ---------------------------------------------------------------------------------

  programs.fish.functions = {
    # TODO: Replace with Ghostty's native command completion notifications when available
    # Custom notification function using escape sequences - avoids done plugin conflicts
    notify-done = {
      body = ''
        if test $CMD_DURATION -gt 10000
          set -l cmd_time (math $CMD_DURATION / 1000)
          printf '\e]777;notify;Ghostty;Command finished - Took %ss\e\\' $cmd_time
        end
      '';
      onEvent = "fish_postexec";
    };

    # Toggles macOS dark mode; Ghostty and Fish follow automatically via OSC detection
    toggle-background.body = ''
      osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode'
    '';
  }
  // lib.optionalAttrs (elem pkgs.bottom config.home.packages) {
    btm = {
      body = ''
        if test "$fish_terminal_color_theme" = light
          command btm --theme default-light $argv
        else
          command btm $argv
        end
      '';
      wraps = "btm";
    };
  };

  # Fish configuration -----------------------------------------------------------------------------

  # Aliases
  home.shellAliases = {
    # Nix related
    drb = "${pkgs.nh}/bin/nh darwin build ${nixConfigDirectory}";
    drs = "${pkgs.nh}/bin/nh darwin switch ${nixConfigDirectory}";
    flakeup = "nix flake update ${nixConfigDirectory}";
    nb = "nix build";
    nd = "nix develop";
    nf = "nix flake";
    nr = "nix run";
    ns = "nix search";

    # Other
    ".." = "cd ..";
    ":q" = "exit";
    cat = "${pkgs.bat}/bin/bat";
    du = "${pkgs.dust}/bin/dust";
    g = "${pkgs.git}/bin/git";
    la = "ll -a";
    tb = "toggle-background";
  };

  programs.fish.shellAbbrs = {
    nix-build-all-systems = {
      expansion = ''
        echo -n x86_64-darwin aarch64-{darwin,linux} | \
          parallel -u -d ' ' nix build -L -f . --system {} %
      '';
      setCursor = true;
    };
    nix-rm-results = ''
      ${pkgs.fd}/bin/fd --hidden --no-ignore --type l '^result-?' --exclude 'Library/**' \
        --exec rm '{}'
    '';
    sysx86d = {
      expansion = "--system x86_64-darwin";
      position = "anywhere";
    };
    sysx86l = {
      expansion = "--system x86_64-linux";
      position = "anywhere";
    };
    sysarmd = {
      expansion = "--system aarch64-darwin";
      position = "anywhere";
    };
    sysarml = {
      expansion = "--system aarch64-linux";
      position = "anywhere";
    };
  };

  programs.fish.interactiveShellInit = ''
    set -g fish_greeting ""

    # Activate color-theme-aware theme (auto-switches on terminal background change)
    fish_config theme choose ok-solar

    # Activate event handlers
    functions notify-done > /dev/null
  '';
}

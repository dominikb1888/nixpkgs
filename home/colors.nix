# Color scheme definitions -------------------------------------------------------------------------
#
# Each scheme is a pair (dark + light) defined by shared monotones, accents, and extras.
# The module auto-generates both polarities with correct ANSI mapping and bright variants.
#
# Colors are defined in OkLCH (Lightness, Chroma, Hue°) for readability -- the lightness
# progression and chroma relationships are immediately visible. The `oklch` helper converts
# to hex at evaluation time via nix-colorizer.
#
# Monotone order: darkest (index 0) to lightest (index 7).
# Indices 1 and 6 become "surface2" (in opposite polarities) -- no ANSI slot.

{ pkgs, ... }:

let
  inherit (pkgs) nix-colorizer;
  pi = 3.14159265358979;
  oklch =
    L: C: h:
    nix-colorizer.oklch.to.hex {
      inherit L C;
      h = h * pi / 180.0; # nix-colorizer expects radians; convert from degrees
      a = 1.0;
    };
in

{
  # Based on OK Solar (https://meat.io/oksolar) by Zack Voase, itself a perceptually uniform
  # redesign of Solarized (https://ethanschoonover.com/solarized) using OkLCH.
  #
  # All accents share L=0.631; monotone hues cluster at 219.6° (dark) and 198°/90° (light).
  # See the OK Solar article for design rationale and OkLCH values (https://meat.io/oksolar.json).
  #
  # Tweak from OK Solar: base2 chroma lowered from 0.031 to 0.012 to match base3, giving a
  # more neutral light-mode surface color.
  colors.malo-ok-solar = {
    #                    L      C      h°
    monotones = [
      (oklch 0.274 0.050 219.6) # base03
      (oklch 0.321 0.053 219.6) # base02
      (oklch 0.535 0.029 219.6) # base01
      (oklch 0.544 0.017 219.6) # base00
      (oklch 0.718 0.017 198.0) # base0
      (oklch 0.718 0.030 198.0) # base1
      (oklch 0.934 0.012 90.0) # base2 (chroma 0.012 to match base3)
      (oklch 0.977 0.012 90.0) # base3
    ];
    accents = {
      red = oklch 0.631 0.221 21.6;
      green = oklch 0.631 0.148 118.8;
      yellow = oklch 0.631 0.129 86.4;
      blue = oklch 0.631 0.141 244.8;
      magenta = oklch 0.631 0.205 349.2;
      cyan = oklch 0.631 0.102 187.2;
    };
    extras = {
      orange = oklch 0.631 0.166 50.4;
      violet = oklch 0.631 0.121 280.8;
    };

    dark.terminal.selectionBg = "#103956";
    light.terminal.selectionBg = "#A9D2EF";

    # Kitty tab/URL colors (nullable -- null means use kitty's built-in default)
    pkgThemes.kitty = {
      url_color = "blue";
      tab_bar_background = "surface";
      active_tab_background = "green";
      active_tab_foreground = "bright";
      inactive_tab_background = "muted";
      inactive_tab_foreground = "bright";
    };

    # Fish theme overrides (scheme-specific accents where Solarized convention differs)
    pkgThemes.fish = {
      redirection = "violet";
    };

    dark.pkgThemes.fish.selection_bg = "#103956";
    light.pkgThemes.fish.selection_bg = "#A9D2EF";
  };
}

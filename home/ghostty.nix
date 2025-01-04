{ config, lib, ... }:

let
  inherit (lib.generators) toKeyValue mkKeyValueDefault;

  mkThemeConfig = toKeyValue {
    mkKeyValue = mkKeyValueDefault { } " = ";
    listsAsDuplicateKeys = true;
  };
in

{
  xdg.configFile."ghostty/themes/light".text =
    mkThemeConfig config.colors.malo-ok-solar-light.pkgThemes.ghostty;


xdg.configFile."ghostty/themes/dark".text =
    mkThemeConfig config.colors.malo-ok-solar-dark.pkgThemes.ghostty;


  xdg.configFile."ghostty/config".text = toKeyValue { mkKeyValue = mkKeyValueDefault { } " = "; } {
    font-family = "PragmataPro Liga";
    font-size = 16;
    font-thicken = true;

    adjust-cell-height = "20%";
    adjust-cursor-height = "20%";
    adjust-cursor-thickness = "100%";
    adjust-box-thickness = "100%";
    adjust-underline-thickness = "100%";

    macos-titlebar-style = "hidden";

    theme = "light:light,dark:dark";
    window-theme = "system";
    window-colorspace = "display-p3";
    window-padding-x = 16;
    window-padding-y = 10;

    auto-update = "download";
  };
}

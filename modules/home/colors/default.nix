{ lib, pkgs, ... }:

let
  inherit (lib) mkOption types;

  yazi-flavors-src = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "4c5753789ea535540e868e2764127be9230cef23";
    hash = "sha256-tCAJXPV7s1akc+zHGdWjmdMPG4NpBE92vcO7LAvI5TI=";
  };

  inherit (pkgs) nix-colorizer;
in
{
  options = {
    colors = mkOption {
      default = { };
      type = types.attrsOf (
        types.submoduleWith {
          modules = [ ./colorscheme.nix ];
          specialArgs = { inherit pkgs yazi-flavors-src nix-colorizer; };
        }
      );
      description = ''
        Color scheme definitions. Each scheme is a pair (dark + light) defined by
        shared monotones, accents, and extras. The module auto-generates both polarities
        with standard ANSI mapping and OkLCH-derived bright accent variants.
      '';
    };
  };
}

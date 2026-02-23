{
  name,
  config,
  lib,
  pkgs,
  nix-colorizer,
  yazi-flavors-src,
  ...
}:

let
  inherit (builtins)
    attrNames
    elemAt
    listToAttrs
    ;

  inherit (lib)
    generators
    hasPrefix
    literalExpression
    mapAttrsToList
    mkDefault
    mkOption
    range
    types
    ;

  hexColorType = types.strMatching "#[0-9a-fA-F]{6}";

  inherit (nix-colorizer) hex;

  # Generate option attrs from a token definition set (used for scheme-level fish/yazi).
  mkTokenOptions =
    defs:
    lib.mapAttrs (
      _: def:
      mkOption {
        type = types.str;
        inherit (def) default description;
      }
    ) defs;

  # Per-polarity resolved submodule ----------------------------------------------------------------

  # Resolve a named color reference (e.g. "blue", "surface") to its hex value
  # by looking up namedColors first, then ANSI slots, falling through to the
  # raw value (assumed hex) if neither matches.
  resolveRef = polCfg: v: polCfg.namedColors.${v} or polCfg.colors.${v} or v;

  # A color option that resolves named references (e.g. "blue") against the
  # polarity's colors + namedColors attrsets. Set `nullable = true` to allow
  # null values (meaning "use the application's built-in default").
  mkColorOption =
    polCfg:
    {
      nullable ? false,
      ...
    }@args:
    let
      cleanArgs = removeAttrs args [ "nullable" ];
      colorRefType = types.either hexColorType (
        types.enum (attrNames polCfg.colors ++ attrNames polCfg.namedColors)
      );
    in
    mkOption (
      cleanArgs
      // {
        type = if nullable then types.nullOr colorRefType else colorRefType;
        apply = v: if v == null then null else resolveRef polCfg v;
      }
    );

  # Shared terminal chrome fields ------------------------------------------------------------------

  # Canonical definitions for terminal chrome colors. Used to generate options
  # for `terminal`, `pkgThemes.kitty`, and `pkgThemes.ghostty` without
  # repeating descriptions or default/defaultText boilerplate.
  terminalChromeFields = [
    {
      field = "bg";
      description = "Background color.";
    }
    {
      field = "fg";
      description = "Foreground (text) color.";
    }
    {
      field = "cursorBg";
      description = "Cursor color.";
    }
    {
      field = "cursorFg";
      description = "Text color under cursor.";
    }
    {
      field = "selectionBg";
      description = "Selection background color.";
    }
    {
      field = "selectionFg";
      description = "Selection text color.";
    }
  ];

  # Generate terminal options (canonical names, no defaults from terminal).
  mkTerminalChromeOptions =
    polCfg:
    listToAttrs (
      map (
        { field, description }:
        {
          name = field;
          value = mkColorOption polCfg { inherit description; };
        }
      ) terminalChromeFields
    );

  # Generate pkg theme chrome options (custom names, defaulting to terminal.*).
  mkPkgChromeOptions =
    polCfg: fieldNames:
    listToAttrs (
      map (
        { field, description }:
        {
          name = fieldNames.${field};
          value = mkColorOption polCfg {
            default = polCfg.terminal.${field};
            defaultText = literalExpression "config.terminal.${field}";
            inherit description;
          };
        }
      ) terminalChromeFields
    );

  # ANSI slot helpers ------------------------------------------------------------------------------

  ansiSlotNames = [
    "black"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "white"
    "brblack"
    "brred"
    "brgreen"
    "bryellow"
    "brblue"
    "brmagenta"
    "brcyan"
    "brwhite"
  ];

  mkAnsiSlotOptions =
    polCfg: namePrefix:
    listToAttrs (
      map (i: {
        name = "${namePrefix}${toString i}";
        value = mkColorOption polCfg {
          default = "color${toString i}";
          description = "ANSI slot ${toString i} (${elemAt ansiSlotNames i}).";
        };
      }) (range 0 15)
    );

  # Token metadata for typed scheme-level options --------------------------------------------------

  # Each key maps to { default, description } used to generate both scheme-level
  # options (with defaults) and polarity-level options (descriptions only, values
  # inherited from scheme via mkDefault).

  fishTokenDefs = {
    # Monotone text hierarchy: command(bold) > param > option > comment
    command = {
      default = "blue --bold";
      description = "Command name color.";
    };
    param = {
      default = "fg";
      description = "Command parameter color.";
    };
    option = {
      default = "subtle";
      description = "Command option color.";
    };
    keyword = {
      default = "magenta";
      description = "Keyword color.";
    };
    quote = {
      default = "green";
      description = "Quoted string color.";
    };
    comment = {
      default = "muted";
      description = "Comment color.";
    };
    autosuggestion = {
      default = "muted";
      description = "Autosuggestion color.";
    };
    normal = {
      default = "normal";
      description = "Normal text color.";
    };
    # Accents
    redirection = {
      default = "yellow";
      description = "Redirection operator color.";
    };
    end = {
      default = "cyan";
      description = "Statement terminator color.";
    };
    error = {
      default = "red";
      description = "Error color.";
    };
    operator = {
      default = "cyan";
      description = "Operator color.";
    };
    escape = {
      default = "cyan";
      description = "Escape sequence color.";
    };
    cancel = {
      default = "red --reverse";
      description = "Cancel action color.";
    };
    # Selection (pure color refs -- template adds --background=)
    selection_bg = {
      default = "surface";
      description = "Selection background color.";
    };
    # Pager
    pager_prefix = {
      default = "fg --bold --underline";
      description = "Pager prefix color.";
    };
    pager_completion = {
      default = "fg";
      description = "Pager completion color.";
    };
    pager_description = {
      default = "yellow --italics";
      description = "Pager description color.";
    };
    pager_progress = {
      default = "bright";
      description = "Pager progress indicator color.";
    };
    # Prompt / UI
    cwd = {
      default = "green";
      description = "Current working directory color.";
    };
    cwd_root = {
      default = "red";
      description = "Root user CWD color.";
    };
    user = {
      default = "green";
      description = "Username color.";
    };
    host = {
      default = "fg";
      description = "Hostname color.";
    };
    host_remote = {
      default = "yellow";
      description = "Remote hostname color.";
    };
    status = {
      default = "red";
      description = "Exit status color.";
    };
    valid_path = {
      default = "--underline";
      description = "Valid path indicator.";
    };
    history_current = {
      default = "--bold";
      description = "Current history item style.";
    };
    preferred_background = {
      default = "bg";
      description = "Preferred background reference.";
    };
  };

  yaziTokenDefs = {
    text = {
      default = "fg";
      description = "Primary text color.";
    };
    background = {
      default = "bg";
      description = "Main background color.";
    };
    primary = {
      default = "blue";
      description = "Primary UI accent (focused items, links).";
    };
    secondary = {
      default = "cyan";
      description = "Secondary UI accent.";
    };
    tertiary = {
      default = "orange";
      description = "Tertiary UI accent.";
    };
    accent = {
      default = "magenta";
      description = "Highlight accent (selected items).";
    };
    surface = {
      default = "surface";
      description = "Surface background (panels, cards).";
    };
    surface1 = {
      default = "muted";
      description = "Elevated surface background.";
    };
    surface2 = {
      default = "subtle";
      description = "Highest-elevation surface background.";
    };
    onSurface = {
      default = "emphasis";
      description = "Text on surface backgrounds.";
    };
    onSurface1 = {
      default = "emphasis";
      description = "Text on elevated surfaces.";
    };
    onSurface2 = {
      default = "muted";
      description = "Muted text on surfaces.";
    };
    red = {
      default = "red";
      description = "Semantic red (errors, deletions).";
    };
    green = {
      default = "green";
      description = "Semantic green (success, additions).";
    };
    blue = {
      default = "blue";
      description = "Semantic blue (info, links).";
    };
    yellow = {
      default = "yellow";
      description = "Semantic yellow (warnings).";
    };
  };

  # The submodule type for a single resolved polarity (dark or light).
  # `schemeConfig` is the top-level scheme config (monotones, accents, etc.)
  # passed via specialArgs. `config` (polCfg) is this polarity's own config.
  mkPolarityModule =
    polarity:
    { config, schemeConfig, ... }:
    let
      polCfg = config;
      m = schemeConfig;
      mono = m.monotones;

      isDark = polarity == "dark";

      # Semantic monotone mapping: light mode is just the reversed scale
      ordered = if isDark then mono else lib.reverseList mono;
      bg = elemAt ordered 0;
      surface = elemAt ordered 1;
      muted = elemAt ordered 2;
      subtle = elemAt ordered 3;
      fg = elemAt ordered 4;
      emphasis = elemAt ordered 5;
      surface2 = elemAt ordered 6; # available as named color, no ANSI slot
      bright = elemAt ordered 7;

      # Bright accent derivation
      brighten = c: if isDark then hex.lighten c m.brightDelta else hex.darken c m.brightDelta;

      inherit (m.accents)
        red
        green
        yellow
        blue
        magenta
        cyan
        ;
      inherit (m.extras) orange violet;

      brRed = brighten red;
      brGreen = brighten green;
      brYellow = brighten yellow;
      brBlue = brighten blue;
      brMagenta = brighten magenta;
      brCyan = brighten cyan;

    in
    {
      options = {
        colors = mkOption {
          type = types.submodule {
            options = listToAttrs (
              map (i: {
                name = "color${toString i}";
                value = mkOption { type = hexColorType; };
              }) (range 0 15)
            );
          };
          description = ''
            Standard ANSI color0-15 hex values. Defaults follow the standard mapping:
            0=surface, 1-6=accents, 7=white (polarity-dependent), 8=brblack
            (polarity-dependent), 9-14=bright accents (OkLCH-derived), 15=bright.
          '';
        };

        namedColors = mkOption {
          type = types.attrsOf (types.either hexColorType (types.enum (attrNames polCfg.colors)));
          default = { };
          apply = builtins.mapAttrs (_: v: if hasPrefix "color" v then polCfg.colors.${v} else v);
          description = ''
            Semantic color names resolved to hex values. Values can be hex colors or
            references to ANSI slot names (e.g. "color4"). Defaults include monotone
            roles (bg, surface, muted, subtle, fg, emphasis, bright, surface2) and
            accent names (red, green, yellow, blue, magenta, cyan, orange, violet).
            These names can be used as values in {option}`terminal` and {option}`pkgThemes`
            options via {option}`mkColorOption`.
          '';
        };

        terminal = mkOption {
          type = types.submodule { options = mkTerminalChromeOptions polCfg; };
          description = ''
            Terminal chrome colors (background, foreground, cursor, selection). These
            serve as the canonical source that pkgThemes inherit from by default.
            Values can be hex colors or named color references.
          '';
        };

        pkgThemes.kitty = mkOption {
          type = types.submodule {
            options =
              mkAnsiSlotOptions polCfg "color"
              // mkPkgChromeOptions polCfg {
                bg = "background";
                fg = "foreground";
                cursorBg = "cursor";
                cursorFg = "cursor_text_color";
                selectionBg = "selection_background";
                selectionFg = "selection_foreground";
              }
              //
                lib.mapAttrs
                  (
                    _: desc:
                    mkColorOption polCfg {
                      nullable = true;
                      default = null;
                      description = "${desc} Null uses kitty's default.";
                    }
                  )
                  {
                    url_color = "Color for highlighted URLs.";
                    tab_bar_background = "Tab bar background color.";
                    active_tab_background = "Active tab background color.";
                    active_tab_foreground = "Active tab text color.";
                    inactive_tab_foreground = "Inactive tab text color.";
                    inactive_tab_background = "Inactive tab background color.";
                  };
          };
          description = ''
            Kitty terminal theme. ANSI color0-15 default to the polarity's resolved
            colors; chrome options (background, cursor, selection) inherit from
            {option}`terminal`. Tab and URL colors must be set explicitly.
          '';
        };

        pkgThemes.yazi = mkOption {
          type = types.submodule {
            options = {
              variant = mkOption {
                type = types.enum [
                  "dark"
                  "light"
                ];
                description = "Flavor variant, determines yazi's base styling.";
              };
            }
            // lib.mapAttrs (_: def: mkColorOption polCfg { inherit (def) default description; }) yaziTokenDefs;
          };
          description = ''
            Yazi file manager flavor tokens. These map to placeholders in the yazi
            flavors template (e.g. `''${text}`, `''${surface}`). Used to generate
            both `flavor.toml` and the accompanying `tmtheme.xml` for syntax
            highlighting in file previews.
          '';
        };

        yaziFlavor = mkOption {
          type = types.package;
          readOnly = true;
          description = "Built yazi flavor derivation (flavor.toml + tmtheme.xml).";
        };

        pkgThemes.ghostty = mkOption {
          default = { };
          type = types.submodule {
            options = {
              palette = mkOption {
                default = { };
                type = types.submodule { options = mkAnsiSlotOptions polCfg ""; };
                description = ''
                  ANSI palette colors keyed by slot number ("0"-"15"). Declared as a
                  submodule for type-safe color references, then transformed by `apply`
                  into a list of "N=hex" strings matching Ghostty's `palette` config format.
                '';
                apply = mapAttrsToList (generators.mkKeyValueDefault { } "=");
              };
            }
            // mkPkgChromeOptions polCfg {
              bg = "background";
              fg = "foreground";
              cursorBg = "cursor-color";
              cursorFg = "cursor-text";
              selectionBg = "selection-background";
              selectionFg = "selection-foreground";
            };
          };
          description = ''
            Ghostty terminal theme. Chrome options inherit from {option}`terminal`;
            palette colors default to the polarity's resolved ANSI color0-15.
          '';
        };

        pkgThemes.fish = mkOption {
          type = types.submodule {
            options = lib.mapAttrs (
              _: def:
              mkOption {
                type = types.str;
                inherit (def) description;
              }
            ) fishTokenDefs;
          };
          description = ''
            Per-polarity Fish shell theme tokens. Inherits from scheme-level
            `pkgThemes.fish` via `mkDefault`; override individual tokens here for
            polarity-specific adjustments (e.g. different selection background).
          '';
        };

        tmTheme = mkOption {
          type = types.lines;
          readOnly = true;
          description = ''
            TextMate theme XML for syntect-based tools (bat, yazi preview, etc.).
            Generated from the polarity's namedColors and ANSI color0-15.
          '';
        };

        fishThemeSection = mkOption {
          type = types.lines;
          readOnly = true;
          description = ''
            Rendered Fish theme section for this polarity. Resolves named color
            references to bare hex and formats as `fish_color_*` / `fish_pager_color_*`
            lines suitable for a `.theme` file `[light]` or `[dark]` section.
          '';
        };
      };

      config = {
        # ANSI color0-15 with standard semantics
        colors = {
          color0 = surface; # black
          color1 = red;
          color2 = green;
          color3 = yellow;
          color4 = blue;
          color5 = magenta;
          color6 = cyan;
          # Swap so color7 stays lighter than color8 in both polarities
          color7 = if isDark then emphasis else muted; # white
          color8 = if isDark then muted else emphasis; # brblack
          color9 = brRed;
          color10 = brGreen;
          color11 = brYellow;
          color12 = brBlue;
          color13 = brMagenta;
          color14 = brCyan;
          color15 = bright; # brwhite
        };

        namedColors = {
          inherit
            bg
            surface
            muted
            subtle
            fg
            emphasis
            bright
            surface2
            ;
          inherit
            red
            green
            yellow
            blue
            magenta
            cyan
            ;
          inherit orange violet;
        };

        # TODO: Consider deriving selection/highlight colors from accents
        # (e.g., blue-tinted selection, orange search highlight, etc.)
        terminal = lib.mapAttrs (_: mkDefault) {
          inherit bg fg;
          cursorBg = blue;
          cursorFg = bg;
          selectionBg = surface;
          selectionFg = fg;
        };

        # ANSI slots and chrome inherit mechanically from the polarity's colors and
        # terminal settings. App-specific aesthetics (tab colors, yazi tokens) inherit
        # from scheme-level pkgThemes via mkDefault, with variant auto-set per polarity.
        pkgThemes.kitty = lib.mapAttrs (_: mkDefault) m.pkgThemes.kitty;
        pkgThemes.yazi = (lib.mapAttrs (_: mkDefault) m.pkgThemes.yazi) // {
          variant = polarity;
        };
        pkgThemes.fish = lib.mapAttrs (_: mkDefault) m.pkgThemes.fish;

        tmTheme = (import ./tmtheme.nix) {
          themeName = "${name} (${polarity})";
          colors = polCfg.namedColors;
        };

        yaziFlavor =
          let
            tokens = polCfg.pkgThemes.yazi;

            tokenNames = attrNames tokens;

            flavorToml = builtins.replaceStrings (map (n: "\${${n}}") tokenNames) (map (
              n: tokens.${n}
            ) tokenNames) (builtins.readFile "${yazi-flavors-src}/scripts/template.toml");

            flavorFile = pkgs.writeText "${name}-${polarity}-flavor.toml" flavorToml;
            tmThemeFile = pkgs.writeText "${name}-${polarity}-tmtheme.xml" polCfg.tmTheme;
          in
          pkgs.runCommand "yazi-${name}-${polarity}-flavor" { } ''
            mkdir -p $out
            cp ${flavorFile} $out/flavor.toml
            cp ${tmThemeFile} $out/tmtheme.xml
          '';

        fishThemeSection =
          let
            inherit (builtins) substring;
            inherit (lib) concatStringsSep splitString optionalString;
            f = polCfg.pkgThemes.fish;
            # Resolve a named color ref to bare hex (no #)
            resolveColor =
              name:
              let
                raw = resolveRef polCfg name;
              in
              if hasPrefix "#" raw then substring 1 6 raw else raw;

            # Parse "<color-ref> [--flags...]" -> full Fish color spec
            resolveToken =
              v:
              let
                words = splitString " " v;
                first = builtins.head words;
                rest = builtins.tail words;
                flags = concatStringsSep " " rest;
              in
              if first == "normal" then
                "normal"
              else if hasPrefix "--" first then
                v
              else if hasPrefix "#" first then
                "${substring 1 6 first}${optionalString (rest != [ ]) " ${flags}"}"
              else
                "${resolveColor first}${optionalString (rest != [ ]) " ${flags}"}";

            # Resolve a color ref for --background= usage
            bgRef = name: if hasPrefix "#" name then substring 1 6 name else resolveColor name;

            t = resolveToken;
          in
          concatStringsSep "\n" [
            "# preferred_background: ${bgRef f.preferred_background}"
            "fish_color_normal ${t f.normal}"
            "fish_color_command ${t f.command}"
            "fish_color_param ${t f.param}"
            "fish_color_option ${t f.option}"
            "fish_color_keyword ${t f.keyword}"
            "fish_color_quote ${t f.quote}"
            "fish_color_redirection ${t f.redirection}"
            "fish_color_end ${t f.end}"
            "fish_color_error ${t f.error}"
            "fish_color_comment ${t f.comment}"
            "fish_color_selection --background=${bgRef f.selection_bg}"
            "fish_color_search_match --background=${bgRef f.selection_bg} --bold"
            "fish_color_operator ${t f.operator}"
            "fish_color_escape ${t f.escape}"
            "fish_color_autosuggestion ${t f.autosuggestion}"
            "fish_color_cancel ${t f.cancel}"
            "fish_color_cwd ${t f.cwd}"
            "fish_color_cwd_root ${t f.cwd_root}"
            "fish_color_user ${t f.user}"
            "fish_color_host ${t f.host}"
            "fish_color_host_remote ${t f.host_remote}"
            "fish_color_status ${t f.status}"
            "fish_color_valid_path ${t f.valid_path}"
            "fish_color_history_current ${t f.history_current}"
            "fish_pager_color_prefix ${t f.pager_prefix}"
            "fish_pager_color_completion ${t f.pager_completion}"
            "fish_pager_color_description ${t f.pager_description}"
            "fish_pager_color_progress ${t f.pager_progress} --background=${bgRef f.end}"
            "fish_pager_color_selected_background --background=${bgRef f.selection_bg}"
          ];
      };
    };
in

{
  options = {
    name = mkOption {
      type = types.str;
      default = name;
      description = "Display name for this color scheme, used in tmTheme metadata.";
    };

    monotones = mkOption {
      type = types.addCheck (types.listOf hexColorType) (l: builtins.length l == 8);
      description = ''
        8 monotone hex colors ordered darkest to lightest. Indices map to semantic
        roles per polarity:

        | Index | Dark role | Light role |
        |-------|-----------|------------|
        | 0     | bg        | bright     |
        | 1     | surface   | surface2   |
        | 2     | muted     | emphasis   |
        | 3     | subtle    | fg         |
        | 4     | fg        | subtle     |
        | 5     | emphasis  | muted      |
        | 6     | surface2  | surface    |
        | 7     | bright    | bg         |

        Indices 1 and 6 ("surface2") have no ANSI slot but are available as named colors.
      '';
    };

    accents = mkOption {
      type = types.submodule {
        options = lib.genAttrs [ "red" "green" "yellow" "blue" "magenta" "cyan" ] (
          _: mkOption { type = hexColorType; }
        );
      };
      description = ''
        Six accent colors mapped to ANSI slots 1-6 (red, green, yellow, blue, magenta,
        cyan). Bright variants (ANSI 9-14) are derived automatically via OkLCH lightness
        adjustment controlled by {option}`brightDelta`.
      '';
    };

    extras = mkOption {
      type = types.submodule {
        options = lib.genAttrs [ "orange" "violet" ] (_: mkOption { type = hexColorType; });
      };
      description = ''
        Extra accent colors (orange, violet) available as named colors but not assigned
        to ANSI slots. Useful for UI elements like import keywords, constants, etc.
      '';
    };

    brightDelta = mkOption {
      type = types.float;
      default = 0.22;
      description = ''
        OkLCH lightness delta for deriving bright accent variants (ANSI slots 9-14).
        In dark mode, accents are lightened by this amount; in light mode, darkened.
        Higher values produce more contrast between normal and bright accents.
      '';
    };

    pkgThemes.kitty = mkOption {
      type = types.submodule {
        options =
          lib.genAttrs
            [
              "url_color"
              "tab_bar_background"
              "active_tab_background"
              "active_tab_foreground"
              "inactive_tab_foreground"
              "inactive_tab_background"
            ]
            (
              _:
              mkOption {
                type = types.nullOr types.str;
                default = null;
              }
            );
      };
      default = { };
      description = ''
        Scheme-level kitty app-specific colors (tab bar, URL color, etc.) shared by
        both polarities. Values are color name references (e.g. "blue", "surface")
        resolved per-polarity, or null to use kitty's built-in default. These flow
        into {option}`dark.pkgThemes.kitty` and {option}`light.pkgThemes.kitty` via
        `mkDefault` and can be overridden per-polarity when needed.
      '';
    };

    pkgThemes.yazi = mkOption {
      type = types.submodule {
        options = mkTokenOptions yaziTokenDefs;
      };
      default = { };
      description = ''
        Scheme-level yazi flavor tokens shared by both polarities. Values are color
        name references (e.g. "fg", "blue", "surface") resolved per-polarity. These
        flow into {option}`dark.pkgThemes.yazi` and {option}`light.pkgThemes.yazi`
        via `mkDefault`. The `variant` field is auto-set per polarity ("dark"/"light")
        at normal priority, overriding the `mkDefault` from here.
      '';
    };

    pkgThemes.fish = mkOption {
      type = types.submodule {
        options = mkTokenOptions fishTokenDefs;
      };
      default = { };
      description = ''
        Scheme-level Fish shell theme tokens shared by both polarities. Token values
        are full Fish color specs: `"<color-ref> [--flags]"`. The first word is a
        named color reference resolved to bare hex per polarity; the rest are Fish
        modifiers passed through. Style-only values like `"--underline"` and `"normal"`
        pass through as-is. Base16-derived defaults are provided on each option;
        schemes override only the ~5 accent assignments that differ. These flow into
        per-polarity `pkgThemes.fish` via `mkDefault` and are rendered into `.theme`
        file sections by `fishThemeSection`.
      '';
    };

    dark = mkOption {
      type = types.submoduleWith {
        modules = [ (mkPolarityModule "dark") ];
        specialArgs = {
          schemeConfig = config;
        };
      };
      default = { };
      description = ''
        Resolved dark polarity. Auto-generated from the scheme's monotones and accents
        with bg=darkest, fg=mid-light, emphasis=light, bright=lightest. All sub-options
        (colors, namedColors, terminal, pkgThemes) have computed defaults that can be
        overridden per-scheme.
      '';
    };

    light = mkOption {
      type = types.submoduleWith {
        modules = [ (mkPolarityModule "light") ];
        specialArgs = {
          schemeConfig = config;
        };
      };
      default = { };
      description = ''
        Resolved light polarity. Auto-generated from the scheme's monotones and accents
        with bg=lightest, fg=mid-dark, emphasis=dark, bright=darkest. All sub-options
        (colors, namedColors, terminal, pkgThemes) have computed defaults that can be
        overridden per-scheme.
      '';
    };
  };
}

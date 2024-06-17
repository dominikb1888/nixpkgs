{ config, lib, pkgs, ... }:
# Let-In --------------------------------------------------------------------------------------- {{{
let
  backgroundDependantColors = colors: with colors; {
    background = "#${base}";
    foreground = "#${main}";

    # Cursor
    cursor = "#${blue}";
    cursor_text_color = "#${base}";

    # Selection
    selection_background = "#${muted}";
    selection_foreground = "#${base}";

    # Tab bar
    tab_bar_background = "#${basehl}";
    inactive_tab_background = "#${strong}";
  };
in
# }}}
{
  # Kitty terminal
  # https://sw.kovidgoyal.net/kitty/conf.html
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.kitty.enable
  programs.kitty.enable = true;
    # General config ----------------------------------------------------------------------------- {{{

  programs.kitty.settings = {
    # https://fsd.it/shop/fonts/pragmatapro/
    # font_family = "Rec Mono Semicasual";
    font_family = "Pragmata Pro Mono";
    font_size = "18.0";
    adjust_line_height = "140%";
    disable_ligatures = "cursor"; # disable ligatures when cursor is on them

    # Window layout
    hide_window_decorations = "titlebar-only";
    window_padding_width = "30";

    # Tab bar
    tab_bar_edge = "top";
    tab_bar_style = "powerline";
    tab_title_template = "Tab {index}: {title}";
    active_tab_font_style = "bold";
    inactive_tab_font_style = "normal";
    tab_activity_symbol = "";
  };

  programs.kitty.extras.useSymbolsFromNerdFont = "JetBrainsMono Nerd Font";
  # }}}

  # Colors config ------------------------------------------------------------------------------ {{{
  programs.kitty.extras.colors =  {
    enable = true;

    # Background dependent colors
    # Background dependent colors
    dark = config.colors.solarized-dark.pkgThemes.kitty;
    light = config.colors.solarized-light.pkgThemes.kitty;
  };

  programs.fish.functions.set-term-colors = {
    body = "term-background $term_background";
    onVariable = "term_background";
  };
  programs.fish.interactiveShellInit = ''
    # Set term colors based on value of `$term_backdround` when shell starts up.
    set-term-colors
  '';
  # }}}
}
# vim: foldmethod=marker

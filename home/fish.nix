{ config, lib, pkgs, ... }:

let
  inherit (lib) elem optionalString;
  inherit (config.home.user-info) nixConfigDirectory;
in

{
  # Fish Shell
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.fish.enable
  programs.fish.enable = true;

  # Add Fish plugins
  home.packages = [ pkgs.fishPlugins.done ];

  #  Fish functions ----------------------------------------------------------------------------- {{{

  programs.fish.functions = {
    # Toggles `$term_background` between "light" and "dark". Other Fish functions trigger when this
    # variable changes. We use a universal variable so that all instances of Fish have the same
    # value for the variable.
    toggle-background.body = ''
      if test "$term_background" = light
        set -U term_background dark
      else
        set -U term_background light
    vpn = "echo "4pTH2WWb" | sudo openconnect --user=dboehler --authgroup=vpn-pers.th-deg.de  --servercert=pin-sha256:oRlBtC/kdoY5pS/VI1R88WGkUbDmbTWev33Sfxmfb5Q= vpn.th-deg.de --protocol=anyconnect --passwd-on-stdin --background"
      end
    '';

    # Set `$term_background` based on whether macOS is light or dark mode. Other Fish functions
    # trigger when this variable changes. We use a universal variable so that all instances of Fish
    # have the same value for the variable.
    set-background-to-macOS.body = ''
      # Returns 'Dark' if in dark mode fails otherwise.
      if defaults read -g AppleInterfaceStyle &>/dev/null
        set -U term_background dark
      else
        set -U term_background light
      end
    '';

    # Sets Fish Shell to light or dark colorscheme based on `$term_background`.
    set-shell-colors = {
      body = ''
        # Set LS_COLORS
        set -xg LS_COLORS (${pkgs.vivid}/bin/vivid generate solarized-$term_background)

        # Set color variables
        if test "$term_background" = light
          set emphasized_text  brgreen  # base01
          set normal_text      bryellow # base00
          set secondary_text   brcyan   # base1
          set background_light white    # base2
          set background       brwhite  # base3
        else
          set emphasized_text  brcyan   # base1
          set normal_text      brblue   # base0
          set secondary_text   brgreen  # base01
          set background_light black    # base02
          set background       brblack  # base03
        end

        # Set Fish colors that change when background changes
        set -g fish_color_command                    $emphasized_text --bold  # color of commands
        set -g fish_color_param                      $normal_text             # color of regular command parameters
        set -g fish_color_comment                    $secondary_text          # color of comments
        set -g fish_color_autosuggestion             $secondary_text          # color of autosuggestions
        set -g fish_pager_color_prefix               $emphasized_text --bold  # color of the pager prefix string
        set -g fish_pager_color_description          $selection_text          # color of the completion description
        set -g fish_pager_color_selected_prefix      $background
        set -g fish_pager_color_selected_completion  $background
        set -g fish_pager_color_selected_description $background
      '' + optionalString config.programs.bat.enable ''

        # Use correct theme for `bat`.
        set -xg BAT_THEME "Solarized ($term_background)"
      '' + optionalString (elem pkgs.bottom config.home.packages) ''

        # Use correct theme for `btm`.
        if test "$term_background" = light
          alias btm "btm --color default-light"
        else
          alias btm "btm --color default"
        end
      '' + optionalString config.programs.neovim.enable ''

      # Set `background` of all running Neovim instances.
      for server in (${pkgs.neovim-remote}/bin/nvr --serverlist)
        ${pkgs.neovim-remote}/bin/nvr -s --nostart --servername $server \
          -c "set background=$term_background" &
      end
      '';
      onVariable = "term_background";
    };

    vup.body = ''
      read -p 'echo "Password: "' -ls pass
      echo $pass | sudo openconnect --user=dboehler --authgroup=vpn-pers.th-deg.de  --servercert=pin-sha256:TzWa1imMUGJ66wR1JCrNsJMOAOR48jl1lSwZ+8BsUsk= vpn.th-deg.de --protocol=anyconnect --passwd-on-stdin --background
    '';

    vdn.body = ''
      sudo kill -2 `pgrep openconnect`
    '';

    __select_from_last.body = ''
      set -l FZF_OUT (eval $history[1] | fzf --height 15%)
      if test -n "$FZF_OUT"
        commandline -r $FZF_OUT
        commandline --cursor 0
      end
    '';

    displayRgPipedFzf.body = ''
      echo $(rg $argv . -n --glob '!.git/' --glob '!vendor/' --glob '!node_modules/' | fzf --exact -e -d ':' -n 2.. --ansi --no-sort --preview 'bat --style=numbers --color=always --highlight-line {2} {1};' --preview-window +{2}-5)
    '';

    nvimGoToLine.body = ''
      set nvimExists (which nvim)
      if [ -z "$nvimExists" ];
        return;
      end

      set selection (displayRgPipedFzf $argv)
      if [ -z "$selection" ];
        return;
      else
        set filename (echo $selection | cut -d: -f1)
        set line (echo $selection | cut -d: -f2)
        nvim $filename "+$line" "+normal zz^";
      end
    '';

    fdFzf.body = ''
	    set fdExists (which fd)
      if [ -z "$fdExists" ];
        return;
      else
        if [ "(pwd)" = "$HOME" ];
          set goTo (fd -t d -d 1 . | fzf --preview "bat --style=numbers --color=always --line-range :500 {}")
          if [ -z "$goTo" ];
            return;
          else
            cd $goTo
            return;
          end
        end

        set goTo (fd -t d . | grep -vE '(node_modules)' | fzf --preview "bat --style=numbers --color=always --line-range :500 {}")
        if [ -z "$goTo" ];
          return;
        else
          cd $goTo
        end
      end
    '';

    displayFZFFiles.body = ''
      fzf --preview 'bat --color=always --style=numbers --line-range :500 {}'
    '';

    nvimGoToFiles.body = ''
      set nvimExists (which nvim)
      if [ -z "$nvimExists" ];
        return;
      end

      set selection (displayFZFFiles $argv);
      if [ -z "$selection" ];
        return;
      else
          nvim $selection;
      end
    '';
  };
  # }}}

  # Fish configuration ------------------------------------------------------------------------- {{{

  # Aliases
  home.shellAliases = with pkgs; {
    # Nix related
    drb = "darwin-rebuild build --flake ${nixConfigDirectory}";
    drs = "sudo darwin-rebuild switch --flake ${nixConfigDirectory}";
    flakeup = "nix flake update --flake ${nixConfigDirectory}";
    nb = "nix build";
    nd = "nix develop";
    nf = "nix flake";
    nr = "nix run";
    ns = "nix search";

    # Other
    ".." = "cd ..";
    ":q" = "exit";
    cat = "${bat}/bin/bat";
    cl = "clear";
    du = "${du-dust}/bin/dust";
    g = "${gitAndTools.git}/bin/git";
    lg = "la --git-ignore"; # does not list files ignored by git
    la = "ll -a";
    ll = "ls -l --time-style=iso --icons --git --no-filesize --no-user --header";
    llt = "ll -T";
    ls = "${eza}/bin/eza -1 --group-directories-first";
    lt = "ls -T";
    tb = "toggle-background";
    v = "vim";
    vi = "vim";
    vim = "nvim";
    lvim = "$HOME/.local/bin/lvim";

    ngl = "nvimGoToLine";
    ngf = "nvimGoToFiles";
    fzd = "fdFzf";
    h = "__select_from_last";
  };

 programs.fish.shellAbbrs = {
    nix-rm-results = ''
      ${pkgs.fd}/bin/fd --hidden --no-ignore --type l '^result-?' --exclude 'Library/**' \
        --exec rm '{}'
    '';
  };
  # Configuration that should be above `loginShellInit` and `interactiveShellInit`.
  programs.fish.shellInit = ''
    set -U fish_term24bit 1
    ${optionalString pkgs.stdenv.isDarwin "set-background-to-macOS"}
  '';

  programs.fish.interactiveShellInit = ''
    set -g fish_greeting ""

    # Run function to set colors that are dependant on `$term_background` and to register them so
    # they are triggerd when the relevent event happens or variable changes.
    set-shell-colors

    # Set Fish colors that aren't dependant the `$term_background`.
    set -g fish_color_quote        cyan      # color of commands
    set -g fish_color_redirection  brmagenta # color of IO redirections
    set -g fish_color_end          blue      # color of process separators like ';' and '&'
    set -g fish_color_error        red       # color of potential errors
    set -g fish_color_match        --reverse # color of highlighted matching parenthesis
    set -g fish_color_search_match --background=yellow
    set -g fish_color_selection    --reverse # color of selected text (vi mode)
    set -g fish_color_operator     green     # color of parameter expansion operators like '*' and '~'
    set -g fish_color_escape       red       # color of character escapes like '\n' and and '\x70'
    set -g fish_color_cancel       red       # color of the '^C' indicator on a canceled command

    set -x FZF_DEFAULT_OPTS '--prompt="🔭 " --height 80% --no-separator --layout=reverse --margin=0,0 --border=none --padding=0,0'
    set -x FZF_DEFAULT_COMMAND 'rg --files --no-ignore --hidden --follow --glob "!.git/" --glob "!node_modules/" --glob "!vendor/" --glob "!undo/" --glob "!plugged/"'
    # set -x BAT_THEME 'gruvbox-dark'

    export EXA_ICON_SPACING=2
    direnv hook fish | source
  '';
  # }}}
}
# vim: foldmethod=marker

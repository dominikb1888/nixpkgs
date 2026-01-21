{ config, pkgs, lib, ... }:
# Let-In ----------------------------------------------------------------------------------------{{{
let
  inherit (lib)
    attrValues
    concatStringsSep
    mapAttrsToList
    optional
    removePrefix
    ;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  inherit (config.home.user-info) nixConfigDirectory;

  mkLuaTableFromList = x: "{" + lib.concatMapStringsSep "," (y: "'${y}'") x + "}";
  mkNeovimAutocmd = { event, pattern, callback ? "" }: ''
    vim.api.nvim_create_autocmd(${mkLuaTableFromList event}, {
      pattern = ${mkLuaTableFromList pattern},
      callback = ${callback},
    })'';
  requireConf = p: "require 'malo.${builtins.replaceStrings [ "." ] [ "-" ] p.pname}'";

  # Function to create `programs.neovim.plugins` entries inspired by `packer.nvim`.
  packer =
    { use
    # Manually specified plugin name.
    , pname ? use.pname or use.name
      # Plugins that this plugin depends on.
    , deps ? [ ]
      # Used to manually specify that the plugin shouldn't be loaded at start up.
    , opt ? false
      # Whether to load the plugin when using VS Code with `vscode-neovim`.
    , vscode ? false
      # Code to run before the plugin is loaded.
    , setup ? ""
      # Code to run after the plugin is loaded.
    , config ? ""
      # The following all imply lazy-loading and imply `opt = true`.
      # `FileType`s which load the plugin.
    , ft ? [ ]
      # Autocommand events which load the plugin.
    , event ? [ ]
    }:
    let
      loadFunctionName = "load_${builtins.replaceStrings [ "." "-" ] [ "_" "_" ] pname}";
      autoload = !opt && vscode && ft == [ ] && event == [ ];
      configFinal =
        concatStringsSep "\n" (
          optional (!autoload && !opt) "vim.cmd 'packadd ${pname}'"
          ++ optional (config != "") config
        );
    in
    {
      plugin = use.overrideAttrs (old: {
        inherit pname;
        dependencies = lib.unique (old.dependencies or [ ] ++ deps);
      });
      optional = !autoload;
      type = "lua";
      config = if (setup == "" && configFinal == "") then null else
      (
        concatStringsSep "\n"
          (
            [ "\n-- ${pname}" ]
            ++ optional (setup != "") setup

            # If the plugin isn't always loaded at startup
            ++ optional (!autoload) (concatStringsSep "\n" (
              [ "local ${loadFunctionName} = function()" ]
              ++ optional (!vscode) "if vim.g.vscode == nil then"
              ++ [ configFinal ]
              ++ optional (!vscode) "end"
              ++ [ "end" ]
              ++ optional (ft == [ ] && event == [ ]) "${loadFunctionName}()"
              ++ optional (ft != [ ]) (mkNeovimAutocmd {
                event = [ "FileType" ];
                pattern = ft;
                callback = loadFunctionName;
              })
              ++ optional (event != [ ]) (mkNeovimAutocmd {
                inherit event;
                pattern = [ "*" ];
                callback = loadFunctionName;
              })
            ))

            # If the plugin is always loaded at startup
            ++ optional (autoload && configFinal != "") configFinal
          )
      );
    };
    mkVimColorVariable = k: v: ''let g:theme_${k} = "${v}"'';
    colorSetToVimscript = colors: concatStringsSep "\n" (mapAttrsToList mkVimColorVariable colors);
  in
# }}}
{
  # Neovim
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.neovim.enable
  programs.neovim.enable = true;

  # Config and plugins ------------------------------------------------------------------------- {{{

  # Put neovim configuration located in this repository into place in a way that edits to the
  # configuration don't require rebuilding the `home-manager` environment to take effect.
  xdg.configFile."nvim/lua".source = mkOutOfStoreSymlink "${nixConfigDirectory}/configs/nvim/lua";
  xdg.configFile."nvim/colors".source =
    mkOutOfStoreSymlink "${nixConfigDirectory}/configs/nvim/colors";

  # Load the `init` module from the above configs
  programs.neovim.extraConfig = ''
    ${colorSetToVimscript config.colors.malo-ok-solar-light.colors}
    ${colorSetToVimscript config.colors.malo-ok-solar-light.namedColors}
    lua require('init')
    lua <<EOF
            require'nvim-treesitter.config'.setup {      highlight = { enable = true },
      incremental_selection = { enable = true },
      indent = { enable = true },
    }
    EOF
  '';

  # Add NodeJs since it's required by some plugins I use.
  programs.neovim.withNodeJs = true;
  # Add `penlight` Lua module package since I used in the above configs
  programs.neovim.extraLuaPackages = ps: [ ps.penlight ];

  # Add plugins using my `packer` function.
  programs.neovim.plugins = with pkgs.vimPlugins; (map packer [
    # Core dependencies
    { use = plenary-nvim; }
    { use = lspkind-nvim; deps = [ nvim-cmp ]; }
    { use = nvim-cmp; config = requireConf nvim-cmp; }
    { use = luasnip; }

    # Completions
    {
      use = cmp-async-path;
      deps = [ nvim-cmp ];
    }
    {
      use = cmp-buffer;
      deps = [ nvim-cmp ];
    }
    {
      use = cmp-nvim-lsp;
      deps = [ nvim-cmp ];
    }
    {
      use = cmp-nvim-lsp-signature-help;
      deps = [ nvim-cmp ];
    }
    {
      use = cmp_luasnip;
      deps = [ nvim-cmp luasnip ];
    }

    # Apperance, interface, UI, etc.
    {
      use = bufferline-nvim;
      deps = [ nvim-web-devicons scope-nvim ];
      config = requireConf bufferline-nvim;
    }
    { use = galaxyline-nvim; deps = [ nvim-web-devicons ]; config = requireConf galaxyline-nvim; }
    { use = gitsigns-nvim; config = requireConf gitsigns-nvim; }
    { use = goyo-vim; }
    { use = indent-blankline-nvim; config = requireConf indent-blankline-nvim; }
    { use = lush-nvim; vscode = true; }
    {
      use = telescope-nvim;
      config = requireConf telescope-nvim;
      deps = [
        nvim-web-devicons
        telescope-file-browser-nvim
        telescope-fzf-native-nvim
        telescope-symbols-nvim
        telescope-zoxide
      ];
    }
    # { use = octo-nvim;
    #   deps = [
    #     plenary-nvim
    #     telescope-nvim
    #     nvim-web-devicons
    #   ];
    #   config = requireConf octo-nvim;
    # }
    { use = toggleterm-nvim; config = requireConf toggleterm-nvim; }

    # Language servers, linters, etc.
    {
      use = lsp_lines-nvim;
      config = ''
        require'lsp_lines'.setup()
        vim.diagnostic.config({ virtual_lines = { only_current_line = true } })'';
    }
    { use = lspsaga-nvim; config = requireConf lspsaga-nvim; }
    { use = nvim-lspconfig; deps = [ neodev-nvim ]; config = requireConf nvim-lspconfig; }

    # Language support/utilities
    # { use = agda-vim; ft = [ "agda" ]; }
    # { use = vim-haskell-module-name; vscode = true; ft = [ "haskell" ]; }
    { use = vim-polyglot; config = requireConf vim-polyglot; }

    # Editor behavior
    { use = comment-nvim; config = "require'comment'.setup()"; }
    { use = editorconfig-vim; setup = "vim.g.EditorConfig_exclude_patterns = { 'fugitive://.*' }"; }
    #{ use = tabular; vscode = true; }
    { use = vim-surround; vscode = true; }
    { use = nvim-lastplace; config = "require'nvim-lastplace'.setup()"; }
    {
      use = vim-pencil;
      setup = "vim.g['pencil#wrapModeDefault'] = 'soft'";
      config = "vim.fn['pencil#init'](); vim.wo.spell = true";
      ft = [ "markdown" "text" ];
    }
    # Markdown
    { use = vim-markdown; ft = [ "markdown" "text" ]; }

    # Misc
    { use = direnv-vim; }
    { use = vim-eunuch; vscode = true; }
    { use = vim-fugitive; }
    { use = which-key-nvim; }
  ]) ++ [
    (nvim-treesitter.withPlugins (plugins: with plugins; [
      tree-sitter-nix
      tree-sitter-lua
      tree-sitter-python
      tree-sitter-bash
      tree-sitter-c
      tree-sitter-javascript
      tree-sitter-typescript
      tree-sitter-html
      tree-sitter-css
      tree-sitter-json
      tree-sitter-yaml
    ]))
  ];

  # From personal addon module `../modules/home/programs/neovim/extras.nix`
  programs.neovim.extras.termBufferAutoChangeDir = true;
  programs.neovim.extras.nvrAliases.enable = true;
  programs.neovim.extras.defaultEditor = true;

  # }}}

  # Required packages -------------------------------------------------------------------------- {{{

  programs.neovim.extraPackages = with pkgs; [
    neovim-remote

    # Language servers, linters, etc.
    # See `../configs/nvim/lua/malo/nvim-lspconfig.lua` and

    # C/C++/Objective-C
    ccls

    # Bash
    # commented until https://github.com/NixOS/nixpkgs/pull/319882 is merged
    # nodePackages.bash-language-server

    # Lus Snip Dependency for Lua Regex
    luajitPackages.jsregexp

    # Javascript/Typescript
    nodePackages.typescript-language-server

    # Markdown
    marksman

    # Nix
    nil
    nixpkgs-fmt

    # rnix-lsp

    # Python
    ruff
    pyright

    # Generic

    # Vim
    nodePackages.vim-language-server

    #Other
    # nodePackages.vscode-langservers-extracted
    # nodePackages.yaml-language-server
    lua-language-server
  ];
  # }}}
}
# vim: foldmethod=marker

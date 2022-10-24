local utils = require 'malo.utils'
local augroup = utils.augroup
local keymaps = utils.keymaps

-- Add some aliases for Neovim Lua API
local o = vim.o
local wo = vim.wo
local g = vim.g
local cmd = vim.cmd

-- TODO --------------------------------------------------------------------------------------------

-- - Flesh out custom colorscheme
--   - Revisit Pmenu highlights:
--   - Experiment with `Diff` highlights to look more like `delta`'s output.
--   - Set `g:terminal_color` values.
--   - Decide on whether I want to include a bunch of language specific highlights
--   - Figure out what to do with `tree-sitter` highlights.
--   - Stretch
--     - Add more highlights for plugins I use, and other popular plugins.
--     - Create monotone variant, where one base color is supplied, and all colors are generate
--       based on transformations of that colors.
-- - Make tweaks to custom status line
--   - Find a way to dynamically display current LSP status/progress/messages.
--   - See if there's an easy way to show show Git sections when in terminal buffer.
--   - Revamp conditions for when segments are displayed
--   - A bunch of other small tweaks.
-- - List searching with telescope.nvim.
--   - Improve workspace folder detection on my telescope.nvim extensions
-- - Other
--   - Figure out how to get Lua LSP to be aware Nvim plugins. Why aren't they on `package.path`?
--   - Play around with `tree-sitter`.
--   - Look into replacing floaterm-vim with vim-toggleterm.lua.


-- Basic Vim Config --------------------------------------------------------------------------------

o.scrolloff  = 10   -- start scrolling when cursor is within 5 lines of the ledge
o.linebreak  = true -- soft wraps on words not individual chars
o.mouse      = 'a'  -- enable mouse support in all modes
o.updatetime = 300
o.autochdir  = true
o.exrc       = true -- allow project specific config in .nvimrc or .exrc files

-- Search and replace
o.ignorecase = true      -- make searches with lower case characters case insensative
o.smartcase  = true      -- search is case sensitive only if it contains uppercase chars
o.inccommand = 'nosplit' -- show preview in buffer while doing find and replace

-- Tab key behavior
o.expandtab  = true      -- Convert tabs to spaces
o.tabstop    = 2         -- Width of tab character
o.shiftwidth = o.tabstop -- Width of auto-indents

-- Set where splits open
o.splitbelow = true -- open horizontal splits below instead of above which is the default
o.splitright = true -- open vertical splits to the right instead of the left with is the default

-- Some basic autocommands
if g.vscode == nil then
  augroup { name = 'MaloVimBasics', cmds = {
    {{ 'BufEnter', 'FocusGained', 'CursorHold', 'CursorHoldI' }, {
      pattern = '*',
      desc = 'Check if file has changed on disk, if it has and buffer has no changes, reload it.',
      command = 'checktime',
    }},
    { 'BufWritePre' , {
      pattern = '*',
      desc = 'Remove trailing whitespace before write.',
      command = [[%s/\s\+$//e]],
    }},
    { 'TextYankPost', {
      pattern = '*',
      desc = 'Highlight yanked text.',
      callback = function() vim.highlight.on_yank { higroup='Search', timeout=150 } end,
    }},
  }}
end


-- UI ----------------------------------------------------------------------------------------------

-- Set UI related options
o.termguicolors   = true
o.showmode        = false -- don't show -- INSERT -- etc.
wo.colorcolumn    = '100' -- show column boarder
wo.number         = true  -- display numberline
wo.relativenumber = true  -- relative line numbers
wo.signcolumn     = 'yes' -- always have signcolumn open to avoid thing shifting around all the time
o.fillchars       = 'stl: ,stlnc: ,vert:·,eob: ' -- No '~' on lines after end of file, other stuff

-- Set colorscheme
require'malo.theme'.extraLushSpecs = {
  'lush_theme.malo.bufferline-nvim',
  'lush_theme.malo.statusline',
  'lush_theme.malo.telescope-nvim',
}
cmd 'colorscheme malo'


-- Terminal ----------------------------------------------------------------------------------------

augroup { name = 'MaloNeovimTerm', cmds = {
  { 'TermOpen', {
    pattern = '*',
    desc = 'Set options for terminal buffers.',
    command = 'setlocal nonumber | setlocal norelativenumber | setlocal signcolumn=no',
  }},
}}

keymaps { modes = 't', opts = { silent = true }, maps = {
  -- Enter normal mode in terminal using `<ESC>` like everywhere else.
  { '<ESC>', [[<C-\><C-n>]] },
  -- Sometimes you want to send `<ESC>` to the terminal though.
  { ' <ESC>', '<ESC>' },
}}

-- WhichKey maps -----------------------------------------------------------------------------------

-- Define all `<Space>` prefixed keymaps with which-key.nvim
-- https://github.com/folke/which-key.nvim
cmd 'packadd which-key.nvim'
cmd 'packadd! gitsigns.nvim' -- needed for some mappings
local wk = require 'which-key'
wk.setup { plugins = { spelling = { enabled = true } } }

-- Spaced prefiexd in Normal mode
wk.register ({
  [' '] = { '<Cmd>exe v:count1 . "ToggleTerm"<CR>', 'Toggle floating terminal' },

  -- Tabs
  t = {
    name = '+Tabs',
    n = { '<Cmd>tabnew +term<CR>'  , 'New with terminal' },
    o = { '<Cmd>tabonly<CR>'       , 'Close all other'   },
    q = { '<Cmd>tabclose<CR>'      , 'Close'             },
    l = { '<Cmd>tabnext<CR>'       , 'Next'              },
    h = { '<Cmd>tabprevious<CR>'   , 'Previous'          },
  },

  -- Windows/splits
  ['-']  = { '<Cmd>new +term<CR>'           , 'New terminal below'               },
  ['_']  = { '<Cmd>botright new +term<CR>'  , 'New termimal below (full-width)'  },
  ['\\'] = { '<Cmd>vnew +term<CR>'          , 'New terminal right'               },
  ['|']  = { '<Cmd>botright vnew +term<CR>' , 'New termimal right (full-height)' },
  w = {
    name = '+Windows',
    -- Split creation
    s = { '<Cmd>split<CR>'  , 'Split below'     },
    v = { '<Cmd>vsplit<CR>' , 'Split right'     },
    q = { '<Cmd>q<CR>'      , 'Close'           },
    o = { '<Cmd>only<CR>'   , 'Close all other' },
    -- Navigation
    k = { '<Cmd>wincmd k<CR>' , 'Go up'           },
    j = { '<Cmd>wincmd j<CR>' , 'Go down'         },
    h = { '<Cmd>wincmd h<CR>' , 'Go left'         },
    l = { '<Cmd>wincmd l<CR>' , 'Go right'        },
    w = { '<Cmd>wincmd w<CR>' , 'Go down/right'   },
    W = { '<Cmd>wincmd W<CR>' , 'Go up/left'      },
    t = { '<Cmd>wincmd t<CR>' , 'Go top-left'     },
    b = { '<Cmd>wincmd b<CR>' , 'Go bottom-right' },
    p = { '<Cmd>wincmd p<CR>' , 'Go to previous'  },
    -- Movement
    K = { '<Cmd>wincmd k<CR>' , 'Move to top'              },
    J = { '<Cmd>wincmd J<CR>' , 'Move to bottom'           },
    H = { '<Cmd>wincmd H<CR>' , 'Move to left'             },
    L = { '<Cmd>wincmd L<CR>' , 'Move to right'            },
    T = { '<Cmd>wincmd T<CR>' , 'Move to new tab'          },
    r = { '<Cmd>wincmd r<CR>' , 'Rotate clockwise'         },
    R = { '<Cmd>wincmd R<CR>' , 'Rotate counter-clockwise' },
    z = { '<Cmd>packadd zoomwintab.vim | ZoomWinTabToggle<CR>', 'Toggle zoom' },
    -- Resize
    ['='] = { '<Cmd>wincmd =<CR>'            , 'All equal size'   },
    ['-'] = { '<Cmd>resize -5<CR>'           , 'Decrease height'  },
    ['+'] = { '<Cmd>resize +5<CR>'           , 'Increase height'  },
    ['<'] = { '<Cmd><C-w>5<<CR>'             , 'Decrease width'   },
    ['>'] = { '<Cmd><C-w>5><CR>'             , 'Increase width'   },
    ['|'] = { '<Cmd>vertical resize 106<CR>' , 'Full line-lenght' },
  },

  -- Git
  g = {
    name = '+Git',
    -- vim-fugitive
    b = { '<Cmd>Gblame<CR>' , 'Blame'  },
    s = { '<Cmd>Git<CR>'    , 'Status' },
    d = {
      name = '+Diff',
      s = { '<Cmd>Ghdiffsplit<CR>' , 'Split horizontal' },
      v = { '<Cmd>Gvdiffsplit<CR>' , 'Split vertical'   },
    },
    -- gitsigns.nvim
    h = {
      name = '+Hunks',
      s = { require'gitsigns'.stage_hunk      , 'Stage'      },
      u = { require'gitsigns'.undo_stage_hunk , 'Undo stage' },
      r = { require'gitsigns'.reset_hunk      , 'Reset'      },
      n = { require'gitsigns'.next_hunk       , 'Go to next' },
      N = { require'gitsigns'.prev_hunk       , 'Go to prev' },
      p = { require'gitsigns'.preview_hunk    , 'Preview'    },
    },
    -- telescope.nvim lists
    l = {
      name = '+Lists',
      s = { '<Cmd>Telescope git_status<CR>'  , 'Status'         },
      c = { '<Cmd>Telescope git_commits<CR>' , 'Commits'        },
      C = { '<Cmd>Telescope git_commits<CR>' , 'Buffer commits' },
      b = { '<Cmd>Telescope git_branches<CR>' , 'Branches'       },
    },
    -- Other
    v = { '<Cmd>!gh repo view --web<CR>' , 'View on GitHub' },
  },

  -- Language server
  l = {
    name = '+LSP',
    h = { '<Cmd>Lspsaga hover_doc<CR>'            , 'Hover'                   },
    d = { vim.lsp.buf.definition                  , 'Jump to definition'      },
    D = { vim.lsp.buf.declaration                 , 'Jump to declaration'     },
    a = { '<Cmd>Lspsaga code_action<CR>'          , 'Code action'             },
    f = { vim.lsp.buf.formatting                  , 'Format'                  },
    r = { '<Cmd>Lspsaga rename<CR>'               , 'Rename'                  },
    t = { vim.lsp.buf.type_definition             , 'Jump to type definition' },
    n = { '<Cmd>Lspsaga diagnostic_jump_next<CR>' , 'Jump to next diagnostic' },
    N = { '<Cmd>Lspsaga diagnostic_jump_prev<CR>' , 'Jump to prev diagnostic' },
    l = {
      name = '+Lists',
      a = { '<Cmd>Telescope lsp_code_actions<CR>'       , 'Code actions'         },
      A = { '<Cmd>Telescope lsp_range_code_actions<CR>' , 'Code actions (range)' },
      r = { '<Cmd>Telescope lsp_references<CR>'         , 'References'           },
      s = { '<Cmd>Telescope lsp_document_symbols<CR>'   , 'Documents symbols'    },
      S = { '<Cmd>Telescope lsp_workspace_symbols<CR>'  , 'Workspace symbols'    },
    },
  },

  -- Seaching with telescope.nvim
  s = {
    name = '+Search',
    b = { '<Cmd>Telescope file_browser<CR>'              , 'File Browser'           },
    f = { '<Cmd>Telescope find_files_workspace<CR>'      , 'Files in workspace'     },
    F = { '<Cmd>Telescope find_files<CR>'                , 'Files in cwd'           },
    g = { '<Cmd>Telescope live_grep_workspace<CR>'       , 'Grep in workspace'      },
    G = { '<Cmd>Telescope live_grep<CR>'                 , 'Grep in cwd'            },
    l = { '<Cmd>Telescope current_buffer_fuzzy_find<CR>' , 'Buffer lines'           },
    o = { '<Cmd>Telescope oldfiles<CR>'                  , 'Old files'              },
    t = { '<Cmd>Telescope builtin<CR>'                   , 'Telescope lists'        },
    w = { '<Cmd>Telescope grep_string_workspace<CR>'     , 'Grep word in workspace' },
    W = { '<Cmd>Telescope grep_string<CR>'               , 'Grep word in cwd'       },
    v = {
      name = '+Vim',
      a = { '<Cmd>Telescope autocommands<CR>'    , 'Autocommands'    },
      b = { '<Cmd>Telescope buffers<CR>'         , 'Buffers'         },
      c = { '<Cmd>Telescope commands<CR>'        , 'Commands'        },
      C = { '<Cmd>Telescope command_history<CR>' , 'Command history' },
      h = { '<Cmd>Telescope highlights<CR>'      , 'Highlights'      },
      q = { '<Cmd>Telescope quickfix<CR>'        , 'Quickfix list'   },
      l = { '<Cmd>Telescope loclist<CR>'         , 'Location list'   },
      m = { '<Cmd>Telescope keymaps<CR>'         , 'Keymaps'         },
      s = { '<Cmd>Telescope spell_suggest<CR>'   , 'Spell suggest'   },
      o = { '<Cmd>Telescope vim_options<CR>'     , 'Options'         },
      r = { '<Cmd>Telescope registers<CR>'       , 'Registers'       },
      t = { '<Cmd>Telescope filetypes<CR>'       , 'Filetypes'       },
    },
    s = { function() require'telescope.builtin'.symbols(require'telescope.themes'.get_dropdown({sources = {'emoji', 'math'}})) end, 'Symbols' },
    z = { '<Cmd>Telescope zoxide list<CR>', 'Z' },
    ['?'] = { '<Cmd>Telescope help_tags<CR>', 'Vim help' },
  }

}, { prefix = ' ' })

-- Octo.nvim
-- https://github.com/pwntester/octo.nvim
cmd 'packadd octo.nvim'

require"octo".setup({
  default_remote = {"upstream", "origin"}; -- order to try remotes
  ssh_aliases = {},                        -- SSH aliases. e.g. `ssh_aliases = {["github.com-work"] = "github.com"}`
  reaction_viewer_hint_icon = "";         -- marker for user reactions
  user_icon = " ";                        -- user icon
  timeline_marker = "";                   -- timeline marker
  timeline_indent = "2";                   -- timeline indentation
  right_bubble_delimiter = "";            -- bubble delimiter
  left_bubble_delimiter = "";             -- bubble delimiter
  github_hostname = "";                    -- GitHub Enterprise host
  snippet_context_lines = 4;               -- number or lines around commented lines
  issues = {
    order_by = {                           -- criteria to sort results of `Octo issue list`
      field = "CREATED_AT",                -- either COMMENTS, CREATED_AT or UPDATED_AT (https://docs.github.com/en/graphql/reference/enums#issueorderfield)
      direction = "DESC"                   -- either DESC or ASC (https://docs.github.com/en/graphql/reference/enums#orderdirection)
    }
  },
  pull_requests = {
    order_by = {                           -- criteria to sort the results of `Octo pr list`
      field = "CREATED_AT",                -- either COMMENTS, CREATED_AT or UPDATED_AT (https://docs.github.com/en/graphql/reference/enums#issueorderfield)
      direction = "DESC"                   -- either DESC or ASC (https://docs.github.com/en/graphql/reference/enums#orderdirection)
    },
    always_select_remote_on_create = "false" -- always give prompt to select base remote repo when creating PRs
  },
  file_panel = {
    size = 10,                             -- changed files panel rows
    use_icons = true                       -- use web-devicons in file panel (if false, nvim-web-devicons does not need to be installed)
  },
  mappings = {
    issue = {
      close_issue = { lhs = "<space>ic", desc = "close issue" },
      reopen_issue = { lhs = "<space>io", desc = "reopen issue" },
      list_issues = { lhs = "<space>il", desc = "list open issues on same repo" },
      reload = { lhs = "<C-r>", desc = "reload issue" },
      open_in_browser = { lhs = "<C-b>", desc = "open issue in browser" },
      copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
      add_assignee = { lhs = "<space>aa", desc = "add assignee" },
      remove_assignee = { lhs = "<space>ad", desc = "remove assignee" },
      create_label = { lhs = "<space>lc", desc = "create label" },
      add_label = { lhs = "<space>la", desc = "add label" },
      remove_label = { lhs = "<space>ld", desc = "remove label" },
      goto_issue = { lhs = "<space>gi", desc = "navigate to a local repo issue" },
      add_comment = { lhs = "<space>ca", desc = "add comment" },
      delete_comment = { lhs = "<space>cd", desc = "delete comment" },
      next_comment = { lhs = "]c", desc = "go to next comment" },
      prev_comment = { lhs = "[c", desc = "go to previous comment" },
      react_hooray = { lhs = "<space>rp", desc = "add/remove 🎉 reaction" },
      react_heart = { lhs = "<space>rh", desc = "add/remove ❤️ reaction" },
      react_eyes = { lhs = "<space>re", desc = "add/remove 👀 reaction" },
      react_thumbs_up = { lhs = "<space>r+", desc = "add/remove 👍 reaction" },
      react_thumbs_down = { lhs = "<space>r-", desc = "add/remove 👎 reaction" },
      react_rocket = { lhs = "<space>rr", desc = "add/remove 🚀 reaction" },
      react_laugh = { lhs = "<space>rl", desc = "add/remove 😄 reaction" },
      react_confused = { lhs = "<space>rc", desc = "add/remove 😕 reaction" },
    },
    pull_request = {
      checkout_pr = { lhs = "<space>po", desc = "checkout PR" },
      merge_pr = { lhs = "<space>pm", desc = "merge commit PR" },
      squash_and_merge_pr = { lhs = "<space>psm", desc = "squash and merge PR" },
      list_commits = { lhs = "<space>pc", desc = "list PR commits" },
      list_changed_files = { lhs = "<space>pf", desc = "list PR changed files" },
      show_pr_diff = { lhs = "<space>pd", desc = "show PR diff" },
      add_reviewer = { lhs = "<space>va", desc = "add reviewer" },
      remove_reviewer = { lhs = "<space>vd", desc = "remove reviewer request" },
      close_issue = { lhs = "<space>ic", desc = "close PR" },
      reopen_issue = { lhs = "<space>io", desc = "reopen PR" },
      list_issues = { lhs = "<space>il", desc = "list open issues on same repo" },
      reload = { lhs = "<C-r>", desc = "reload PR" },
      open_in_browser = { lhs = "<C-b>", desc = "open PR in browser" },
      copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
      goto_file = { lhs = "gf", desc = "go to file" },
      add_assignee = { lhs = "<space>aa", desc = "add assignee" },
      remove_assignee = { lhs = "<space>ad", desc = "remove assignee" },
      create_label = { lhs = "<space>lc", desc = "create label" },
      add_label = { lhs = "<space>la", desc = "add label" },
      remove_label = { lhs = "<space>ld", desc = "remove label" },
      goto_issue = { lhs = "<space>gi", desc = "navigate to a local repo issue" },
      add_comment = { lhs = "<space>ca", desc = "add comment" },
      delete_comment = { lhs = "<space>cd", desc = "delete comment" },
      next_comment = { lhs = "]c", desc = "go to next comment" },
      prev_comment = { lhs = "[c", desc = "go to previous comment" },
      react_hooray = { lhs = "<space>rp", desc = "add/remove 🎉 reaction" },
      react_heart = { lhs = "<space>rh", desc = "add/remove ❤️ reaction" },
      react_eyes = { lhs = "<space>re", desc = "add/remove 👀 reaction" },
      react_thumbs_up = { lhs = "<space>r+", desc = "add/remove 👍 reaction" },
      react_thumbs_down = { lhs = "<space>r-", desc = "add/remove 👎 reaction" },
      react_rocket = { lhs = "<space>rr", desc = "add/remove 🚀 reaction" },
      react_laugh = { lhs = "<space>rl", desc = "add/remove 😄 reaction" },
      react_confused = { lhs = "<space>rc", desc = "add/remove 😕 reaction" },
    },
    review_thread = {
      goto_issue = { lhs = "<space>gi", desc = "navigate to a local repo issue" },
      add_comment = { lhs = "<space>ca", desc = "add comment" },
      add_suggestion = { lhs = "<space>sa", desc = "add suggestion" },
      delete_comment = { lhs = "<space>cd", desc = "delete comment" },
      next_comment = { lhs = "]c", desc = "go to next comment" },
      prev_comment = { lhs = "[c", desc = "go to previous comment" },
      select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
      select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      react_hooray = { lhs = "<space>rp", desc = "add/remove 🎉 reaction" },
      react_heart = { lhs = "<space>rh", desc = "add/remove ❤️ reaction" },
      react_eyes = { lhs = "<space>re", desc = "add/remove 👀 reaction" },
      react_thumbs_up = { lhs = "<space>r+", desc = "add/remove 👍 reaction" },
      react_thumbs_down = { lhs = "<space>r-", desc = "add/remove 👎 reaction" },
      react_rocket = { lhs = "<space>rr", desc = "add/remove 🚀 reaction" },
      react_laugh = { lhs = "<space>rl", desc = "add/remove 😄 reaction" },
      react_confused = { lhs = "<space>rc", desc = "add/remove 😕 reaction" },
    },
    submit_win = {
      approve_review = { lhs = "<C-a>", desc = "approve review" },
      comment_review = { lhs = "<C-m>", desc = "comment review" },
      request_changes = { lhs = "<C-r>", desc = "request changes review" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
    },
    review_diff = {
      add_review_comment = { lhs = "<space>ca", desc = "add a new review comment" },
      add_review_suggestion = { lhs = "<space>sa", desc = "add a new review suggestion" },
      focus_files = { lhs = "<leader>e", desc = "move focus to changed file panel" },
      toggle_files = { lhs = "<leader>b", desc = "hide/show changed files panel" },
      next_thread = { lhs = "]t", desc = "move to next thread" },
      prev_thread = { lhs = "[t", desc = "move to previous thread" },
      select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
      select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      toggle_viewed = { lhs = "<leader><space>", desc = "toggle viewer viewed state" },
    },
    file_panel = {
      next_entry = { lhs = "j", desc = "move to next changed file" },
      prev_entry = { lhs = "k", desc = "move to previous changed file" },
      select_entry = { lhs = "<cr>", desc = "show selected changed file diffs" },
      refresh_files = { lhs = "R", desc = "refresh changed files panel" },
      focus_files = { lhs = "<leader>e", desc = "move focus to changed file panel" },
      toggle_files = { lhs = "<leader>b", desc = "hide/show changed files panel" },
      select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
      select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      toggle_viewed = { lhs = "<leader><space>", desc = "toggle viewer viewed state" },
    }
  }
})



-- Spaced prefiexd in mode Visual mode
wk.register ({
  l = {
    name = '+LSP',
    a = { ':<C-U>Lspsaga range_code_action<CR>' , 'Code action (range)' , mode = 'v' },
  },
}, { prefix = ' ' })

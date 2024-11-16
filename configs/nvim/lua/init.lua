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

-- Yank and clipboard
o.clipboard = 'unnamed'

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
o.showmode        = false    -- don't show -- INSERT -- etc.
wo.colorcolumn    = '100'    -- show column boarder
wo.number         = true     -- display numberline
wo.relativenumber = true     -- relative line numbers
wo.cursorline     = true     -- highlight current line
wo.cursorlineopt  = 'number' -- only highlight the number of the cursorline
wo.signcolumn     = 'yes'    -- always have signcolumn open to avoid thing shifting around all the time
o.fillchars       = 'stl: ,stlnc: ,vert:·,eob: ' -- No '~' on lines after end of file, other stuff

-- Set colorscheme
if g.vscode == nil then
  require'malo.theme'.extraLushSpecs = {
    'lush_theme.malo.bufferline-nvim',
    'lush_theme.malo.statusline',
    'lush_theme.malo.telescope-nvim',
  }
  cmd 'colorscheme malo'
end


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

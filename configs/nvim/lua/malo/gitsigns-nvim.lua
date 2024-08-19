-- Git signs
-- gitsigns.nvim
-- https://github.com/lewis6991/gitsigns.nvim
vim.cmd 'packadd gitsigns.nvim'

require'gitsigns'.setup {
  signs = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '≃' },
  },
  numhl = false,
  watch_gitdir = {
    interval = 1000
  },
  sign_priority = 6,
  status_formatter = nil, -- Use default
  -- Scenarios to not show a lightbulb.
  -- ignore = {
  --   -- LSP client names to ignore.
  --   -- Example: {"null-ls", "lua_ls"}
  --   clients = { "marksman" },
  --   -- Filetypes to ignore.
  --   -- Example: {"neo-tree", "lua"}
  --   -- Ignore code actions without a `kind` like refactor.rewrite, quickfix.
  --   actions_without_kind = false,
  -- },
}

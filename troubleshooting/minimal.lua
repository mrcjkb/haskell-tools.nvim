-- Minimal nvim config with lazy
-- Assumes a directory in $NVIM_DATA_MINIMAL
-- Start with
--
-- export NVIM_DATA_MINIMAL=$(mktemp -d)
-- export NVIM_APP_NAME="nvim-ht-minimal"
-- nvim -u minimal.lua
--
-- Then exit out of neovim and start again.

-- Ignore default config
local config_path = vim.fn.stdpath('config')
vim.opt.rtp:remove(config_path)

-- Ignore default plugins
local data_path = vim.fn.stdpath('data')
local pack_path = data_path .. '/site'
vim.opt.packpath:remove(pack_path)

-- bootstrap lazy.nvim
data_path = assert(os.getenv('NVIM_DATA_MINIMAL'), '$NVIM_DATA_MINIMAL environment variable not set!')
local lazypath = data_path .. '/lazy/lazy.nvim'
local uv = vim.uv
  ---@diagnostic disable-next-line: deprecated
  or vim.loop
if not uv.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'git@github.com:folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

local lazy = require('lazy')

lazy.setup({
  {
    'mrcjkb/haskell-tools.nvim',
    version = '^3', -- Recommended
    init = function()
      -- Configure haskell-tools.nvim here
      vim.g.haskell_tools = {}
    end,
    dependencies = {
      -- Uncomment or add any optional dependencies needed to reproduce the issue
      -- 'nvim-telescope/telescope.nvim',
      -- 'akinsho/toggleterm.nvim',
    },
    ft = { 'haskell', 'lhaskell', 'cabal', 'cabalproject' },
  },
  -- Add any other plugins needed to reproduce the issue.
  -- see https://github.com/folke/lazy.nvim#-lazynvim for details.
}, { root = data_path, state = data_path .. '/lazy-state.json', lockfile = data_path .. '/lazy-lock.json' })

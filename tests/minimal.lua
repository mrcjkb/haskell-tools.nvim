-- Minimal nvim config with packer
-- Assumes a directory in $NVIM_DATA_MINIMAL
-- Start with $NVIM_DATA_MINIMAL=$(mktemp -d) nvim -u minimal.lua
-- Then exit out of neovim and start again.

-- Ignore default config
local fn = vim.fn
local config_path = fn.stdpath('config')
vim.opt.runtimepath:remove(config_path)

-- Ignore default plugins
local data_path = fn.stdpath('data')
local pack_path = data_path .. '/site'
vim.opt.packpath:remove(pack_path)

--append temporary config and pack dir
data_path = os.getenv('NVIM_DATA_MINIMAL')
if not data_path then
  error('$NVIM_DATA_MINIMAL environment variable not set!')
end
vim.opt.runtimepath:append('.')
vim.opt.runtimepath:append(data_path)
vim.opt.runtimepath:append(data_path .. '/site/pack/packer/start/plenary.nvim')
vim.opt.packpath:append(data_path .. '/site')

-- bootstrap packer
local packer_install_path = data_path .. '/site/pack/packer/start/packer.nvim'
local install_plugins = false

if vim.fn.empty(vim.fn.glob(packer_install_path)) > 0 then
  vim.cmd('!git clone git@github.com:wbthomason/packer.nvim ' .. packer_install_path)
  vim.cmd('packadd packer.nvim')
  install_plugins = true
else
  vim.cmd('packadd packer.nvim')
end

local packer = require('packer')

packer.init {
  package_root = data_path .. '/site/pack',
  compile_path = data_path .. '/plugin/packer_compiled.lua',
}

vim.cmd('runtime! plugin/plenary.vim')

packer.startup(function(use)
  use('wbthomason/packer.nvim')
  use {
    'MrcJkb/haskell-tools.nvim',
    requires = {
      'neovim/nvim-lspconfig',
      'nvim-lua/plenary.nvim',
    },
    config = function()
      -- Paste setup here
    end,
  }

  if install_plugins then
    packer.sync()
  end
end)

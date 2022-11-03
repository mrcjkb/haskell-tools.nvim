local deps = require('haskell-tools.deps')

-- Utility functions for analysing a project
local M = {}

-- Get the currently open file
local function get_current_file()
  return vim.fn.expand('%')
end

-- Get the root directory for a given path
-- @return string | nil
function M.get_root_dir(path)
  local lspconfig = deps.require_lspconfig('lspconfig')
  return lspconfig.hls.get_root_dir(path)
end

-- Is the current buffer part of a cabal project?
-- @return boolean
function M.is_cur_buf_cabal_project()
  local lspconfig_util = deps.require_lspconfig('lspconfig.util')
  local get_root = lspconfig_util.root_pattern('*.cabal', 'cabal.project') 
  return get_root(get_current_file()) ~= nil
end

-- Is the current buffer part of a stack project?
-- @return boolean
function M.is_cur_buf_stack_project()
  local lspconfig_util = deps.require_lspconfig('lspconfig.util')
  local get_root = lspconfig_util.root_pattern('stack.yaml')
  return get_root(get_current_file()) ~= nil
end

return M

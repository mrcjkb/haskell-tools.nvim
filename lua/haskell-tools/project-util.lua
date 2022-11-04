local deps = require('haskell-tools.deps')

-- Utility functions for analysing a project.
-- This module is not public API.
local M = {}

local function root_pattern(...)
  local lspconfig_util = deps.require_lspconfig('lspconfig.util')
  return lspconfig_util.root_pattern(...)
end

-- Get the root of the cabal project for a path
-- @return string | nil
M.match_cabal_project_root = root_pattern('cabal.project')

-- Get the root of the stack project for a path
-- @return string | nil
M.match_stack_project_root = root_pattern('stack.yaml')

-- Get the root of the package for a path
-- @return string | nil
M.match_package_root = root_pattern('*.cabal', 'package.yaml')

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

-- Is `path` part of a cabal project?
-- @param string?: path to check for
-- @return boolean
function M.is_cabal_project(path)
  path = path or vim.fn.expand('%')
  local get_root = root_pattern('*.cabal', 'cabal.project') 
  return get_root(path) ~= nil
end

-- Is `path` part of a stack project?
-- @param string?: path to check for
-- @return boolean
function M.is_stack_project(path)
  path = path or vim.fn.expand('%')
  return M.match_stack_project_root(path) ~= nil
end

-- Get the package name for a path
-- @return string | nil
function M.get_package_name(path)
  local package_path = M.match_package_root(path)
  return package_path and vim.fn.fnamemodify(package_path, ':t')
end

return M

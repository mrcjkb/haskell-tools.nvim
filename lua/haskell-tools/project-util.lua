local deps = require('haskell-tools.deps')

-- Utility functions for analysing a project.
-- This module is not public API.
local M = {}

local function root_pattern(...)
  local lspconfig_util = deps.require_lspconfig('lspconfig.util')
  return lspconfig_util.root_pattern(...)
end

local function escape_glob_wildcards(path)
  return path:gsub('([%[%]%?%*])', '\\%1')
end

local function path_join(...)
  return table.concat(vim.tbl_flatten { ... }, '/')
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

-- Get the package.yaml for a given path
-- @return string | nil
function M.get_package_yaml(path)
  local match = root_pattern('package.yaml')
  local dir = match(path)
  return dir and dir .. '/package.yaml'
end

-- Get the *.cabal for a given path
-- @return string | nil
function M.get_package_cabal(path)
  local match = root_pattern('*.cabal')
  local dir = match(path)
  if not dir then
    return nil
  end
  dir = escape_glob_wildcards(dir)
  for _, pattern in ipairs(vim.fn.glob(path_join(dir, '*.cabal'), true, true)) do
    if pattern then
      return pattern
    end
  end
end

-- Get the root directory for a given path
-- @return string | nil
function M.get_root_dir(path)
  local lspconfig = deps.require_lspconfig('lspconfig')
  return lspconfig.hls.get_root_dir(path)
end
-- Is `path` part of a cabal project?
-- @param string: path to check for
-- @return boolean
function M.is_cabal_project(path)
  local get_root = root_pattern('*.cabal', 'cabal.project')
  return get_root(path) ~= nil
end

-- Is `path` part of a stack project?
-- @param string: path to check for
-- @return boolean
function M.is_stack_project(path)
  return M.match_stack_project_root(path) ~= nil
end

function M.get_package_name(path)
  local package_path = M.match_package_root(path)
  return package_path and vim.fn.fnamemodify(package_path, ':t')
end

return M

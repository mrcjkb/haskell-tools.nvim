---@mod haskell-tools.project_util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Utility functions for analysing a project.
---@brief ]]

local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')

local project_util = {}

---@return fun(path:string):(string|nil)
local function root_pattern(...)
  local lspconfig_util = deps.require_lspconfig('lspconfig.util')
  return lspconfig_util.root_pattern(...)
end

---@param path string
---@return string escaped_path
local function escape_glob_wildcards(path)
  local escaped_path = path:gsub('([%[%]%?%*])', '\\%1')
  return escaped_path
end

---@param ... string The paths to join
---@return string joined_path
local function path_join(...)
  return table.concat(vim.tbl_flatten { ... }, '/')
end

---Get the root of the cabal project for a path
project_util.match_cabal_project_root = root_pattern('cabal.project')

---Get the root of the stack project for a path
project_util.match_stack_project_root = root_pattern('stack.yaml')

---Get the root of the project for a path
project_util.match_project_root = root_pattern('cabal.project', 'stack.yaml')

---Get the root of the package for a path
project_util.match_package_root = root_pattern('*.cabal', 'package.yaml')

---Get the package.yaml for a given path
---@param path string
---@return string|nil package_yaml_path
function project_util.get_package_yaml(path)
  local match = root_pattern('package.yaml')
  local dir = match(path)
  return dir and dir .. '/package.yaml'
end

---Get the *.cabal for a given path
---@param path string
---@return string|nil cabal_file_path
function project_util.get_package_cabal(path)
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

---Get the root directory for a given path
---@param path string
---@return string|nil project_root
function project_util.get_root_dir(path)
  local lspconfig = deps.require_lspconfig('lspconfig')
  local root_dir = lspconfig.hls.get_root_dir(path)
  ht.log.debug('Project root:' .. root_dir)
  return root_dir
end

---Is `path` part of a cabal project?
---@param path string
---@return boolean is_cabal_project
function project_util.is_cabal_project(path)
  local get_root = root_pattern('*.cabal', 'cabal.project')
  if get_root(path) ~= nil then
    ht.log.debug('Detected cabal project.')
    return true
  end
  return false
end

---Is `path` part of a stack project?
---@param path string
---@return boolean is_stack_project
function project_util.is_stack_project(path)
  if project_util.match_stack_project_root(path) ~= nil then
    ht.log.debug('Detected stack project.')
    return true
  end
  return false
end

---Get the package name for a given path
---@param path string
---@return string|nil package_name
function project_util.get_package_name(path)
  local package_path = project_util.match_package_root(path)
  return package_path and vim.fn.fnamemodify(package_path, ':t')
end

return project_util

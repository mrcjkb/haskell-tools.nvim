---@mod haskell-tools.project_util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Utility functions for analysing a project.
---@brief ]]

local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')

local Path = deps.require_plenary('plenary.path')

---@class Path Plenary Path (as used by this module)
---@field filename string
---@field parent fun():Path
---@field absolute fun():Path

local project_util = {}

---@param path string
---@return string stripped_path For zipfile: or tarfile: virtual paths, returns the path to the archive. Other paths are returned unaltered.
--- Taken from nvim-lspconfig
local function strip_archive_subpath(path)
  -- Matches regex from zip.vim / tar.vim
  path = vim.fn.substitute(path, 'zipfile://\\(.\\{-}\\)::[^\\\\].*$', '\\1', '')
  path = vim.fn.substitute(path, 'tarfile:\\(.\\{-}\\)::.*$', '\\1', '')
  return path
end

---@param path string the file path to search in
---@param ... string Search patterns (can be globs)
---@return string|nil The first file that matches the globs
local function find_file(path, ...)
  for _, search_term in ipairs(vim.tbl_flatten { ... }) do
    local results = vim.fn.glob(Path:new(path, search_term).filename, true, true)
    if #results > 0 then
      return results[1]
    end
  end
end

---Iterate the path until we find the rootdir.
---@param startpath Path The start path
---@return fun(_:any,path:Path):(Path?,Path?)
---@return Path startpath
---@return Path startpath
local function iterate_parents(startpath)
  ---@param _ any Ignored
  ---@param path Path file path
  ---@return Path|nil path
  ---@return Path|nil startpath
  local function it(_, path)
    local next = path:parent()
    if next.filename == path.filename or next.filename == '/nix/store' then
      return
    end
    if vim.loop.fs_realpath(next.filename) then
      return next, startpath
    end
  end
  return it, startpath, startpath
end

---@param startpath Path The start path to search upward from
---@param matcher fun(path:string):string|nil
---@return Path|nil
local function search_ancestors(startpath, matcher)
  if matcher(startpath.filename) then
    return startpath
  end
  for path in iterate_parents(startpath) do
    if not path then
      return nil
    end
    if matcher(path.filename) then
      return path
    end
  end
end

---@param ... string Globs to match in the root directory
---@return fun(path:string):(string|nil)
local function root_pattern(...)
  local args = vim.tbl_flatten { ... }
  local function matcher(path)
    return find_file(path, unpack(args))
  end
  return function(path)
    ---@type Path
    local startpath = Path:new(strip_archive_subpath(path))
    local result = search_ancestors(startpath, matcher)
    return result and result.filename
  end
end

---@param path string
---@return string escaped_path
local function escape_glob_wildcards(path)
  local escaped_path = path:gsub('([%[%]%?%*])', '\\%1')
  return escaped_path
end

---Get the root of a cabal multi-package project for a path
project_util.match_cabal_multi_project_root = root_pattern('cabal.project')

---Get the root of a cabal package for a path
project_util.match_cabal_package_root = root_pattern('*.cabal')

---Get the root of the cabal project for a path
---@param path string File path
project_util.match_cabal_project_root = function(path)
  return project_util.match_cabal_multi_project_root(path) or project_util.match_cabal_package_root(path)
end

---Get the root of the stack project for a path
project_util.match_stack_project_root = root_pattern('stack.yaml')

---Get the root of the project for a path
project_util.match_project_root = root_pattern('cabal.project', 'stack.yaml')

---Get the root of the package for a path
project_util.match_package_root = root_pattern('*.cabal', 'package.yaml')

---Get the directory containing a haskell-language-server hie.yaml
project_util.match_hie_yaml = root_pattern('hie.yaml')

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
  for _, pattern in ipairs(vim.fn.glob(Path:new(dir, '*.cabal').filename, true, true)) do
    if pattern then
      return pattern
    end
  end
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

---@mod haskell-tools.project_util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Utility functions for analysing a project.
---@brief ]]

local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')
local ht_util = require('haskell-tools.util')
local cabal = require('haskell-tools.project.cabal')
local stack = require('haskell-tools.project.stack')

local Path = deps.require_plenary('plenary.path')

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
  local max_iterations = 100
  for path in iterate_parents(startpath) do
    max_iterations = max_iterations - 1
    if max_iterations == 0 then
      return
    end
    if not path then
      return
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

---Parse the package paths (absolute) from a project file
---@param project_file string project file (cabal.project or stack.yaml)
---@return string[] package_paths
---@async
function project_util.parse_package_paths(project_file)
  local package_paths = {}
  local content = ht_util.read_file_async(project_file)
  if not content then
    return package_paths
  end
  local project_dir = vim.fn.fnamemodify(project_file, ':h')
  local lines = vim.split(content, '\n') or {}
  local packages_start = false
  for _, line in ipairs(lines) do
    if packages_start then
      local is_indented = line:match('^%s') ~= nil
      local is_yaml_list_elem = line:match('^%-') ~= nil
      if not (is_indented or is_yaml_list_elem) then
        return package_paths
      end
    end
    if packages_start then
      local trimmed = ht_util.trim(line)
      local pkg_rel_path = trimmed:match('/(.+)')
      local pkg_path = Path:new(project_dir, pkg_rel_path).filename
      if vim.fn.isdirectory(pkg_path) == 1 then
        package_paths[#package_paths + 1] = pkg_path
      end
    end
    if line:match('packages:') then
      packages_start = true
    end
  end
  return package_paths
end

---Parse the DAP entry points from a *.cabal file
---@param package_path string Path to a package directory
---@return HsEntryPoint[] entry_points
---@async
function project_util.parse_package_entrypoints(package_path)
  if project_util.is_cabal_project(package_path) then
    return cabal.parse_package_entrypoints(package_path)
  end
  return stack.parse_package_entrypoints(package_path)
end

---@param project_root string Project root directory
---@return HsEntryPoint[]
---@async
function project_util.parse_project_entrypoints(project_root)
  local entry_points = {}
  local project_file = Path:new(project_root, 'cabal.project').filename
  if vim.fn.filereadable(project_file) == 1 then
    for _, package_path in pairs(project_util.parse_package_paths(project_file)) do
      vim.list_extend(entry_points, cabal.parse_package_entrypoints(package_path))
    end
    return entry_points
  end
  project_file = Path:new(project_root, 'stack.yaml').filename
  if vim.fn.filereadable(project_file) == 1 then
    for _, package_path in pairs(project_util.parse_package_paths(project_file)) do
      vim.list_extend(entry_points, stack.parse_package_entrypoints(package_path))
    end
    return entry_points
  end
  return cabal.parse_package_entrypoints(project_root)
end

return project_util

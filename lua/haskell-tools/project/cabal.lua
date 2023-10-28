---@mod haskell-tools.cabal

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Helper functions related to cabal projects
---@brief ]]

local Strings = require('haskell-tools.strings')
local HtParser = require('haskell-tools.parser')
local Dap = require('haskell-tools.dap.internal')
local OS = require('haskell-tools.os')
local compat = require('haskell-tools.compat')

---@class CabalProjectHelper
local CabalProjectHelper = {}

---@class CabalEntryPointParserData
---@field idx integer
---@field lines string[]
---@field line string
---@field package_dir string

---@class CabalEntryPointParserState
---@field package_name string
---@field entry_points HsEntryPoint[]
---@field mains string[]
---@field source_dirs string[]
---@field src_dir_indent_pattern string
---@field exe_name string | nil

---@param data CabalEntryPointParserData
---@param state CabalEntryPointParserState
local function get_entrypoint_from_line(data, state)
  local package_dir = data.package_dir
  local idx = data.idx
  local lines = data.lines
  local line = data.line
  state.package_name = state.package_name or line:match('^name:%s*(.+)')
  local no_indent = HtParser.get_indent(line) == 0
  if no_indent or idx == #lines then
    vim.list_extend(
      state.entry_points,
      Dap.mk_entry_points(state.package_name, state.exe_name, package_dir, state.mains, state.source_dirs)
    )
    state.mains = {}
    state.source_dirs = {}
    state.exe_name = nil
  end
  state.exe_name = state.exe_name or line:match('^%S+%s+(.+)') or state.package_name
  -- main detection
  local main = line:match('main%-is:%s+(.+)%.hs')
  if not main and lines[idx + 1] and line:match('main%-is:') then
    main = (lines[idx + 1]):match('%s+(.+)%.hs')
  end
  if main then
    table.insert(state.mains, main .. '.hs')
  end
  -- source directory detection
  local is_src_dir_end = state.src_dir_indent_pattern and (line == '' or line:match(state.src_dir_indent_pattern))
  if is_src_dir_end then
    state.src_dir_indent_pattern = nil
  end
  if state.src_dir_indent_pattern then
    local source_dir = line:match(',%s*(.*)') or line:match('%s+(.*)')
    if source_dir then
      table.insert(state.source_dirs, source_dir)
    end
  else
    local source_dirs_indent = line:match('(%s*)hs%-source%-dirs:')
    if source_dirs_indent then
      state.src_dir_indent_pattern = '^' .. ('%s'):rep(#source_dirs_indent) .. '%S+'
    end
  end
end

---Parse the DAP entry points from a *.cabal file
---@param package_file string Path to the *.cabal file
---@return HsEntryPoint[] entry_points
---@async
local function parse_package_entrypoints(package_file)
  local state = {
    entry_points = {},
    mains = {},
    source_dirs = {},
  }
  local package_dir = vim.fn.fnamemodify(package_file, ':h') or package_file
  local entry_points = {}
  local content = OS.read_file_async(package_file)
  if not content then
    return entry_points
  end
  local lines = vim.split(content, '\n') or {}
  for idx, line in ipairs(lines) do
    local is_comment = vim.startswith(Strings.trim(line), '--')
    if not is_comment then
      ---@type CabalEntryPointParserData
      local data = {
        package_dir = package_dir,
        line = line,
        lines = lines,
        idx = idx,
      }
      get_entrypoint_from_line(data, state)
    end
  end
  return state.entry_points
end

---Parse the DAP entry points from a *.cabal file
---@param package_path string Path to a package directory
---@return HsEntryPoint[] entry_points
---@async
function CabalProjectHelper.parse_package_entrypoints(package_path)
  local entry_points = {}
  for _, package_file in pairs(vim.fn.glob(compat.joinpath(package_path, '*.cabal'), true, true)) do
    vim.list_extend(entry_points, parse_package_entrypoints(package_file))
  end
  return entry_points
end

return CabalProjectHelper

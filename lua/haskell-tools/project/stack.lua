---@mod haskell-tools.stack

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Helper functions related to stack projects
---@brief ]]

local Strings = require('haskell-tools.strings')
local HtParser = require('haskell-tools.parser')
local Dap = require('haskell-tools.dap.internal')
local OS = require('haskell-tools.os')
local compat = require('haskell-tools.compat')

---@class StackProjectHelper
local StackProjectHelper = {}

---@param str string
---@return boolean is_yaml_comment
local function is_yaml_comment(str)
  return vim.startswith(Strings.trim(str), '#')
end

---@class StackEntryPointParserData
---@field idx integer
---@field lines string[]
---@field line string
---@field package_dir string
---@field next_line string|nil

---@class StackEntryPointParserState
---@field package_name string
---@field entry_points HsEntryPoint[]
---@field mains string[]
---@field source_dirs string[]
---@field parsing_exe_list boolean
---@field parsing_exe boolean
---@field parsing_source_dirs boolean
---@field exe_indent integer | nil
---@field exe_name string | nil

---@param data StackEntryPointParserData
---@param state StackEntryPointParserState
local function parse_exe_list_line(data, state)
  local package_dir = data.package_dir
  local idx = data.idx
  local lines = data.lines
  local line = data.line
  local next_line = lines[idx + 1]
  local indent = HtParser.get_indent(line)
  state.exe_indent = state.exe_indent or indent
  state.exe_name = indent == state.exe_indent and line:match('%s*(.+):') or state.exe_name
  if state.parsing_exe then
    local main = line:match('main:%s+(.+)%.hs')
    if not main and line:match('main:') and next_line then
      main = next_line:match('%s+(.+)%.hs')
    end
    if main then
      table.insert(state.mains, main .. '.hs')
    end
    local source_dir = line:match('source%-dirs:%s+(.+)')
    if source_dir then
      -- Single source directory
      state.parsing_source_dirs = false
    end
    if state.parsing_source_dirs then
      source_dir = line:match('%s+%-%s*(.*)') or line:match('%s+(.*)')
    end
    if source_dir then
      table.insert(state.source_dirs, source_dir)
    end
    local is_source_dir_list = not source_dir and line:match('source%-dirs:') ~= nil
    state.parsing_source_dirs = is_source_dir_list
      or (
        state.parsing_source_dirs
        and next_line
        and (next_line:match('^%s+%-') or HtParser.get_indent(next_line) > indent)
      )
  end
  if state.parsing_exe and (not next_line or HtParser.get_indent(next_line) == 0 or indent <= state.exe_indent) then
    vim.list_extend(
      state.entry_points,
      Dap.mk_entry_points(state.package_name, state.exe_name, package_dir, state.mains, state.source_dirs)
    )
    state.mains = {}
    state.source_dirs = {}
    state.parsing_exe = false
  else
    state.parsing_exe = indent >= state.exe_indent
  end
end

---@param data StackEntryPointParserData
---@param state StackEntryPointParserState
local function get_entrypoint_from_line(data, state)
  local line = data.line
  state.package_name = state.package_name or line:match('^name:%s*(.+)')
  local indent = HtParser.get_indent(line)
  if indent == 0 then
    state.parsing_exe_list = false
    state.exe_indent = nil
  end
  if state.parsing_exe_list then
    parse_exe_list_line(data, state)
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
    parsing_exe_list = false,
    parsing_exe = false,
    parsing_source_dirs = false,
  }
  local package_dir = vim.fn.fnamemodify(package_file, ':h') or package_file
  local content = OS.read_file_async(package_file)
  if not content then
    return state.entry_points
  end
  local lines = vim.split(content, '\n') or {}
  for idx, line in ipairs(lines) do
    if not is_yaml_comment(line) then
      ---@type StackEntryPointParserData
      local data = {
        package_dir = package_dir,
        line = line,
        lines = lines,
        idx = idx,
      }
      get_entrypoint_from_line(data, state)
    end
    if line:match('^executables:') or line:match('^tests:') then
      state.parsing_exe_list = true
    end
  end
  return state.entry_points
end

---Parse the DAP entry points from a package.yaml file
---@param package_path string Path to a package directory
---@return HsEntryPoint[] entry_points
---@async
function StackProjectHelper.parse_package_entrypoints(package_path)
  local entry_points = {}
  for _, package_file in pairs(vim.fn.glob(compat.joinpath(package_path, 'package.yaml'), true, true)) do
    vim.list_extend(entry_points, parse_package_entrypoints(package_file))
  end
  return entry_points
end

return StackProjectHelper

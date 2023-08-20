---@mod haskell-tools.util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- General utility functions that may need to be moded somewhere else
---@brief ]]

local Path = require('plenary.path')
local uv = vim.uv
  ---@diagnostic disable-next-line: deprecated
  or vim.loop

---@class HtUtil
local HtUtil = {}

--- Quote a string
--- @param str string
--- @return string quoted_string
HtUtil.quote = function(str)
  return '"' .. str .. '"'
end

---Read the content of a file
---@param filename string
---@return string|nil content
HtUtil.read_file = function(filename)
  local content
  local f = io.open(filename, 'r')
  if f then
    content = f:read('*a')
    f:close()
  end
  return content
end

---Asynchronously the content of a file
---@param filename string
---@return string|nil content
---@async
HtUtil.read_file_async = function(filename)
  local file_fd = uv.fs_open(filename, 'r', 438)
  if not file_fd then
    return nil
  end
  local stat = uv.fs_fstat(file_fd)
  if not stat then
    return nil
  end
  local data = uv.fs_read(file_fd, stat.size, 0)
  uv.fs_close(file_fd)
  ---@cast data string?
  return data
end

---Trim leading and trailing whitespace.
---@param str string
---@return string trimmed
HtUtil.trim = function(str)
  return (str:match('^%s*(.*)') or str):gsub('%s*$', '')
end

---@param package_name string
---@param exe_name string
---@param package_dir string
---@param mains string[]
---@param source_dirs string[]
---@return HsEntryPoint[] entry_points
HtUtil.mk_entry_points = function(package_name, exe_name, package_dir, mains, source_dirs)
  ---@type HsEntryPoint[]
  local entry_points = {}
  for _, source_dir in pairs(source_dirs) do
    for _, main in pairs(mains) do
      local filename = Path:new(package_dir, source_dir, main).filename
      if vim.fn.filereadable(filename) == 1 then
        local entry_point = {
          package_name = package_name,
          exe_name = exe_name,
          main = main,
          source_dir = source_dir,
          package_dir = package_dir,
        }
        table.insert(entry_points, entry_point)
      end
    end
  end
  return entry_points
end

---@param str string
---@return integer indent
HtUtil.get_indent = function(str)
  return #(str:match('^(%s+)%S') or '')
end

---Evaluate a value that may be a function
---or an evaluated value
---@generic T
---@param value (fun():T)|T
---@return T
HtUtil.evaluate = function(value)
  if type(value) == 'function' then
    return value()
  end
  return value
end

---@param bufnr number The buffer number
---@return boolean is_cabal_file
HtUtil.is_cabal_file = function(bufnr)
  local filetype = vim.bo[bufnr].filetype
  return filetype == 'cabal' or filetype == 'cabalproject'
end

return HtUtil

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

--- Pretty-print a type signature
--- @param sig string|nil The raw signature
--- @return string|nil pp_sig The pretty-printed signature
local function pp_signature(sig)
  local pp_sig = sig
    and sig
      :gsub('\n', ' ') -- join lines
      :gsub('forall .*%.%s', '') -- hoogle cannot search for `forall a.`
      :gsub('^%s*(.-)%s*$', '%1') -- trim
  return pp_sig
end

---@class HtUtil
local HtUtil = {}

--- Get the type signature of the word under the cursor from markdown
--- @param func_name string the name of the function
--- @param docs string Markdown docs
--- @return string|nil function_signature Type signature, or the word under the cursor if none was found
--- @return string[] signatures Other type signatures returned by hls
HtUtil.try_get_signatures_from_markdown = function(func_name, docs)
  local all_sigs = {}
  ---@type string|nil
  local raw_func_sig = docs:match('```haskell\n' .. func_name .. '%s::%s([^```]*)')
  for code_block in docs:gmatch('```haskell\n([^```]*)\n```') do
    ---@type string|nil
    local sig = code_block:match('::%s([^```]*)')
    local pp_sig = sig and pp_signature(sig)
    if sig and not vim.tbl_contains(all_sigs, pp_sig) then
      table.insert(all_sigs, pp_sig)
    end
  end
  return raw_func_sig and pp_signature(raw_func_sig), all_sigs
end

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

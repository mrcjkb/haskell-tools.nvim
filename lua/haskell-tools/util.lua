---@mod haskell-tools.util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- General utility functions that may need to be moded somewhere else
---@brief ]]

local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')
local Job = deps.require_plenary('plenary.job')
local Path = require('plenary.path')
---@diagnostic disable-next-line: deprecated
local uv = vim.uv or vim.loop

---@class Util
---@field try_get_signatures_from_markdown fun(string, string):(string|nil, string[])
---@field open_browser fun(string):nil
---@field read_file fun(string):(string|nil)
---@field read_file_async fun(string):(string|nil)
---@field quote fun(string):string
---@field tbl_merge function

---@type Util
local util = {}

---Deep extend tables with the 'keep' behaviour
---@generic T1: table
---@generic T2: table
---@param ... T2 Two or more map-like tables
---@return T1|T2 The merged table
function util.tbl_merge(...)
  return vim.tbl_deep_extend('keep', ...)
end

---@param url string
---@return nil
function util.open_browser(url)
  local browser_cmd
  if vim.fn.has('unix') == 1 then
    if vim.fn.executable('sensible-browser') == 1 then
      browser_cmd = 'sensible-browser'
    else
      browser_cmd = 'xdg-open'
    end
  end
  if vim.fn.has('mac') == 1 then
    browser_cmd = 'open'
  end
  if browser_cmd and vim.fn.executable(browser_cmd) == 1 then
    local job_opts = {
      command = browser_cmd,
      args = { url },
    }
    ht.log.debug { 'Opening browser', job_opts }
    Job:new(job_opts):start()
    return
  end
  local msg = 'No executable found to open the browser.'
  ht.log.error(msg)
  vim.notify('haskell-tools.hoogle: ' .. msg, vim.log.levels.ERROR)
end

--- Pretty-print a type signature
--- @param sig string The raw signature
--- @return string pp_sig The pretty-printed signature
local function pp_signature(sig)
  local pp_sig = sig
    :gsub('\n', ' ') -- join lines
    :gsub('forall .*%.%s', '') -- hoogle cannot search for `forall a.`
    :gsub('^%s*(.-)%s*$', '%1') -- trim
  return pp_sig
end

--- Get the type signature of the word under the cursor from markdown
--- @param func_name string the name of the function
--- @param docs string Markdown docs
--- @return string|nil function_signature Type signature, or the word under the cursor if none was found
--- @return string[] signatures Other type signatures returned by hls
function util.try_get_signatures_from_markdown(func_name, docs)
  local all_sigs = {}
  ---@type string|nil
  local raw_func_sig = docs:match('```haskell\n' .. func_name .. '%s::%s([^```]*)')
  for code_block in docs:gmatch('```haskell\n([^```]*)\n```') do
    local sig = code_block:match('::%s([^```]*)')
    local pp_sig = pp_signature(sig)
    if sig and not vim.tbl_contains(all_sigs, pp_sig) then
      table.insert(all_sigs, pp_sig)
    end
  end
  return raw_func_sig and pp_signature(raw_func_sig), all_sigs
end

--- Quote a string
--- @param str string
--- @return string quoted_string
function util.quote(str)
  return '"' .. str .. '"'
end

---Read the content of a file
---@param filename string
---@return string|nil content
function util.read_file(filename)
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
function util.read_file_async(filename)
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
function util.trim(str)
  return (str:match('^%s*(.*)') or str):gsub('%s*$', '')
end

---@param package_name string
---@param exe_name string
---@param package_dir string
---@param mains string[]
---@param source_dirs string[]
---@return HsEntryPoint[] entry_points
function util.mk_entry_points(package_name, exe_name, package_dir, mains, source_dirs)
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
function util.get_indent(str)
  return #(str:match('^(%s+)%S') or '')
end

return util

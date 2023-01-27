---@mod haskell-tools.util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- General utility functions that may need to be moded somewhere else
---@brief ]]

local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')
local Job = deps.require_plenary('plenary.job')

---@class Util
---@field get_signature_from_markdown fun(string):string
---@field open_browser fun(string):nil
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

--- Get the type signature of the word under the cursor from markdown
--- @param docs string Markdown docs
--- @return string result Type signature, or the word under the cursor if none was found
function util.try_get_signature_from_markdown(docs)
  local func_name = vim.fn.expand('<cword>')
  local full_sig = docs:match('```haskell\n' .. func_name .. ' :: ([^```]*)')
  return full_sig
      and full_sig
        :gsub('\n', ' ') -- join lines
        :gsub('forall .*%.%s', '') -- hoogle cannot search for `forall a.`
        :gsub('^%s*(.-)%s*$', '%1') -- trim
    or func_name -- Fall back to value under cursor
end

--- Quote a string
--- @param str string
--- @return string quoted_string
function util.quote(str)
  return '"' .. str .. '"'
end

return util

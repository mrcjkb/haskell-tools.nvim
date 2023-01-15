---@mod haskell-tools.util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')
local Job = deps.require_plenary('plenary.job')

-- General utility functions that may need to be moded somewhere else
local util = {}

function util.tbl_merge(...)
  return vim.tbl_deep_extend('keep', ...)
end

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
  if browser_cmd then
    local job_opts = {
      command = browser_cmd,
      args = { url },
    }
    ht.log.debug { 'Opening browser', job_opts }
    Job:new(job_opts):start()
  end
end

-- Get the type signature of the word under the cursor from markdown
-- @param string: markdown docs
-- @return the type signature, or the word under the cursor if none was found
function util.get_signature_from_markdown(docs)
  local func_name = vim.fn.expand('<cword>')
  local full_sig = docs:match('```haskell\n' .. func_name .. ' :: ([^```]*)')
  return full_sig
      and full_sig
        :gsub('\n', ' ') -- join lines
        :gsub('forall .*%.%s', '') -- hoogle cannot search for `forall a.`
        :gsub('^%s*(.-)%s*$', '%1') -- trim
    or func_name -- Fall back to value under cursor
end

-- Quote a string
-- @param string
-- @return (string) the quoted string
function util.quote(str)
  return '"' .. str .. '"'
end

return util

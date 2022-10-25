local deps = require('haskell-tools.deps')
local Job = deps.require_plenary('plenary.job')

-- General utility funcitons that may need to be moded somewhere else
local M = {}

function M.tbl_merge(...)
  return vim.tbl_deep_extend('keep', ...)
end

function M.open_browser(url)
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
    Job:new({
      command = browser_cmd,
      args = { vim.fn.fnameescape(url) },
    }):start()
  end
end

return M

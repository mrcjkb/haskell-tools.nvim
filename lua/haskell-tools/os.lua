---@mod haskell-tools.util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Functions for interacting with the operating system
---@brief ]]

local deps = require('haskell-tools.deps')
local Job = deps.require_plenary('plenary.job')
local log = require('haskell-tools.log')

---@class OS
local OS = {}

---@param url string
---@return nil
OS.open_browser = function(url)
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
    log.debug { 'Opening browser', job_opts }
    Job:new(job_opts):start()
    return
  end
  local msg = 'No executable found to open the browser.'
  log.error(msg)
  vim.notify('haskell-tools.hoogle: ' .. msg, vim.log.levels.ERROR)
end

return OS

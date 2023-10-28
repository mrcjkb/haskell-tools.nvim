---@mod haskell-tools.os

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Functions for interacting with the operating system
---@brief ]]

local compat = require('haskell-tools.compat')
local log = require('haskell-tools.log.internal')
local uv = compat.uv

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
    local cmd = { browser_cmd, url }
    log.debug { 'Opening browser', cmd }
    compat.system(cmd, nil, function(sc)
      ---@cast sc vim.SystemCompleted
      if sc.code ~= 0 then
        log.error { 'Error opening browser', sc.code, sc.stderr }
      end
    end)
    return
  end
  local msg = 'No executable found to open the browser.'
  log.error(msg)
  vim.notify('haskell-tools.hoogle: ' .. msg, vim.log.levels.ERROR)
end

---Read the content of a file
---@param filename string
---@return string|nil content
OS.read_file = function(filename)
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
OS.read_file_async = function(filename)
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

return OS

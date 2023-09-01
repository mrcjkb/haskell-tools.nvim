---@mod haskell-tools.log haskell-tools Logging

---@class HaskellToolsLog
local HaskellToolsLog = {}

---Get the haskell-language-server log file
---@return string filepath
HaskellToolsLog.get_hls_logfile = function()
  return require('haskell-tools.log.internal').get_hls_logfile()
end

---Get the haskell-tools.nvim log file path.
---@return string filepath
HaskellToolsLog.get_logfile = function()
  return require('haskell-tools.log.internal').get_logfile()
end

---Open the haskell-language-server log file
---@return nil
HaskellToolsLog.nvim_open_hls_logfile = function()
  return require('haskell-tools.log.internal').nvim_open_hls_logfile()
end

---Open the haskell-tools.nvim log file.
---@return nil
HaskellToolsLog.nvim_open_logfile = function()
  return require('haskell-tools.log.internal').nvim_open_logfile()
end

---Set the log level
---@param level (string|integer) The log level
---@return nil
---@see vim.log.levels
HaskellToolsLog.set_level = function(level)
  return require('haskell-tools.log.internal').set_level(level)
end

return HaskellToolsLog

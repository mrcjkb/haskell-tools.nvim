---@mod haskell-tools.log haskell-tools Logging
---
---@brief [[
--- The following commands are available:
---
--- * `:Haskell setLogLevel` - Set the haskell-tools.nvim and LSP client log level.
--- * `:Haskell openLog` - Open the haskell-tools.nvim log file.
--- * `:Hls openLog` - Open the haskell-language-server log file.
---@brief ]]

---@class haskell-tools.Log
local Log = {}

---Get the haskell-language-server log file
---@return string filepath
function Log.get_hls_logfile()
  return require('haskell-tools.log.internal').get_hls_logfile()
end

---Get the haskell-tools.nvim log file path.
---@return string filepath
function Log.get_logfile()
  return require('haskell-tools.log.internal').get_logfile()
end

---Open the haskell-language-server log file
---@return nil
function Log.nvim_open_hls_logfile()
  return require('haskell-tools.log.internal').nvim_open_hls_logfile()
end

---Open the haskell-tools.nvim log file.
---@return nil
function Log.nvim_open_logfile()
  return require('haskell-tools.log.internal').nvim_open_logfile()
end

---Set the haskell-tools.nvim and LSP client log level
---@param level (string|integer) The log level
---@return nil
---@see vim.log.levels
function Log.set_level(level)
  return require('haskell-tools.log.internal').set_level(level)
end

return Log

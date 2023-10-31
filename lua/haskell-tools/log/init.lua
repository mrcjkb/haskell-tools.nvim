---@mod haskell-tools.log haskell-tools Logging
---
---@brief [[
--- The following commands are available:
---
--- * `:HtLog` - Open the haskell-tools.nvim log file.
--- * `:HlsLog` - Open the haskell-language-server log file.
--- * `:HtSetLogLevel` - Set the haskell-tools.nvim and LSP client log level.
---@brief ]]

---@class HaskellToolsLog
local HaskellToolsLog = {}

---Get the haskell-language-server log file
---@return string filepath
function HaskellToolsLog.get_hls_logfile()
  return require('haskell-tools.log.internal').get_hls_logfile()
end

---Get the haskell-tools.nvim log file path.
---@return string filepath
function HaskellToolsLog.get_logfile()
  return require('haskell-tools.log.internal').get_logfile()
end

---Open the haskell-language-server log file
---@return nil
function HaskellToolsLog.nvim_open_hls_logfile()
  return require('haskell-tools.log.internal').nvim_open_hls_logfile()
end

---Open the haskell-tools.nvim log file.
---@return nil
function HaskellToolsLog.nvim_open_logfile()
  return require('haskell-tools.log.internal').nvim_open_logfile()
end

---Set the haskell-tools.nvim and LSP client log level
---@param level (string|integer) The log level
---@return nil
---@see vim.log.levels
function HaskellToolsLog.set_level(level)
  return require('haskell-tools.log.internal').set_level(level)
end

local commands = {
  {
    'HtLog',
    function()
      HaskellToolsLog.nvim_open_logfile()
    end,
    {},
  },
  {
    'HlsLog',
    function()
      HaskellToolsLog.nvim_open_hls_logfile()
    end,
    { nargs = 1 },
  },
  {
    'HtSetLogLevel',
    function(tbl)
      local level = vim.fn.expand(tbl.args)
      ---@cast level string
      HaskellToolsLog.set_level(tonumber(level) or level)
    end,
    { nargs = 1 },
  },
}

for _, command in ipairs(commands) do
  vim.api.nvim_create_user_command(unpack(command))
end

return HaskellToolsLog

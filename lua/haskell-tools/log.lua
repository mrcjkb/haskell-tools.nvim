---@mod haskell-tools.log haskell-tools Logging

local uv = vim.uv
  ---@diagnostic disable-next-line: deprecated
  or vim.loop

---@class HaskellToolsLog
local HaskellToolsLog = {
  -- NOTE: These functions are initialised as empty for type checking purposes
  -- and implemented later.
  trace = function(_) end,
  debug = function(_) end,
  info = function(_) end,
  warn = function(_) end,
  error = function(_) end,
}

local LARGE = 1e9

local log_date_format = '%F %H:%M:%S'

local function format_log(arg)
  return vim.inspect(arg, { newline = '' })
end

local HTConfig = require('haskell-tools.config.internal')

local logfilename = HTConfig.tools.log.logfile

---Get the haskell-tools.nvim log file path.
---@return string filepath
function HaskellToolsLog.get_logfile()
  return logfilename
end

---Open the haskell-tools.nvim log file.
function HaskellToolsLog.nvim_open_logfile()
  vim.cmd('e ' .. HaskellToolsLog.get_logfile())
end

local logfile, openerr
--- @private
--- Opens log file. Returns true if file is open, false on error
--- @return boolean
local function open_logfile()
  -- Try to open file only once
  if logfile then
    return true
  end
  if openerr then
    return false
  end

  logfile, openerr = io.open(logfilename, 'a+')
  if not logfile then
    local err_msg = string.format('Failed to open haskell-tools.nvim log file: %s', openerr)
    vim.notify(err_msg, vim.log.levels.ERROR)
    return false
  end

  local log_info = uv.fs_stat(logfilename)
  if log_info and log_info.size > LARGE then
    local warn_msg =
      string.format('haskell-tools.nvim log is large (%d MB): %s', log_info.size / (1000 * 1000), logfilename)
    vim.notify(warn_msg, vim.log.levels.WARN)
  end

  -- Start message for logging
  logfile:write(string.format('[START][%s] haskell-tools.nvim logging initiated\n', os.date(log_date_format)))
  return true
end

local opts = HTConfig.tools.log

local hls_log = HTConfig.hls.logfile

--- Get the haskell-language-server log file
function HaskellToolsLog.get_hls_logfile()
  return hls_log
end

-- Open the haskell-language-server log file
function HaskellToolsLog.nvim_open_hls_logfile()
  vim.cmd('e ' .. HaskellToolsLog.get_hls_logfile())
end

--- Set the log level
--- @param level (string|integer) The log level
--- @see vim.log.levels
function HaskellToolsLog.set_level(level)
  local log_levels = vim.deepcopy(vim.log.levels)
  vim.tbl_add_reverse_lookup(log_levels)
  if type(level) == 'string' then
    HaskellToolsLog.level =
      assert(log_levels[string.upper(opts.level)], string.format('haskell-tools: Invalid log level: %q', level))
  else
    assert(log_levels[opts.level], string.format('haskell-tools: Invalid log level: %d', level))
    HaskellToolsLog.level = level
  end
  vim.lsp.set_log_level(HaskellToolsLog.level)
end

HaskellToolsLog.set_level(opts.level)

for level, levelnr in pairs(vim.log.levels) do
  HaskellToolsLog[level:lower()] = function(...)
    if HaskellToolsLog.level == vim.log.levels.OFF or not open_logfile() then
      return false
    end
    local argc = select('#', ...)
    if levelnr < HaskellToolsLog.level then
      return false
    end
    if argc == 0 then
      return true
    end
    local info = debug.getinfo(2, 'Sl')
    local fileinfo = string.format('%s:%s', info.short_src, info.currentline)
    local parts = {
      table.concat({ level, '|', os.date(log_date_format), '|', fileinfo, '|' }, ' '),
    }
    for i = 1, argc do
      local arg = select(i, ...)
      if arg == nil then
        table.insert(parts, '<nil>')
      elseif type(arg) == 'string' then
        table.insert(parts, arg)
      else
        table.insert(parts, format_log(arg))
      end
    end
    logfile:write(table.concat(parts, ' '), '\n')
    logfile:flush()
  end
end

HaskellToolsLog.debug { 'Config', HTConfig }

return HaskellToolsLog

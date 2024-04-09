---@mod haskell-tools.log.internal haskell-tools Logging (internal)

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- The internal API for use by this plugin's ftplugins
---@brief ]]

local compat = require('haskell-tools.compat')

---@class HaskellToolsLogInternal
local HaskellToolsLogInternal = {
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
function HaskellToolsLogInternal.get_logfile()
  return logfilename
end

---Open the haskell-tools.nvim log file.
function HaskellToolsLogInternal.nvim_open_logfile()
  vim.cmd('e ' .. HaskellToolsLogInternal.get_logfile())
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

  local log_info = compat.uv.fs_stat(logfilename)
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
function HaskellToolsLogInternal.get_hls_logfile()
  return hls_log
end

-- Open the haskell-language-server log file
function HaskellToolsLogInternal.nvim_open_hls_logfile()
  vim.cmd('e ' .. HaskellToolsLogInternal.get_hls_logfile())
end

local log_levels = vim.deepcopy(vim.log.levels)
for levelstr, levelnr in pairs(log_levels) do
  log_levels[levelnr] = levelstr
end

--- Set the log level
--- @param level (string|integer) The log level
--- @see vim.log.levels
function HaskellToolsLogInternal.set_level(level)
  if type(level) == 'string' then
    HaskellToolsLogInternal.level =
      assert(log_levels[string.upper(level)], string.format('haskell-tools: Invalid log level: %q', level))
  else
    assert(log_levels[level], string.format('haskell-tools: Invalid log level: %d', level))
    HaskellToolsLogInternal.level = level
  end
  vim.lsp.set_log_level(HaskellToolsLogInternal.level)
end

HaskellToolsLogInternal.set_level(opts.level)

for level, levelnr in pairs(vim.log.levels) do
  HaskellToolsLogInternal[level:lower()] = function(...)
    if HaskellToolsLogInternal.level == vim.log.levels.OFF or not open_logfile() then
      return false
    end
    local argc = select('#', ...)
    if levelnr < HaskellToolsLogInternal.level then
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

HaskellToolsLogInternal.debug { 'Config', HTConfig }

return HaskellToolsLogInternal

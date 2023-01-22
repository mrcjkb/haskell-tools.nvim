---@mod haskell-tools.log haskell-tools Logging

local ht = require('haskell-tools')

local log = {}

local LARGE = 1e9

local log_date_format = '%F %H:%M:%S'

local function format_log(arg)
  return vim.inspect(arg, { newline = '' })
end

local logpath = vim.fn.stdpath('log')
vim.fn.mkdir(logpath, 'p')
local logfilename = logpath .. '/haskell-toolls.log'

---Get the haskell-tools.nvim log file path.
---@return string filepath
function log.get_logfile()
  return logfilename
end

---Open the haskell-tools.nvim log file.
function log.nvim_open_logfile()
  vim.cmd('e ' .. log.get_logfile())
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

  local log_info = vim.loop.fs_stat(logfilename)
  if log_info and log_info.size > LARGE then
    local warn_msg =
      string.format('haskell-tools.nvim log is large (%d MB): %s', log_info.size / (1000 * 1000), logfilename)
    vim.notify(warn_msg, vim.log.levels.WARN)
  end

  -- Start message for logging
  logfile:write(string.format('[START][%s] haskell-tools.nvim logging initiated\n', os.date(log_date_format)))
  return true
end

---Set up the log module. Called by the haskell-tools setup.
function log.setup()
  local config = ht.config
  if not config then
    error('haskell-tools.setup() has not been called.')
  end
  local opts = config.options.tools.log

  local hls_log = config.hls_log

  --- Get the haskell-language-server log file
  function log.get_hls_logfile()
    return hls_log
  end

  -- Open the haskell-language-server log file
  function log.nvim_open_hls_logfile()
    vim.cmd('e ' .. log.get_hls_logfile())
  end

  --- Set the log level
  --- @param level (string|integer) The log level
  --- @see vim.log.levels
  function log.set_level(level)
    local log_levels = vim.deepcopy(vim.log.levels)
    vim.tbl_add_reverse_lookup(log_levels)
    if type(level) == 'string' then
      log.level = assert(log_levels[opts.level:upper()], string.format('haskell-tools: Invalid log level: %q', level))
    else
      assert(log_levels[opts.level], string.format('haskell-tools: Invalid log level: %d', level))
      log.level = level
    end
    vim.lsp.set_log_level(log.level)
  end

  log.set_level(opts.level)

  for level, levelnr in pairs(vim.log.levels) do
    log[level:lower()] = function(...)
      if log.level == vim.log.levels.OFF or not open_logfile() then
        return false
      end
      local argc = select('#', ...)
      if levelnr < log.level then
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
end

return log

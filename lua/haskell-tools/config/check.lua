---@mod haskell-tools.config.check haskell-tools configuration check

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

---@class haskell-tools.config.Check
local Check = {}

---@param name string Argument namee
---@param value unknown Argument value
---@param validator vim.validate.Validator
---   - (`string|string[]`): Any value that can be returned from |lua-type()| in addition to
---     `'callable'`: `'boolean'`, `'callable'`, `'function'`, `'nil'`, `'number'`, `'string'`, `'table'`,
---     `'thread'`, `'userdata'`.
---   - (`fun(val:any): boolean, string?`) A function that returns a boolean and an optional
---     string message.
---@param optional? boolean Argument is optional (may be omitted)
---@param message? string message when validation fails
---@see vim.validate
---@return boolean is_valid
---@return string|nil error_message
local function validate(name, value, validator, optional, message)
  local ok, err = pcall(vim.validate, name, value, validator, optional, message)
  return ok or false, 'Rocks: Invalid config' .. (err and ': ' .. err or '')
end

---Validates the config.
---@param cfg haskell-tools.Config
---@return boolean is_valid
---@return string|nil error_message
function Check.validate(cfg)
  local ok, err
  local hls = cfg.hls
  ok, err = validate('haskell_tools.hls', hls, 'table')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.hls.auto_attach', hls.auto_attach, { 'boolean', 'function' })
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.hls.capabilities', hls.capabilities, 'table')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.hls.cmd', hls.cmd, { 'table', 'function' })
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.hls.debug', hls.debug, 'boolean')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.hls.default_settings', hls.default_settings, 'table')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.hls.on_attach', hls.on_attach, 'function')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.hls.settings', hls.settings, { 'function', 'table' })
  if not ok then
    return false, err
  end
  local tools = cfg.tools
  ok, err = validate('haskell_tools.tools', tools, 'table')
  if not ok then
    return false, err
  end
  local codeLens = tools.codeLens
  ok, err = validate('haskell_tools.tools.codeLens', codeLens, 'table')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.tools.codeLens.autoRefresh', codeLens.autoRefresh, { 'boolean', 'function' })
  if not ok then
    return false, err
  end
  local hoogle = tools.hoogle
  ok, err = validate('haskell_tools.tools.hoogle', hoogle, 'table')
  if not ok then
    return false, err
  end
  local valid_modes = { 'auto', 'telescope-local', 'telescope-web', 'browser' }
  ok, err = validate('haskell_tools.tools.hoogle.mode', hoogle.mode, function(mode)
    return vim.tbl_contains(valid_modes, mode)
  end, false, 'one of ' .. vim.inspect(valid_modes))
  if not ok then
    return false, err
  end
  local hover = tools.hover
  ok, err = validate('haskell_tools.tools.hover', hover, 'table')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.tools.hover.auto_focus', hover.auto_focus, 'boolean', true)
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.tools.hover.auto_focus', hover.border, 'table', true)
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.tools.hover.stylize_markdown', hover.stylize_markdown, 'boolean')
  if not ok then
    return false, err
  end
  local log = tools.log
  ok, err = validate('haskell_tools.tools.log', log, 'table')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.tools.log.level', log.level, { 'number', 'string' })
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.tools.open_url', tools.open_url, 'function')
  if not ok then
    return false, err
  end
  local repl = tools.repl
  ok, err = validate('haskell_tools.tools.repl', repl, 'table')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.tools.repl.auto_focus', repl.auto_focus, 'boolean', true)
  if not ok then
    return false, err
  end
  local valid_handlers = { 'builtin', 'toggleterm' }
  ok, err = validate('haskell_tools.tools.repl.handler', repl.handler, function(handler)
    return type(handler) == 'function' or vim.tbl_contains(valid_handlers, handler)
  end, false, 'one of ' .. vim.inspect(valid_handlers))
  if not ok then
    return false, err
  end
  local valid_backends = { 'cabal', 'stack' }
  ok, err = validate('haskell_tools.tools.repl.prefer', repl.prefer, function(backend)
    return type(backend) == 'function' or vim.tbl_contains(valid_backends, backend)
  end, false, 'one of ' .. vim.inspect(valid_backends))
  if not ok then
    return false, err
  end
  local builtin = repl.builtin
  ok, err = validate('haskell_tools.tools.repl.builtin', builtin, 'table')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.tools.repl.builtin.create_repl_window', builtin.create_repl_window, 'function')
  if not ok then
    return false, err
  end
  local tags = tools.tags
  ok, err = validate('haskell_tools.tools.tags', tags, 'table')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.tools.tags.enable', tags.enable, { 'boolean', 'function' })
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.tools.tags.package_events', tags.package_events, 'table')
  if not ok then
    return false, err
  end
  local dap = cfg.dap
  ok, err = validate('haskell_tools.dap', dap, 'table')
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.dap.cmd', dap.cmd, { 'function', 'table' })
  if not ok then
    return false, err
  end
  ok, err = validate('haskell_tools.dap.logFile', dap.logFile, 'string')
  if not ok then
    return false, err
  end
  local valid_dap_log_levels = { 'Debug', 'Info', 'Warning', 'Error' }
  ok, err = validate('haskell_tools.dap.logLevel', dap.logLevel, function(level)
    return type(level) == 'string' and vim.tbl_contains(valid_dap_log_levels, level)
  end, false, 'one of ' .. vim.inspect(valid_backends))
  if not ok then
    return false, err
  end
  local auto_discover = dap.auto_discover
  ok, err = validate('haskell_tools.dap.auto_discover', auto_discover, { 'boolean', 'table' }, false)
  if not ok then
    return false, err
  end
  if type(auto_discover) == 'table' then
    ---@cast auto_discover haskell-tools.dap.AddConfigOpts
    ok, err = validate('haskell_tools.dap.auto_discover.autodetect', auto_discover.autodetect, 'boolean')
    if not ok then
      return false, err
    end
    ok, err =
      validate('haskell_tools.dap.auto_discover.settings_file_pattern', auto_discover.settings_file_pattern, 'string')
    if not ok then
      return false, err
    end
  end
  return true
end

---Recursively check a table for unrecognized keys,
---using a default table as a reference
---@param tbl table
---@param default_tbl table
---@param ignored_keys string[]
---@return string[]
function Check.get_unrecognized_keys(tbl, default_tbl, ignored_keys)
  local unrecognized_keys = {}
  for k, _ in pairs(tbl) do
    unrecognized_keys[k] = true
  end
  for k, _ in pairs(default_tbl) do
    unrecognized_keys[k] = false
  end
  local ret = {}
  for k, _ in pairs(unrecognized_keys) do
    if unrecognized_keys[k] then
      ret[k] = k
    end
    if type(default_tbl[k]) == 'table' and tbl[k] then
      for _, subk in pairs(Check.get_unrecognized_keys(tbl[k], default_tbl[k], {})) do
        local key = k .. '.' .. subk
        ret[key] = key
      end
    end
  end
  for k, _ in pairs(ret) do
    for _, ignore in pairs(ignored_keys) do
      if vim.startswith(k, ignore) then
        ret[k] = nil
      end
    end
  end
  return vim.tbl_keys(ret)
end

return Check

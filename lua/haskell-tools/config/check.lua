---@mod haskell-tools.config.check haskell-tools configuration check

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

---@class HtConfigCheck
local HtConfigCheck = {}

---@param path string
---@param msg string|nil
---@return string
local function mk_error_msg(path, msg)
  return msg and path .. '.' .. msg or path
end

---@param path string The config path
---@param tbl table The table to validate
---@see vim.validate
---@return boolean is_valid
---@return string|nil error_message
local function validate(path, tbl)
  local prefix = 'Invalid config: '
  local ok, err = pcall(vim.validate, tbl)
  return ok or false, prefix .. mk_error_msg(path, err)
end

---Validates the config.
---@param cfg HTConfig
---@return boolean is_valid
---@return string|nil error_message
function HtConfigCheck.validate(cfg)
  local ok, err
  local hls = cfg.hls
  ok, err = validate('hls', {
    auto_attach = { hls.auto_attach, { 'boolean', 'function' } },
    capabilities = { hls.capabilities, 'table' },
    cmd = { hls.cmd, { 'table', 'function' } },
    debug = { hls.debug, 'boolean' },
    default_settings = { hls.default_settings, 'table' },
    on_attach = { hls.on_attach, 'function' },
    settings = { hls.settings, { 'function', 'table' } },
  })
  if not ok then
    return false, err
  end
  local tools = cfg.tools
  local codeLens = tools.codeLens
  ok, err = validate('tools.codeLens', {
    autoRefresh = { codeLens.autoRefresh, { 'boolean', 'function' } },
  })
  if not ok then
    return false, err
  end
  local definition = tools.definition
  ok, err = validate('tools.definition', {
    hoogle_signature_fallback = { definition.hoogle_signature_fallback, { 'boolean', 'function' } },
  })
  if not ok then
    return false, err
  end
  local hoogle = tools.hoogle
  local valid_modes = { 'auto', 'telescope-local', 'telescope-web', 'browser' }
  ok, err = validate('tools.hoogle', {
    mode = {
      hoogle.mode,
      function(mode)
        return vim.tbl_contains(valid_modes, mode)
      end,
      'one of ' .. vim.inspect(valid_modes),
    },
  })
  if not ok then
    return false, err
  end
  local hover = tools.hover
  ok, err = validate('tools.hover', {
    auto_focus = { hover.auto_focus, 'boolean', true },
    border = { hover.border, 'table', true },
    enable = { hover.enable, { 'boolean', 'function' } },
    stylize_markdown = { hover.stylize_markdown, 'boolean' },
  })
  if not ok then
    return false, err
  end
  local log = tools.log
  ok, err = validate('tools.log', {
    log = { log.level, { 'number', 'string' } },
  })
  if not ok then
    return false, err
  end
  local repl = tools.repl
  local valid_handlers = { 'builtin', 'toggleterm' }
  local valid_backends = { 'cabal', 'stack' }
  ok, err = validate('tools.repl', {
    auto_focus = { repl.auto_focus, 'boolean', true },
    builtin = { repl.builtin, 'table' },
    handler = {
      repl.handler,
      function(handler)
        return type(handler) == 'function' or vim.tbl_contains(valid_handlers, handler)
      end,
      'one of ' .. vim.inspect(valid_handlers),
    },
    prefer = {
      repl.prefer,
      function(backend)
        return type(backend) == 'function' or vim.tbl_contains(valid_backends, backend)
      end,
      'one of ' .. vim.inspect(valid_backends),
    },
  })
  if not ok then
    return false, err
  end
  local builtin = repl.builtin
  ok, err = validate('tools.repl.builtin', {
    create_repl_window = { builtin.create_repl_window, 'function' },
  })
  if not ok then
    return false, err
  end
  local tags = tools.tags
  ok, err = validate('tools.tags', {
    enable = { tags.enable, { 'boolean', 'function' } },
    package_events = { tags.package_events, 'table' },
  })
  if not ok then
    return false, err
  end
  return true
end

return HtConfigCheck

---@mod haskell-tools.lsp haskell-language-server LSP client tools

local HTConfig = require('haskell-tools.config.internal')
local log = require('haskell-tools.log.internal')
local Types = require('haskell-tools.types.internal')

---@brief [[
--- The following commands are available if an LSP client is active:
---
--- * `:Haskell hls evalAll` - Evaluate all code snippets in comments.
--- * `:Haskell hls stop` - Stop the haskell-tools LSP client for the current buffer.
--- * `:Haskell hls restart` - Restart the haskell-tools LSP client for the current buffer.
---
--- The following commands are available if no LSP client is active:
---
--- * `:Haskell hls start` - Start the haskell-tools LSP client for the current buffer.
---@brief ]]

---To minimise the risk of this occurring, we attempt to shut down hls cleanly before exiting neovim.
---@param client vim.lsp.Client The LSP client
---@param bufnr number The buffer number
---@return nil
local function ensure_clean_exit_on_quit(client, bufnr)
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('haskell-tools-hls-clean-exit-' .. tostring(client.id), { clear = true }),
    callback = function()
      log.debug('Stopping LSP client...')
      client:stop(false)
    end,
    buffer = bufnr,
  })
end

---@class haskell-tools.load_hls_settings.Opts
---@field settings_file_pattern string|nil File name or pattern to search for. Defaults to 'hls.json'

log.debug('Setting up the LSP client...')
local hls_opts = HTConfig.hls

---@type table<string, lsp.Handler>
local handlers = {}

local tools_opts = HTConfig.tools

---@class haskell-tools.Hls
local Hls = {}
---Search the project root for a haskell-language-server settings JSON file and load it to a Lua table.
---Falls back to the `hls.default_settings` if no file is found or file cannot be read or decoded.
---@param project_root string|nil The project root
---@param opts haskell-tools.load_hls_settings.Opts|nil
---@return table hls_settings
---@see https://haskell-language-server.readthedocs.io/en/latest/configuration.html
Hls.load_hls_settings = function(project_root, opts)
  local default_settings = HTConfig.hls.default_settings
  if not project_root then
    return default_settings
  end
  local default_opts = { settings_file_pattern = 'hls.json' }
  opts = vim.tbl_deep_extend('force', {}, default_opts, opts or {})
  local results = vim.fn.glob(vim.fs.joinpath(project_root, opts.settings_file_pattern), true, true)
  if #results == 0 then
    log.info(opts.settings_file_pattern .. ' not found in project root ' .. project_root)
    return default_settings
  end
  local settings_json = results[1]
  local OS = require('haskell-tools.os')
  local content = OS.read_file(settings_json)
  local success, settings = pcall(vim.json.decode, content)
  if not success then
    local msg = 'Could not decode ' .. settings_json .. '. Falling back to default settings.'
    log.warn { msg, error }
    vim.schedule(function()
      vim.notify('haskell-tools.lsp: ' .. msg, vim.log.levels.WARN)
    end)
    return default_settings
  end
  log.debug { 'hls settings', settings }
  return settings or default_settings
end

---@param default_handler lsp.Handler
---@return lsp.Handler
local function suppress_method_not_found_error(default_handler)
  return function(err, ...)
    if
      err
      and err.code == vim.lsp.protocol.ErrorCodes.MethodNotFound
      and err.message:match('Plugins installed for this method, but not available to handle this request') ~= nil
    then
      return
    end
    return default_handler(err, ...)
  end
end

---Start or attach the LSP client.
---Fails silently if the buffer's filetype is not one of the filetypes specified in the config.
---@param bufnr number|nil The buffer number (optional), defaults to the current buffer
---@return number|nil client_id The LSP client ID
Hls.start = function(bufnr)
  local ht = require('haskell-tools')
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  if not file or #file == 0 then
    local msg = 'Could not determine the name of buffer ' .. bufnr .. '.'
    log.debug('lsp.start: ' .. msg)
    return
  end
  local HtProjectHelpers = require('haskell-tools.project.helpers')

  if HtProjectHelpers.is_cabal_file(bufnr) then
    -- HACK: hls spams error messages in cabal files if the user enables features like inlay hints
    -- See https://github.com/haskell/haskell-language-server/issues/4550#issuecomment-4239601683
    for k, default_handler in pairs(vim.lsp.handlers) do
      handlers[k] = suppress_method_not_found_error(default_handler)
    end
  end

  local LspHelpers = require('haskell-tools.lsp.helpers')
  local project_root = ht.project.root_dir(file)
  local hls_settings = type(hls_opts.settings) == 'function' and hls_opts.settings(project_root) or hls_opts.settings

  local cmd = LspHelpers.get_hls_cmd()
  local hls_bin = cmd[1]
  if vim.fn.executable(hls_bin) == 0 then
    log.warn('Executable ' .. hls_bin .. ' not found.')
  end

  local lsp_start_opts = {
    name = LspHelpers.haskell_client_name,
    cmd = Types.evaluate(cmd),
    root_dir = project_root,
    filetypes = { 'haskell', 'lhaskell', 'cabal', 'cabalproject' },
    capabilities = hls_opts.capabilities,
    handlers = handlers,
    settings = hls_settings,
    on_attach = function(client_id, buf)
      log.debug('LSP attach')
      local ok, err = pcall(hls_opts.on_attach, client_id, buf, ht)
      if not ok then
        ---@cast err string
        log.error { 'on_attach failed', err }
        vim.schedule(function()
          vim.notify('haskell-tools.lsp: Error in hls.on_attach: ' .. err)
        end)
      end
      local code_lens_opts = tools_opts.codeLens or {}
      if Types.evaluate(code_lens_opts.autoRefresh) then
        vim.lsp.codelens.enable(true, { bufnr = buf })
      end
    end,
    on_init = function(client, _)
      ensure_clean_exit_on_quit(client, bufnr)
    end,
  }
  local hs_config_name = lsp_start_opts.name
  -- Force resolution of `vim.lsp.config['*']` for `hs_config_name`,
  -- in case it has not been set
  -- (This does not overwrite any existing configs).
  vim.lsp.config(hs_config_name, {})
  local hls_config = vim.lsp.config[hs_config_name] or {}
  if hls_config.settings then
    -- Ensure vim.lsp.config settings get merged with server.default_settings.
    hls_config.default_settings = hls_config.settings
    hls_config.settings = nil
  end
  local client_config = vim.tbl_deep_extend('force', {}, lsp_start_opts, hls_config)
  local client_id = vim.lsp.start(client_config)
  return client_id
end

---Evaluate all code snippets in comments.
---@param bufnr number|nil Defaults to the current buffer.
---@return nil
Hls.buf_eval_all = function(bufnr)
  local eval = require('haskell-tools.lsp.eval')
  return eval.all(bufnr)
end

return Hls

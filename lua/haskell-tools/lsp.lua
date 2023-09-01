---@mod haskell-tools.lsp haskell-language-server LSP client tools

local HTConfig = require('haskell-tools.config.internal')
local log = require('haskell-tools.log.internal')
local Types = require('haskell-tools.types.internal')
local uv = vim.uv
  ---@diagnostic disable-next-line: deprecated
  or vim.loop

---@brief [[
--- The following commands are available:
---
--- * `:HlsStart` - Start the LSP client.
--- * `:HlsStop` - Stop the LSP client.
--- * `:HlsRestart` - Restart the LSP client.
---@brief ]]

---To minimise the risk of this occurring, we attempt to shut down hls cleanly before exiting neovim.
---@param client lsp.Client The LSP client
---@param bufnr number The buffer number
---@return nil
local function ensure_clean_exit_on_quit(client, bufnr)
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('haskell-tools-hls-clean-exit-' .. tostring(client.id), { clear = true }),
    callback = function()
      log.debug('Stopping LSP client...')
      vim.lsp.stop_client(client, false)
    end,
    buffer = bufnr,
  })
end

---A workaround for #48:
---Some plugins that add LSP client capabilities which are not built-in to neovim
---(like nvim-ufo and nvim-lsp-selection-range) cause error messages, because
---haskell-language-server falsly advertises those server_capabilities for cabal files.
---@param client lsp.Client
---@return nil
local function fix_cabal_client(client)
  local LspHelpers = require('haskell-tools.lsp.helpers')
  if client.name == LspHelpers.cabal_client_name and client.server_capabilities then
    client.server_capabilities = vim.tbl_extend('force', client.server_capabilities, {
      foldingRangeProvider = false,
      selectionRangeProvider = false,
      documentHighlightProvider = false,
    })
  end
end

---@class LoadHlsSettingsOpts
---@field settings_file_pattern string|nil File name or pattern to search for. Defaults to 'hls.json'

log.debug('Setting up the LSP client...')
local hls_opts = HTConfig.hls
local handlers = {}

local tools_opts = HTConfig.tools
local definition_opts = tools_opts.definition or {}

if Types.evaluate(definition_opts.hoogle_signature_fallback) then
  local lsp_definition = require('haskell-tools.lsp.definition')
  log.debug('Wrapping vim.lsp.buf.definition with Hoogle signature fallback.')
  handlers['textDocument/definition'] = lsp_definition.mk_hoogle_fallback_definition_handler(definition_opts)
end
local hover_opts = tools_opts.hover
if Types.evaluate(hover_opts.enable) then
  local hover = require('haskell-tools.lsp.hover')
  handlers['textDocument/hover'] = hover.on_hover
end

---@class HlsTools
local HlsTools = {}
---Search the project root for a haskell-language-server settings JSON file and load it to a Lua table.
---Falls back to the `hls.default_settings` if no file is found or file cannot be read or decoded.
---@param project_root string|nil The project root
---@param opts LoadHlsSettingsOpts|nil
---@return table hls_settings
---@see https://haskell-language-server.readthedocs.io/en/latest/configuration.html
HlsTools.load_hls_settings = function(project_root, opts)
  local default_settings = HTConfig.hls.default_settings
  if not project_root then
    return default_settings
  end
  local default_opts = { settings_file_pattern = 'hls.json' }
  opts = vim.tbl_deep_extend('force', {}, default_opts, opts or {})
  local deps = require('haskell-tools.deps')
  local Path = deps.require_plenary('plenary.path')
  local results = vim.fn.glob(Path:new(project_root, opts.settings_file_pattern).filename, true, true)
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
    vim.notify('haskell-tools.lsp: ' .. msg, vim.log.levels.WARN)
    return default_settings
  end
  log.debug { 'hls settings', settings }
  return settings or default_settings
end

---Start or attach the LSP client.
---Fails silently if the buffer's filetype is not one of the filetypes specified in the config.
---@param bufnr number|nil The buffer number (optional), defaults to the current buffer
---@return number|nil client_id The LSP client ID
HlsTools.start = function(bufnr)
  local ht = require('haskell-tools')
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  if not file or #file == 0 then
    local msg = 'Could not determine the name of buffer ' .. bufnr .. '.'
    log.error('lsp.start: ' .. msg)
    vim.notify('haskell-tools: ' .. msg, vim.log.levels.ERROR)
    return
  end
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  local is_cabal = HtProjectHelpers.is_cabal_file(bufnr)
  local project_root = ht.project.root_dir(file)
  local hls_settings = type(hls_opts.settings) == 'function' and hls_opts.settings(project_root) or hls_opts.settings
  local LspHelpers = require('haskell-tools.lsp.helpers')
  local cmd = LspHelpers.get_hls_cmd()
  local hls_bin = cmd[1]
  if vim.fn.executable(hls_bin) == 0 then
    log.warn('Executable ' .. hls_bin .. ' not found.')
  end

  local lsp_start_opts = {
    name = is_cabal and LspHelpers.cabal_client_name or LspHelpers.haskell_client_name,
    cmd = Types.evaluate(cmd),
    root_dir = project_root,
    capabilities = hls_opts.capabilities,
    handlers = handlers,
    settings = hls_settings,
    on_attach = function(client_id, buf)
      log.debug('LSP attach')
      local ok, err = pcall(hls_opts.on_attach, client_id, buf, ht)
      if not ok then
        ---@cast err string
        log.error { 'on_attach failed', err }
        vim.notify('haskell-tools.lsp: Error in hls.on_attach: ' .. err)
      end
      local function buf_refresh_codeLens()
        vim.schedule(function()
          for _, client in pairs(LspHelpers.get_active_ht_clients(bufnr)) do
            if client.server_capabilities.codeLensProvider then
              vim.lsp.codelens.refresh()
              return
            end
          end
        end)
      end
      local code_lens_opts = tools_opts.codeLens or {}
      if Types.evaluate(code_lens_opts.autoRefresh) then
        vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufWritePost', 'TextChanged' }, {
          group = vim.api.nvim_create_augroup('haskell-tools-code-lens', {}),
          callback = buf_refresh_codeLens,
          buffer = buf,
        })
        buf_refresh_codeLens()
      end
    end,
    on_init = function(client, _)
      ensure_clean_exit_on_quit(client, bufnr)
      fix_cabal_client(client)
    end,
  }
  log.debug('LSP start options: lsp_start_opts')
  local client_id = vim.lsp.start(lsp_start_opts)
  return client_id
end

---Stop the LSP client.
---@param bufnr number|nil The buffer number (optional), defaults to the current buffer
---@return table[] clients A list of clients that will be stopped
HlsTools.stop = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local LspHelpers = require('haskell-tools.lsp.helpers')
  local clients = LspHelpers.get_active_ht_clients(bufnr)
  vim.lsp.stop_client(clients)
  return clients
end

---Restart the LSP client.
---Fails silently if the buffer's filetype is not one of the filetypes specified in the config.
---@param bufnr number|nil The buffer number (optional), defaults to the current buffer
---@return number|nil client_id The LSP client ID after restart
HlsTools.restart = function(bufnr)
  local lsp = require('haskell-tools').lsp
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = lsp.stop(bufnr)
  local timer, err_name, err_msg = uv.new_timer()
  if not timer then
    log.error { 'Could not create timer', err_name, err_msg }
    return
  end
  timer:start(500, 500, function()
    for _, client in ipairs(clients) do
      if client:is_stopped() then
        vim.schedule(function()
          lsp.start(bufnr)
        end)
      end
    end
  end)
end

---Evaluate all code snippets in comments.
---@param bufnr number|nil Defaults to the current buffer.
---@return nil
HlsTools.buf_eval_all = function(bufnr)
  local eval = require('haskell-tools.lsp.eval')
  return eval.all(bufnr)
end

local commands = {
  {
    'HlsStart',
    function()
      HlsTools.start()
    end,
    {},
  },
  {
    'HlsStop',
    function()
      HlsTools.stop()
    end,
    {},
  },
  {
    'HlsRestart',
    function()
      HlsTools.restart()
    end,
    {},
  },
}

for _, command in ipairs(commands) do
  vim.api.nvim_create_user_command(unpack(command))
end

return HlsTools

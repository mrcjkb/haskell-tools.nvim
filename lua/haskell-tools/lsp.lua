---@mod haskell-tools.lsp haskell-tools LSP client setup

local ht = require('haskell-tools')
local ht_util = require('haskell-tools.util')
local deps = require('haskell-tools.deps')
local Path = deps.require_plenary('plenary.path')
local lsp_util = require('haskell-tools.lsp.util')

local lsp = {}

---@brief [[
--- The following commands are available:
---
--- * `:HlsStart` - Start the LSP client.
--- * `:HlsStop` - Stop the LSP client.
--- * `:HlsRestart` - Restart the LSP client.
---@brief ]]

local commands = {
  {
    'HlsStart',
    function()
      lsp.start()
    end,
    {},
  },
  {
    'HlsStop',
    function()
      lsp.stop()
    end,
    {},
  },
  {
    'HlsRestart',
    function()
      lsp.restart()
    end,
    {},
  },
}

---GHC can leave behind corrupted files if it does not exit cleanly.
---(https://gitlab.haskell.org/ghc/ghc/-/issues/14533)
---To minimise the risk of this occurring, we attempt to shut down hls cleanly before exiting neovim.
---@param client number The LSP client
---@param bufnr number The buffer number
---@return nil
local function ensure_clean_exit_on_quit(client, bufnr)
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('haskell-tools-hls-clean-exit', { clear = true }),
    callback = function()
      ht.log.debug('Stopping LSP client...')
      vim.lsp.stop_client(client, false)
    end,
    buffer = bufnr,
  })
end

---@class LoadHlsSettingsOpts
---@field settings_file_pattern string|nil File name or pattern to search for. Defaults to 'hls.json'

---Search the project root for a haskell-language-server settings JSON file and load it to a Lua table.
---Falls back to the `hls.default_settings` if no file is found or file cannot be read or decoded.
---@param project_root string|nil The project root
---@param opts LoadHlsSettingsOpts|nil
---@return table hls_settings
---@see https://haskell-language-server.readthedocs.io/en/latest/configuration.html
function lsp.load_hls_settings(project_root, opts)
  local default_settings = ht.config.options.hls.default_settings
  if not project_root then
    return default_settings
  end
  local default_opts = { settings_file_pattern = 'hls.json' }
  opts = vim.tbl_deep_extend('force', {}, default_opts, opts or {})
  local results = vim.fn.glob(Path:new(project_root, opts.settings_file_pattern).filename, true, true)
  if #results == 0 then
    ht.log.info(opts.settings_file_pattern .. ' not found in project root ' .. project_root)
    return default_settings
  end
  local settings_json = results[1]
  local content = ht_util.read_file(settings_json)
  local success, settings = pcall(vim.json.decode, content)
  if not success then
    local msg = 'Could not decode ' .. settings_json .. '. Falling back to default settings.'
    ht.log.warn { msg, error }
    vim.notify('haskell-tools: ' .. msg, vim.log.levels.WARN)
    return default_settings
  end
  ht.log.debug { 'hls settings', settings }
  return settings or default_settings
end

---Setup the LSP client. Called by the haskell-tools setup.
---@return nil
function lsp.setup()
  ht.log.debug('Setting up the LSP client...')
  local opts = ht.config.options
  local hls_opts = assert(opts.hls, 'haskell-tools: hls options not set.')
  local cmd = assert(hls_opts.cmd, 'haskell-tools: hls cmd not set.')
  assert(#cmd > 1, 'haskell-tools: hls cmd table is empty.')
  local hls_cmd = cmd[1]
  if vim.fn.executable(hls_cmd) == 0 then
    ht.log.warn('Command ' .. hls_cmd .. ' not found in PATH.')
    return
  end

  local handlers = {}

  local tools_opts = assert(opts.tools, 'haskell-tools: tools options not set.')
  local defintion_opts = tools_opts.definition or {}

  if defintion_opts.hoogle_signature_fallback == true then
    local lsp_definition = require('haskell-tools.lsp.definition')
    ht.log.debug('Wrapping vim.lsp.buf.definition with Hoogle signature fallback.')
    handlers['textDocument/definition'] = lsp_definition.mk_hoogle_fallback_definition_handler(defintion_opts)
  end
  local hover_opts = tools_opts.hover or {}
  if not hover_opts.disable then
    local hover = require('haskell-tools.lsp.hover')
    handlers['textDocument/hover'] = hover.on_hover
  end

  local filetypes = hls_opts.filetypes or {}

  ---Start or attach the LSP client.
  ---Fails silently if the buffer's filetype is not one of the filetypes specified in the config.
  ---@param bufnr number|nil The buffer number (optional), defaults to the current buffer
  ---@return number|nil client_id The LSP client ID
  function lsp.start(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(bufnr)
    if not file or #file == 0 then
      local msg = 'Could not determine the name of buffer ' .. bufnr .. '.'
      ht.log.error('lsp.start: ' .. msg)
      vim.notify('haskell-tools: ' .. msg, vim.log.levels.ERROR)
      return
    end
    local filetype = vim.bo[bufnr].filetype
    if #filetypes > 0 and not vim.tbl_contains(filetypes, filetype) then
      local msg = 'File type ' .. filetype .. ' not one of ' .. vim.inspect(filetypes)
      ht.log.error('lsp.start: ' .. msg)
      vim.notify('haskell-tools: ' .. msg, vim.log.levels.ERROR)
      return
    end
    local project_root = ht.project.root_dir(file)
    local hls_settings = type(hls_opts.settings) == 'function' and hls_opts.settings(project_root) or hls_opts.settings
    local client_id = vim.lsp.start {
      name = lsp_util.client_name,
      cmd = cmd,
      root_dir = project_root,
      capabilities = hls_opts.capabilities,
      handlers = handlers,
      settings = hls_settings,
      on_attach = function(client_id, buf)
        ht.log.debug('LSP attach')
        hls_opts.on_attach(client_id, buf)
        local function buf_refresh_codeLens()
          vim.schedule(function()
            for _, client in pairs(lsp_util.get_active_ht_clients(bufnr)) do
              if client.server_capabilities.codeLensProvider then
                vim.lsp.codelens.refresh()
                return
              end
            end
          end)
        end
        local codeLensOpts = tools_opts.codeLens or {}
        if codeLensOpts.autoRefresh then
          vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufWritePost', 'TextChanged' }, {
            group = vim.api.nvim_create_augroup('haskell-tools-code-lens', {}),
            callback = buf_refresh_codeLens,
            buffer = buf,
          })
          buf_refresh_codeLens()
        end
      end,
    }
    if client_id then
      ensure_clean_exit_on_quit(client_id, bufnr)
    end
    return client_id
  end

  ---Stop the LSP client.
  ---@param bufnr number|nil The buffer number (optional), defaults to the current buffer
  ---@return table[] clients A list of clients that will be stopped
  function lsp.stop(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local clients = lsp_util.get_active_ht_clients(bufnr)
    for _, client in ipairs(clients) do
      client:stop()
    end
    return clients
  end

  ---Restart the LSP client.
  ---Fails silently if the buffer's filetype is not one of the filetypes specified in the config.
  ---@param bufnr number|nil The buffer number (optional), defaults to the current buffer
  ---@return number|nil client_id The LSP client ID after restart
  function lsp.restart(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local clients = lsp.stop(bufnr)
    local timer = vim.loop.new_timer()
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

  if #filetypes > 0 then
    local pattern = table.concat(filetypes, ',')
    ht.log.info('Setting up haskell-tools client autocmd for ' .. pattern)
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('haskell-tools-lsp', {}),
      pattern = table.concat(filetypes, ','),
      callback = function(opt)
        lsp.start(opt.buf)
      end,
      desc = 'Start haskell-language-server or attach to an existing LSP client.',
    })
  end

  for _, command in ipairs(commands) do
    vim.api.nvim_create_user_command(unpack(command))
  end

  ---Evaluate all code snippets in comments.
  ---@param bufnr number|nil Defaults to the current buffer.
  ---@return nil
  function lsp.buf_eval_all(bufnr)
    local eval = require('haskell-tools.lsp.eval')
    return eval.all(bufnr)
  end
end

return lsp

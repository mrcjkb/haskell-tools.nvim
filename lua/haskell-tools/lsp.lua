local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')

local M = {}

-- GHC can leave behind corrupted files if it does not exit cleanly.
-- (https://gitlab.haskell.org/ghc/ghc/-/issues/14533)
-- To minimise the risk of this occurring, we attempt to shut down hls clnly before exiting neovim.
-- @param client the LSP client
local function ensure_clean_exit_on_quit(client, bufnr)
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('haskell-tools-hls-clean-exit', { clear = true} ),
    callback = function()
      vim.lsp.stop_client(client, false)
    end,
    buffer = bufnr,
  })
end

local function setup_codeLens(opts, bufnr)
  if opts.autoRefresh then
    vim.api.nvim_create_autocmd({'CursorHold', 'InsertLeave', 'BufWritePost', 'TextChanged'}, {
      group = vim.api.nvim_create_augroup('haskell-tools-code-lens', {}),
      callback = vim.lsp.codelens.refresh,
      buffer = bufnr
    })
    vim.lsp.codelens.refresh()
  end
end

local function setup_lsp()
  local opts = ht.config.options
  local hls_opts = opts.hls
  local orig_on_attach = hls_opts.on_attach
  local function on_attach(client, bufnr)
    orig_on_attach(client, bufnr)
    ensure_clean_exit_on_quit(client, bufnr)
    setup_codeLens(opts.tools.codeLens, bufnr)
  end
  hls_opts.on_attach = on_attach
  local lspconfig = deps.require_or_err('lspconfig', 'neovim/nvim-lspconfig')
  lspconfig.hls.setup(hls_opts)
end

local function setup_definition()
  local opts = ht.config.options.tools.definition
  require('haskell-tools.lsp.definition').setup(opts or {})
end

local function setup_hover()
  local opts = ht.config.options.tools.hover
  if opts.disable then
    return
  end
  require('haskell-tools.lsp.hover').setup()
end

function M.setup()
  setup_lsp()
  setup_definition()
  setup_hover()
end

return M

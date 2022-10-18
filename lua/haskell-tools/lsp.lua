local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')

local M = {}

-- GHC can leave behind corrupted files if it does not exit cleanly.
-- (https://gitlab.haskell.org/ghc/ghc/-/issues/14533)
-- To minimise the risk of this occurring, we attempt to shut down hls clnly before exiting neovim.
-- @param client the LSP client
local function ensure_clean_exit_on_quit(client)
  vim.api.nvim_create_augroup('VimLeavePre', {
    group = vim.api.nvim_create_augroup('haskell-tools-hls-clean-exit', { clear = true} ),
    callback = function()
      vim.lsp.stop_client(client, false)
    end
  })
end

local function setup_lsp()
  local config = ht.config.options.hls
  local function on_attach(client, bufnr)
    M.options.hls.on_attach(client, bufnr)
    ensure_clean_exit_on_quit(client)
  end
  config.on_attach = on_attach
  deps.lspconfig.hls.setup(ht.config.options.hls)
end

function M.setup()
  setup_lsp()
end

return M

local M = {
  config = nil,
  lsp = nil,
}

function M.setup(opts)
  local config = require('haskell-tools.config')
  M.config = config
  local lsp = require('haskell-tools.lsp')
  M.lsp = lsp

  config.setup(opts)
  lsp.setup()
end

return M

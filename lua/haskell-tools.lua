local M = {
  config = nil,
  lsp = nil,
}

M.config = require('haskell-tools.config')
M.lsp = require('haskell-tools.lsp')

return M

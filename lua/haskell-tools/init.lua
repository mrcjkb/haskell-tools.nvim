local M = {
  config = nil,
  lsp = nil,
  hoogle = nil,
}

function M.setup(opts)
  local config = require('haskell-tools.config')
  M.config = config
  local lsp = require('haskell-tools.lsp')
  M.lsp = lsp
  local hoogle = require('haskell-tools.hoogle')
  M.hoogle = hoogle

  config.setup(opts)
  lsp.setup()
  hoogle.setup()
end

return M

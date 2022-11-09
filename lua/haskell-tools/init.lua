local M = {
  config = nil,
  lsp = nil,
  hoogle = nil,
  repl = nil,
}

function M.setup(opts)
  local config = require('haskell-tools.config')
  M.config = config
  local lsp = require('haskell-tools.lsp')
  M.lsp = lsp
  local hoogle = require('haskell-tools.hoogle')
  M.hoogle = hoogle
  local repl = require('haskell-tools.repl')
  M.repl = repl

  config.setup(opts)
  lsp.setup()
  hoogle.setup()
  repl.setup()
end

return M

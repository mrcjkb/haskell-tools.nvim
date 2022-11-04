local M = {
  config = nil,
  lsp = nil,
  dap = nil,
  hoogle = nil,
}

function M.setup(opts)
  local config = require('haskell-tools.config')
  M.config = config
  local lsp = require('haskell-tools.lsp')
  M.lsp = lsp
  local dap = require('haskell-tools.dap')
  M.dap = dap
  local hoogle = require('haskell-tools.hoogle')
  M.hoogle = hoogle

  config.setup(opts)
  lsp.setup()
  dap.setup()
  hoogle.setup()
end

return M

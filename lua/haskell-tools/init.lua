local ht = require('haskell-tools')

local M = {}

function M.setup(opts)
  ht.config.setup(opts)
  ht.lsp.setup()
end

return M

local ht = require('haskell-tools')

local M = {}

local function setup_lsp()
  ht.deps.lspconfig.hls.setup(ht.config.options.hls)
end

function M.setup()
  setup_lsp()
end

return M

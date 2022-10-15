local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')

local M = {}

local function setup_lsp()
  deps.lspconfig.hls.setup(ht.config.options.hls)
end

function M.setup()
  setup_lsp()
end

return M

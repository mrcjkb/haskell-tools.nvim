local ht = require('haskell-tools')
-- local stub = require('luassert.stub')

describe('LSP client API', function()
  ht.setup {}
  it('LSP client is available after setup.', function()
    assert(ht.lsp ~= nil)
  end)
  it('Can spin up haskell-language-server for Cabal project.', function()
    --- TODO: Figure out how to add tests for this
    print('TODO')
  end)
end)

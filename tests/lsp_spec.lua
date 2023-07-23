local ht = require('haskell-tools')

describe('LSP client API', function()
  ht.setup()
  it('LSP client is available after setup.', function()
    assert(ht.lsp ~= nil)
  end)
  it('LSP client functions are available after setup.', function()
    assert(ht.lsp.start ~= nil)
    assert(ht.lsp.stop ~= nil)
    assert(ht.lsp.restart ~= nil)
  end)
  it('Can load haskell-language-server config', function()
    local settings = ht.lsp.load_hls_settings(os.getenv('TEST_CWD'))
    assert.not_same(ht.config.options.hls.default_settings, settings)
  end)
  it('Falls back to default haskell-language-server config if none is found', function()
    local settings = ht.lsp.load_hls_settings(os.getenv('TEST_CWD'), { settings_file_pattern = 'bla.json' })
    assert.same(ht.config.options.hls.default_settings, settings)
  end)
  local hls_bin = ht.config.options.hls.cmd[1]
  if vim.fn.executable(hls_bin) ~= 0 then
    it('Can spin up haskell-language-server for Cabal project.', function()
      --- TODO: Figure out how to add tests for this
      print('TODO')
    end)
  end
end)

describe('LSP client API', function()
  local config = require('haskell-tools.config')
  local ht = require('haskell-tools')
  it('Can load haskell-language-server config', function()
    local settings = ht.lsp.load_hls_settings(os.getenv('TEST_CWD'))
    assert.not_same(config.options.hls.default_settings, settings)
  end)
  it('Falls back to default haskell-language-server config if none is found', function()
    local settings = ht.lsp.load_hls_settings(os.getenv('TEST_CWD'), { settings_file_pattern = 'bla.json' })
    assert.same(config.options.hls.default_settings, settings)
  end)
  local hls_bin = config.options.hls.cmd[1]
  if vim.fn.executable(hls_bin) ~= 0 then
    it('Can spin up haskell-language-server for Cabal project.', function()
      --- TODO: Figure out how to add tests for this
      print('TODO')
    end)
  end
end)

describe('LSP client API', function()
  local HtConfig = require('haskell-tools.config.internal')
  local ht = require('haskell-tools')
  local Types = require('haskell-tools.types.internal')
  local test_cwd = vim.fn.getcwd() .. '/spec'
  it('Can load haskell-language-server config', function()
    local settings = ht.lsp.load_hls_settings(test_cwd)
    assert.are_not_same(HtConfig.hls.default_settings, settings)
  end)
  it('Falls back to default haskell-language-server config if none is found', function()
    local settings = ht.lsp.load_hls_settings(test_cwd, { settings_file_pattern = 'bla.json' })
    assert.same(HtConfig.hls.default_settings, settings)
  end)
  local hls_bin = Types.evaluate(HtConfig.hls.cmd)[1]
  if vim.fn.executable(hls_bin) ~= 0 then
    it('Can spin up haskell-language-server for Cabal project.', function()
      --- TODO: Figure out how to add tests for this
      print('TODO')
    end)
  end
end)

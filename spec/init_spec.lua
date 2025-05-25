local stub = require('luassert.stub')
describe('Can require haskell-tools with default configs.', function()
  local notify_once = stub(vim, 'notify_once')
  local notify = stub(vim, 'notify')
  local deprecate = stub(vim, 'deprecate')
  local ht = require('haskell-tools')
  it('Public API is available after setup.', function()
    assert(ht.lsp ~= nil)
    assert(ht.hoogle ~= nil)
    assert(ht.repl ~= nil)
    assert(ht.project ~= nil)
    assert(ht.tags ~= nil)
  end)
  require('haskell-tools.config.internal')
  it('No notifications at startup.', function()
    if not pcall(assert.stub(notify_once).called_at_most, 0) then
      -- fails and outputs arguments
      assert.stub(notify_once).called_with(nil)
    end
    if not pcall(assert.stub(notify).called_at_most, 0) then
      assert.stub(notify).called_with(nil)
    end
  end)
  it('No deprecation warnings at startup.', function()
    if not pcall(assert.stub(deprecate).called_at_most, 0) then
      assert.stub(deprecate).called_with(nil)
    end
  end)
end)

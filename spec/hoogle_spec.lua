local stub = require('luassert.stub')
local mock = require('luassert.mock')
local match = require('luassert.match')
local deps = require('haskell-tools.deps')
local compat = require('haskell-tools.compat')

local hoogle_web = require('haskell-tools.hoogle.web')
local hoogle_local = require('haskell-tools.hoogle.local')
local local_telescope_search = stub(hoogle_local, 'telescope_search')
local browser_search = stub(hoogle_web, 'browser_search')
local web_telescope_search = stub(hoogle_web, 'telescope_search')
local os = require('haskell-tools.os')
local open_browser = stub(os, 'open_browser')
local mock_compat = mock {
  system = function(_)
    return {}
  end,
}
compat.system = mock_compat.system

describe('Hoogle:', function()
  local ht = require('haskell-tools')
  it('Hoogle API available after setup', function()
    assert(ht.hoogle ~= nil)
  end)
  if hoogle_local.has_hoogle() then
    if deps.has_telescope() then
      it('Defaults to local handler', function()
        pcall(ht.hoogle.hoogle_signature, { search_term = 'foo' })
        assert.stub(local_telescope_search).called(1)
        local_telescope_search:revert()
      end)
    else
      it('Defaults to web handler with browser search', function()
        pcall(ht.hoogle.hoogle_signature, { search_term = 'foo' })
        assert.stub(browser_search).called(1)
      end)
    end
  else
    if deps.has_telescope() then
      it('Defaults to web handler with telescope search', function()
        pcall(ht.hoogle.hoogle_signature, { search_term = 'foo' })
        assert.stub(web_telescope_search).called(1)
        web_telescope_search:revert()
      end)
      it('Formatting of URL', function()
        pcall(hoogle_web.telescope_search, 'Foldable t => t a -> Bool')
        assert.spy(mock_compat.system).called_with({
          'curl',
          '--silent',
          'https://hoogle.haskell.org/?hoogle=Foldable+t+%3D%3E+t+a+%2D%3E+Bool&mode=json',
          '-H',
          'Accept: application/json',
        }, nil, match.is_not_nil())
      end)
    else
      it('Web handler is available', function()
        assert(hoogle_web.browser_search ~= nil)
      end)
      it('Defaults to web handler with browser search', function()
        pcall(ht.hoogle.hoogle_signature, { search_term = 'foo' })
        assert.stub(browser_search).called(1)
        browser_search:revert()
      end)
      it('Formatting of URL', function()
        hoogle_web.browser_search('Foldable t => t a -> Bool')
        assert.stub(open_browser).called_with('https://hoogle.haskell.org/?hoogle=Foldable+t+%3D%3E+t+a+%2D%3E+Bool')
      end)
    end
  end
end)

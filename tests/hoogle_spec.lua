local ht = require('haskell-tools')
local stub = require('luassert.stub')
local mock = require('luassert.mock')
local deps = require('haskell-tools.deps')

local hoogle_web = require('haskell-tools.hoogle.web')
local hoogle_local = require('haskell-tools.hoogle.local')
local local_telescope_search = stub(hoogle_local, 'telescope_search')
local browser_search = stub(hoogle_web, 'browser_search')
local web_telescope_search = stub(hoogle_web, 'telescope_search')
local util = require('haskell-tools.util')
local open_browser = stub(util, 'open_browser')
local curl = deps.require_plenary('plenary.curl')
local mock_curl = mock {
  get = function()
    return {}
  end,
}
curl.get = mock_curl.get

local async = deps.require_plenary('plenary.async')
async.run = function(f)
  return f()
end

describe('Hoogle:', function()
  ht.setup {}
  it('Hoogle API available after setup', function()
    assert(ht.hoogle ~= nil)
  end)
  if hoogle_local.has_hoogle() then
    if deps.has_telescope() then
      it('Defaults to local handler', function()
        pcall(ht.hoogle.hoogle_signature, { search_term = 'foo' })
        assert.stub(local_telescope_search).was_called()
        local_telescope_search:revert()
      end)
    else
      it('Defaults to web handler with browser search', function()
        pcall(ht.hoogle.hoogle_signature, { search_term = 'foo' })
        assert.stub(browser_search).was_called()
      end)
    end
  else
    if deps.has_telescope() then
      it('Defaults to web handler with telescope search', function()
        pcall(ht.hoogle.hoogle_signature, { search_term = 'foo' })
        assert.stub(web_telescope_search).was_called()
        web_telescope_search:revert()
      end)
      it('Formatting of URL', function()
        pcall(hoogle_web.telescope_search, 'Foldable t => t a -> Bool')
        assert.spy(mock_curl.get).was_called_with {
          url = 'https://hoogle.haskell.org/?hoogle=Foldable+t+%3D%3E+t+a+%2D%3E+Bool&mode=json',
          accept = 'application/json',
        }
      end)
    else
      it('Web handler is available', function()
        assert(hoogle_web.browser_search ~= nil)
      end)
      it('Defaults to web handler with browser search', function()
        pcall(ht.hoogle.hoogle_signature, { search_term = 'foo' })
        assert.stub(browser_search).was_called()
        browser_search:revert()
      end)
      it('Formatting of URL', function()
        hoogle_web.browser_search('Foldable t => t a -> Bool')
        assert
          .stub(open_browser)
          .was_called_with('https://hoogle.haskell.org/?hoogle=Foldable+t+%3D%3E+t+a+%2D%3E+Bool')
      end)
    end
  end
end)

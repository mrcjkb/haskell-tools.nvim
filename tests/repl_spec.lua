local ht = require('haskell-tools')
local stub = require('luassert.stub')

local function mk_repl_setup_test(handler, auto_focus)
  describe('Setup ' .. handler .. ' handler ' .. (auto_focus and 'with' or 'without') .. ' auto focus.', function()
    local notify_once = stub(vim, 'notify_once')
    local notify = stub(vim, 'notify')
    ht.setup {
      tools = {
        repl = {
          handler = handler,
          auto_focus = auto_focus,
        },
      },
    }
    it('Public API is available after setup.', function()
      assert(ht.repl ~= nil)
    end)
    it('No notifications at startup.', function()
      assert.stub(notify_once).was_not_called()
      assert.stub(notify).was_not_called()
    end)
  end)
end

mk_repl_setup_test('builtin', true)
mk_repl_setup_test('builtin', false)
mk_repl_setup_test('toggleterm', true)
mk_repl_setup_test('toggleterm', false)

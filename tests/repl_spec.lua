local ht = require('haskell-tools')
local stub = require('luassert.stub')
local deps = require('haskell-tools.deps')

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
if deps.has_toggleterm() then
  mk_repl_setup_test('toggleterm', true)
  mk_repl_setup_test('toggleterm', false)
end

local repl = assert(ht.repl, 'repl not set up')
local cwd = vim.fn.getcwd()

describe('mk_repl_cmd', function()
  local stack_project_file = cwd .. '/tests/fixtures/stack/single-package/Abc.hs'
  if vim.fn.executable('stack') == 1 then
    it('prefers stack if stack.yml exists', function()
      local cmd = assert(repl.mk_repl_cmd(stack_project_file))
      assert(#cmd > 1)
      assert.same('stack', cmd[1])
    end)
  else
    it('prefers cabal even if stack.yml exists if cabal files exist', function()
      local cmd = assert(repl.mk_repl_cmd(stack_project_file))
      assert(#cmd > 1)
      assert.same('cabal', cmd[1])
    end)
  end
  local cabal_project_file = cwd .. '/tests/fixtures/cabal/single-package/Abc.hs'
  it('prefers cabal if no stack.yml exists and cabal files exist', function()
    local cmd = assert(repl.mk_repl_cmd(cabal_project_file))
    assert(#cmd > 1)
    assert.same('cabal', cmd[1])
  end)
end)

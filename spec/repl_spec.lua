local stub = require('luassert.stub')
local deps = require('haskell-tools.deps')

local function mk_repl_setup_test(handler)
  describe('Repl with ' .. handler .. ' handler', function()
    local notify_once = stub(vim, 'notify_once')
    local notify = stub(vim, 'notify')
    vim.g.haskell_tools = {
      tools = {
        repl = {
          handler = handler,
        },
      },
    }
    local ht = require('haskell-tools')
    it('Public API is available after setup.', function()
      assert(ht.repl ~= nil)
    end)
    it('No notifications at startup.', function()
      assert.stub(notify_once).called_at_most(0)
      assert.stub(notify).called_at_most(0)
    end)
  end)
end

if deps.has_toggleterm() then
  mk_repl_setup_test('toggleterm')
else
  mk_repl_setup_test('builtin')
end

local cwd = vim.fn.getcwd()

describe('mk_repl_cmd', function()
  local repl = require('haskell-tools').repl
  local stack_project_file = cwd .. '/spec/fixtures/stack/single-package/Abc.hs'
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
  local cabal_project_file = cwd .. '/spec/fixtures/cabal/single-package/Abc.hs'
  it('prefers cabal if no stack.yml exists and cabal files exist', function()
    local cmd = assert(repl.mk_repl_cmd(cabal_project_file))
    assert(#cmd > 1)
    assert.same('cabal', cmd[1])
  end)
end)

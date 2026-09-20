local cwd = vim.fn.getcwd() or '.'
local cabal_project_root = cwd .. '/spec/fixtures/cabal/multi-package'
local stack_project_root = cwd .. '/spec/fixtures/stack/multi-package'

---@param path string
---@return number bufnr
local function make_buffer(path)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(bufnr, path)
  return bufnr
end

describe('DAP launch configuration discovery', function()
  local ht = require('haskell-tools')
  local dap = require('dap')

  ---@param name string
  ---@return table config
  local function find_configuration(name)
    for _, cfg in ipairs(dap.configurations.haskell or {}) do
      if cfg.name == name then
        return cfg
      end
    end
    error('No launch configuration named ' .. name)
  end

  local orig_executable
  before_each(function()
    orig_executable = vim.fn.executable
  end)
  after_each(function()
    if orig_executable then
      rawset(vim.fn, 'executable', orig_executable)
    end
  end)

  it('registers the haskell-debugger adapter and detects Cabal launch configurations', function()
    rawset(vim.fn, 'executable', function()
      return 1
    end)
    local bufnr = make_buffer(cabal_project_root .. '/sub1/src/Lib.hs')
    ht.dap.discover_configurations(bufnr)
    vim.api.nvim_buf_delete(bufnr, { force = true })

    assert.same({
      type = 'server',
      port = '${port}',
      executable = {
        command = 'hdb',
        args = { 'server', '--port', '${port}' },
      },
    }, dap.adapters['haskell-debugger'])

    local app = find_configuration('sub1:app')
    assert.equal('haskell-debugger', app.type)
    assert.equal('launch', app.request)
    assert.equal(cabal_project_root, app.projectRoot)
    assert.equal('sub1/app/Main.hs', app.entryFile)
    assert.equal('main', app.entryPoint)
    assert.same({}, app.entryArgs)
    assert.same({}, app.extraGhcArgs)

    local tests = find_configuration('sub1:tests')
    assert.equal('sub1/test/Spec.hs', tests.entryFile)
  end)

  it('detects launch configurations when hdb is on PATH', function()
    if vim.fn.executable('hdb') ~= 1 then
      ---@diagnostic disable-next-line: missing-parameter
      pending('hdb is not installed')
    end
    local bufnr = make_buffer(stack_project_root .. '/sub1/src/Lib.hs')
    ht.dap.discover_configurations(bufnr)
    vim.api.nvim_buf_delete(bufnr, { force = true })

    assert.is_not_nil(dap.adapters['haskell-debugger'])

    local app = find_configuration('sub1:sub1')
    assert.equal(stack_project_root, app.projectRoot)
    assert.equal('sub1/app/Main.hs', app.entryFile)
    assert.equal('main', app.entryPoint)
  end)
end)

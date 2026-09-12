---@diagnostic disable: undefined-field

local HTConfig = require('haskell-tools.config.internal')
local ht = require('haskell-tools')
local Types = require('haskell-tools.types.internal')
local LspHelpers = require('haskell-tools.lsp.helpers')

local timeout_ms = 120000

local function has_hls()
  local hls_bin = Types.evaluate(HTConfig.hls.cmd)[1]
  return vim.fn.executable(hls_bin) == 1
end

local function copy_project()
  local src = vim.fn.getcwd() .. '/spec/fixtures/cabal/single-package'
  local dst = vim.fn.tempname()
  vim.fn.system { 'cp', '-r', src, dst }
  return dst
end

local function start_client()
  local project_root = copy_project()
  local file = vim.fs.joinpath(project_root, 'src', 'Lib.hs')
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(bufnr, file)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn.readfile(file))
  vim.bo[bufnr].filetype = 'haskell'
  vim.api.nvim_set_current_buf(bufnr)
  ht.lsp.start(bufnr)
  assert(
    vim.wait(timeout_ms, function()
      return #LspHelpers.get_active_hls_clients(bufnr) > 0
    end),
    'failed to start the haskell-language-server client'
  )
  return bufnr
end

local function stop_client(bufnr)
  for _, client in ipairs(LspHelpers.get_active_hls_clients(bufnr)) do
    client:stop()
    vim.wait(timeout_ms, function()
      return vim.lsp.get_client_by_id(client.id) == nil
    end)
  end
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

local function hover(bufnr, row, col)
  local clients = LspHelpers.get_active_hls_clients(bufnr)
  if #clients == 0 then
    return nil
  end
  local result
  clients[1]:request('textDocument/hover', {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = row, character = col },
  }, function(_, res)
    result = res
  end)
  vim.wait(timeout_ms, function()
    return result ~= nil
  end)
  if not result or not result.contents then
    return nil
  end
  return table.concat(vim.lsp.util.convert_input_to_markdown_lines(result.contents, {}), '\n')
end

describe('LSP client API', function()
  local test_cwd = vim.fn.getcwd() .. '/spec'

  it('Can load haskell-language-server config', function()
    local settings = ht.lsp.load_hls_settings(test_cwd)
    assert.are_not_same(HTConfig.hls.default_settings, settings)
  end)

  it('Falls back to default haskell-language-server config if none is found', function()
    local settings = ht.lsp.load_hls_settings(test_cwd, { settings_file_pattern = 'bla.json' })
    assert.same(HTConfig.hls.default_settings, settings)
  end)

  if not has_hls() then
    return
  end

  describe('haskell-language-server client', function()
    local bufnr

    setup(function()
      bufnr = start_client()
    end)

    teardown(function()
      stop_client(bufnr)
    end)

    it('spins up and resolves the type of a function', function()
      local row, col
      for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        local pos = line:find('someFunc =', 1, true)
        if pos then
          row = i - 1
          col = pos - 1
          break
        end
      end
      assert(row, 'expected to find "someFunc =" in the buffer')
      local hover_content = hover(bufnr, row, col)
      assert.is_not_nil(hover_content)
      ---@cast hover_content string
      assert.matches('IO', hover_content, 1, true)
    end)
  end)
end)

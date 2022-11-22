-- Inspired by rust-tools.nvim's hover_actions
local ht = require('haskell-tools')
local ht_definition = require('haskell-tools.lsp.definition')
local lsp_util = vim.lsp.util
local ht_util = require('haskell-tools.util')
local M = {}

local _state = {
  winnr = nil,
  commands = {},
}

local function close_hover()
  local winnr = _state.winnr
  if winnr ~= nil and vim.api.nvim_win_is_valid(winnr) then
    vim.api.nvim_win_close(winnr, true)
  end
end

local function run_command()
  local winnr = vim.api.nvim_get_current_win()
  local line = vim.api.nvim_win_get_cursor(winnr)[1]

  if line > #_state.commands then
    return
  end
  local action = _state.commands[line]
  close_hover()
  action()
end

local function on_hover(_, result, ctx, config)
  config = config or {}
  config.focus_id = ctx.method
  if not (result and result.contents) then
    vim.notify('No information available')
    return
  end
  local markdown_lines = lsp_util.convert_input_to_markdown_lines(result.contents)
  markdown_lines = lsp_util.trim_empty_lines(markdown_lines)
  if vim.tbl_isempty(markdown_lines) then
    vim.notify('No information available')
    return
  end
  local to_remove = {}
  local actions = {}
  _state.commands = {}
  local signature = ht_util.get_signature_from_markdown(result.contents.value)
  if signature and signature ~= '' then
    table.insert(actions, 1, string.format('%d. Hoogle search: `%s`.', #actions + 1, signature))
    table.insert(_state.commands, function()
      ht.hoogle.hoogle_signature { search_term = signature }
    end)
  end
  local cword = vim.fn.expand('<cword>')
  if cword ~= signature then
    table.insert(actions, 1, string.format('%d. Hoogle search: `%s`.', #actions + 1, cword))
    table.insert(_state.commands, function()
      ht.hoogle.hoogle_signature { search_term = cword }
    end)
  end
  local params = lsp_util.make_position_params()
  local found_location = false
  local found_documentation = false
  local found_source = false
  for i, value in ipairs(markdown_lines) do
    if vim.startswith(value, '[Documentation]') and not found_documentation then
      found_documentation = true
      table.insert(to_remove, 1, i)
      table.insert(actions, 1, string.format('%d. Open documentation in browser.', #actions + 1))
      local uri = string.match(value, '%[Documentation%]%((.+)%)')
      table.insert(_state.commands, function()
        ht_util.open_browser(uri)
      end)
    elseif vim.startswith(value, '[Source]') and not found_source then
      found_source = true
      table.insert(to_remove, 1, i)
      table.insert(actions, 1, string.format('%d. View source in browser.', #actions + 1))
      local uri = string.match(value, '%[Source%]%((.+)%)')
      table.insert(_state.commands, function()
        ht_util.open_browser(uri)
      end)
    end
    local location = string.match(value, '*Defined [ia][nt] (.+)')
    if location and not found_location then
      found_location = true
      table.insert(to_remove, 1, i)
      local location_suffix = (' in %s.'):format(location):gsub('%*', ''):gsub('‘', '`'):gsub('’', '`')
      local results, err = vim.lsp.buf_request_sync(0, 'textDocument/definition', params, 1000)
      local can_go_to_definition = false
      if not err and results and #results > 0 then -- Can go to definition
        local definition_results = results[1] and results[1].result or {}
        if #definition_results > 0 then
          can_go_to_definition = true
          local definition_result = definition_results[1]
          table.insert(actions, 1, string.format('%d. Go to definition' .. location_suffix, #actions + 1))
          table.insert(_state.commands, function()
            -- We don't call vim.lsp.buf.definition() because the location params may have changed
            local definition_ctx = {
              method = 'textDocument/definition',
              client_id = ctx.client_id,
            }
            vim.lsp.handlers['textDocument/definition'](_, definition_result, definition_ctx)
          end)
        end
      end
      if not can_go_to_definition then -- Display Hoogle search instead
        local package = location:match('‘(.+)’')
        local search_term = package and package .. '.' .. cword or cword
        table.insert(actions, 1, string.format('%d. Hoogle search: `%s`.', #actions + 1, search_term))
        table.insert(_state.commands, function()
          ht.hoogle.hoogle_signature { search_term = search_term }
        end)
      end
      local reference_params = vim.tbl_deep_extend('force', params, { context = { includeDeclaration = true } })
      table.insert(actions, 1, string.format('%d. Find references.', #actions + 1))
      table.insert(_state.commands, function()
        -- We don't call vim.lsp.buf.references() because the location params may have changed
        vim.lsp.buf_request(0, 'textDocument/references', reference_params)
      end)
    end
  end
  for _, pos in ipairs(to_remove) do
    table.remove(markdown_lines, pos)
  end
  for _, action in ipairs(actions) do
    table.insert(markdown_lines, 1, action)
  end
  if #actions > 0 then
    table.insert(markdown_lines, #actions + 1, '')
    table.insert(markdown_lines, #actions + 1, '')
  end
  local opts = ht.config.options.tools.hover
  config = vim.tbl_extend('keep', {
    border = opts.border,
    stylize_markdown = opts.stylize_markdown,
    focusable = true,
    focus_id = 'haskell-tools-hover',
    close_events = { 'CursorMoved', 'BufHidden', 'InsertCharPre' },
  }, config or {})
  local bufnr, winnr = lsp_util.open_floating_preview(markdown_lines, 'markdown', config)
  if opts.stylize_markdown == false then
    vim.bo[bufnr].filetype = 'markdown'
  end
  if opts.auto_focus == true then
    vim.api.nvim_set_current_win(winnr)
  end

  if _state.winnr ~= nil then
    return bufnr, winnr
  end

  _state.winnr = winnr
  vim.keymap.set('n', '<Esc>', close_hover, { buffer = bufnr, noremap = true, silent = true })
  vim.api.nvim_buf_attach(bufnr, false, {
    on_detach = function()
      _state.winnr = nil
    end,
  })

  if #_state.commands == 0 then
    return bufnr, winnr
  end

  vim.api.nvim_win_set_option(winnr, 'cursorline', true)

  -- run the command under the cursor
  vim.keymap.set('n', '<CR>', function()
    run_command()
  end, { buffer = bufnr, noremap = true, silent = true })

  return bufnr, winnr
end

M.setup = function()
  local orig_buf_hover = vim.lsp.buf.hover
  vim.lsp.buf.hover = function()
    local clients = vim.lsp.get_active_clients { bufnr = vim.api.nvim_get_current_buf() }
    if #clients < 1 then
      return
    end
    local client = clients[1]
    if client.name == 'hls' then
      local params = lsp_util.make_position_params()
      vim.lsp.buf_request(0, 'textDocument/hover', params, on_hover)
    else
      orig_buf_hover()
    end
  end
end

return M

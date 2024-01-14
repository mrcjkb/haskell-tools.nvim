---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Inspired by rust-tools.nvim's hover_actions
---@brief ]]

local log = require('haskell-tools.log.internal')
local lsp_util = vim.lsp.util
local HtParser = require('haskell-tools.parser')
local OS = require('haskell-tools.os')
local HtProjectHelpers = require('haskell-tools.project.helpers')

local hover = {}

---@class HtHoverState
---@field winnr number|nil The hover window number
---@field commands (fun():nil)[] List of hover actions

---@type HtHoverState
local _state = {
  winnr = nil,
  commands = {},
}

---@return nil
local function close_hover()
  local winnr = _state.winnr
  if winnr ~= nil and vim.api.nvim_win_is_valid(winnr) then
    vim.api.nvim_win_close(winnr, true)
    _state.winnr = nil
    _state.commands = {}
  end
end

---Execute the command at the cursor position
---@retrun nil
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

---@param x string hex
---@return string char
local function hex_to_char(x)
  return string.char(tonumber(x, 16))
end

---Formats a location in a Haskell file, shortening it to a relative path if possible.
---@param location string The location provided by LSP hover
---@param current_file string The current file path or an empty string
---@return string formatted_location or the original location if the file is not a Haskell file
local function format_location(location, current_file)
  -- remove *
  -- replace quotes with markdown backticks
  -- decode url-encoded characters
  local formatted_location = ('%s')
    :format(location)
    :gsub('%*', '') -- remove *
    :gsub('‘', '`') -- markdown backticks
    :gsub('’', '`')
    :gsub('%%(%x%x)', hex_to_char) -- decode url-encoded characters
  local file_location = formatted_location:match('(.*).hs:')
  if not file_location then
    return formatted_location
  end
  local is_current_buf = formatted_location:find(current_file, 1, true) == 1
  if is_current_buf then
    return formatted_location:sub(#current_file + 2)
  end
  local path = file_location .. '.hs'
  local package_path = HtProjectHelpers.match_package_root(path)
  if package_path then
    return formatted_location:sub(#package_path + 2) -- trim package path + first '/'
  end
  local project_path = HtProjectHelpers.match_project_root(path)
  if project_path then
    formatted_location = formatted_location:sub(#project_path + 2):gsub('/', ':', 1) -- trim project path + first '/'
  end
  return formatted_location
end

---@param result table LSP result
---@return string location string
local function mk_location(result)
  local range_start = result.range and result.range.start or {}
  local line = range_start.line
  local character = range_start.character
  local uri = result.uri and result.uri:gsub('file://', '')
  return line and character and uri and uri .. ':' .. tostring(line + 1) .. ':' .. tostring(character + 1) or ''
end

---Is the result's start location the same as the params location?
---@param params table LSP location params
---@param result table LSP result
---@return boolean
local function is_same_position(params, result)
  local range_start = result.range and result.range.start or {}
  return params.textDocument.uri == result.uri
    and params.position.line == range_start.line
    and params.position.character == range_start.character
end

---LSP handler for textDocument/hover
---@param result table
---@param ctx table
---@param config table<string,any>|nil
---@return number|nil bufnr
---@return number|nil winnr
function hover.on_hover(_, result, ctx, config)
  local ht = require('haskell-tools')
  config = config or {}
  config.focus_id = ctx.method
  if vim.api.nvim_get_current_buf() ~= ctx.bufnr then
    -- Ignore result since buffer changed.
    return
  end
  if not (result and result.contents) then
    vim.notify('No information available')
    return
  end
  local markdown_lines = lsp_util.convert_input_to_markdown_lines(result.contents)
  if vim.tbl_isempty(markdown_lines) then
    log.debug('No hover information available.')
    vim.notify('No information available')
    return
  end
  local to_remove = {}
  local actions = {}
  _state.commands = {}
  local func_name = vim.fn.expand('<cword>')
  ---@cast func_name string
  local _, signatures = HtParser.try_get_signatures_from_markdown(func_name, result.contents.value)
  for _, signature in pairs(signatures) do
    table.insert(actions, 1, string.format('%d. Hoogle search: `%s`', #actions + 1, signature))
    table.insert(_state.commands, function()
      log.debug { 'Hover: Hoogle search for signature', signature }
      ht.hoogle.hoogle_signature { search_term = signature }
    end)
  end
  local cword = vim.fn.expand('<cword>')
  table.insert(actions, 1, string.format('%d. Hoogle search: `%s`', #actions + 1, cword))
  table.insert(_state.commands, function()
    log.debug { 'Hover: Hoogle search for cword', cword }
    ht.hoogle.hoogle_signature { search_term = cword }
  end)
  local params = ctx.params
  local found_location = false
  local found_type_definition = false
  local found_documentation = false
  local found_source = false
  for i, value in ipairs(markdown_lines) do
    if vim.startswith(value, '[Documentation]') and not found_documentation then
      found_documentation = true
      table.insert(to_remove, 1, i)
      table.insert(actions, 1, string.format('%d. Open documentation in browser', #actions + 1))
      local uri = string.match(value, '%[Documentation%]%((.+)%)')
      table.insert(_state.commands, function()
        log.debug { 'Hover: Open documentation in browser', uri }
        OS.open_browser(uri)
      end)
    elseif vim.startswith(value, '[Source]') and not found_source then
      found_source = true
      table.insert(to_remove, 1, i)
      table.insert(actions, 1, string.format('%d. View source in browser', #actions + 1))
      local uri = string.match(value, '%[Source%]%((.+)%)')
      table.insert(_state.commands, function()
        log.debug { 'Hover: View source in browser', uri }
        OS.open_browser(uri)
      end)
    end
    local location = string.match(value, '*Defined [ia][nt] (.+)')
    local current_file = params.textDocument.uri:gsub('file://', '')
    local results, err, definition_results
    if location == nil or found_location then
      goto SkipDefinition
    end
    found_location = true
    table.insert(to_remove, 1, i)
    results, err = vim.lsp.buf_request_sync(0, 'textDocument/definition', params, 1000)
    if err or results == nil or #results == 0 then
      goto SkipDefinition
    end
    definition_results = results[1] and results[1].result or {}
    if #definition_results > 0 then
      local location_suffix = ('%s'):format(format_location(location, current_file))
      local definition_result = definition_results[1]
      if not is_same_position(params, definition_result) then
        log.debug { 'Hover: definition location', location_suffix }
        table.insert(actions, 1, string.format('%d. Go to definition at ' .. location_suffix, #actions + 1))
        table.insert(_state.commands, function()
          -- We don't call vim.lsp.buf.definition() because the location params may have changed
          local definition_ctx = vim.tbl_extend('force', ctx, {
            method = 'textDocument/definition',
          })
          log.debug { 'Hover: Go to definition', definition_result }
          ---Neovim 0.9 has a bug in the lua doc
          ---@diagnostic disable-next-line: param-type-mismatch
          vim.lsp.handlers['textDocument/definition'](nil, definition_result, definition_ctx)
        end)
      end
    else -- Display Hoogle search instead
      local pkg = location:match('‘(.+)’')
      local search_term = pkg and pkg .. '.' .. cword or cword
      table.insert(actions, 1, string.format('%d. Hoogle search: `%s`', #actions + 1, search_term))
      table.insert(_state.commands, function()
        log.debug { 'Hover: Hoogle search for definition', search_term }
        ht.hoogle.hoogle_signature { search_term = search_term }
      end)
    end
    table.insert(actions, 1, string.format('%d. Find references', #actions + 1))
    table.insert(_state.commands, function()
      local reference_params = vim.tbl_deep_extend('force', params, { context = { includeDeclaration = true } })
      log.debug { 'Hover: Find references', reference_params }
      -- We don't call vim.lsp.buf.references() because the location params may have changed
      ---@diagnostic disable-next-line: missing-parameter
      vim.lsp.buf_request(0, 'textDocument/references', reference_params)
    end)
    ::SkipDefinition::
    if found_type_definition then
      goto SkipTypeDefinition
    end
    results, err = vim.lsp.buf_request_sync(0, 'textDocument/typeDefinition', params, 1000)
    if err or results == nil or #results == 0 then -- Can go to type definition
      goto SkipTypeDefinition
    end
    found_type_definition = true
    local type_definition_results = results[1] and results[1].result or {}
    if #type_definition_results == 0 then
      goto SkipTypeDefinition
    end
    local type_definition_result = type_definition_results[1]
    local type_def_suffix = format_location(mk_location(type_definition_result), current_file)
    if is_same_position(params, result) then
      goto SkipTypeDefinition
    end
    log.debug { 'Hover: type definition location', type_def_suffix }
    table.insert(actions, 1, string.format('%d. Go to type definition at ' .. type_def_suffix, #actions + 1))
    table.insert(_state.commands, function()
      -- We don't call vim.lsp.buf.typeDefinition() because the location params may have changed
      local type_definition_ctx = vim.tbl_extend('force', ctx, {
        method = 'textDocument/typeDefinition',
      })
      log.debug { 'Hover: Go to type definition', type_definition_result }
      ---Neovim 0.9 has a bug in the lua doc
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.lsp.handlers['textDocument/typeDefinition'](nil, type_definition_result, type_definition_ctx)
    end)
    ::SkipTypeDefinition::
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
  local HTConfig = require('haskell-tools.config.internal')
  local opts = HTConfig.tools.hover
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

  vim.api.nvim_set_option_value('cursorline', true, { win = winnr })

  -- run the command under the cursor
  vim.keymap.set('n', '<CR>', function()
    run_command()
  end, { buffer = bufnr, noremap = true, silent = true })

  return bufnr, winnr
end

return hover

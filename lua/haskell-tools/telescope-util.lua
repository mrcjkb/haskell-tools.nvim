local deps = require('haskell-tools.deps')
local actions = deps.require_telescope('telescope.actions')
local actions_state = deps.require_telescope('telescope.actions.state')
local entry_display = deps.require_telescope('telescope.pickers.entry_display')

-- This module provides hoogle search capabilities for telescope.nvim, 
-- The telescope search is mostly inspired by telescope_hoogle by Luc Tielen, 
-- but has been redesigned for searching for individual terms.
-- https://github.com/luc-tielen/telescope_hoogle
local M = {}

function M.hoogle_attach_mappings(buf, map)
  actions.select_default:replace(function()
    -- Copy type signature to clipboard
    local entry = actions_state.get_selected_entry()
    local reg = vim.o.clipboard == 'unnamedplus' and '+' or '"'
    vim.fn.setreg(reg, entry.type_sig)
    actions.close(buf)
  end)
  map('i', '<C-b>', function()
    -- Open in browser
    local entry = actions_state.get_selected_entry()
    util.open_browser(entry.url)
    actions.close(buf)
  end)
  map('i', '<C-r>', function()
    -- Replace word under cursor
    local entry = actions_state.get_selected_entry()
    local func_name = entry.type_sig:match("([^%s]*)%s::")
    actions.close(buf)
    vim.cmd('normal! ciw' .. func_name)
  end)
  return true
end

local function format_html(doc)
  return doc and doc:gsub('&lt;', '<')
  :gsub('&gt;', '>')
  :gsub('&amp', '&')
  or ''
end

local function show_preview(entry, buf)
  local docs = format_html(entry.docs)
  local lines = vim.split(docs, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)

  vim.api.nvim_buf_call(buf, function()
    local win = vim.fn.win_findbuf(buf)[1]
    vim.wo[win].conceallevel = 2
    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
    vim.bo[buf].textwidth = 80
  end)
end

local function make_display(entry)
  local module = entry.module_name

  local displayer = entry_display.create {
    separator = '',
    items = {
      { width = module and #module + 1 or 0 },
      { remaining = true },
    }
  }
  return displayer { {module, "Structure"}, {entry.type_sig, "Type"} }
end

local function get_type_sig(item)
  local name = item:match('<span class=name><s0>(.*)</s0></span>') 
  local sig = item:match(':: (.*)')
  if name and sig then
    return name .. ' :: ' .. format_html(sig)
  end
  return item
end

function M.mk_hoogle_entry(data)
  local module_name = (data.module or {}).name
  local type_sig = data.item and get_type_sig(data.item) or ''
  if not module_name or not type_sig then
    return nil
  end
  return {
    value = data,
    valid = true,
    type_sig = type_sig,
    module_name = module_name,
    url = data.url,
    docs = data.docs,
    display = make_display,
    ordinal = data.item .. data.url,
    preview_command = show_preview
  }
end

return M

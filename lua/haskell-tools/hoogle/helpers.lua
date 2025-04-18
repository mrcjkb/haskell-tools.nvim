---@mod haskell-tools.hoogle.helpers

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- This module provides hoogle search capabilities for telescope.nvim,
--- The telescope search is mostly inspired by telescope_hoogle by Luc Tielen,
--- but has been redesigned for searching for individual terms.
--- https://github.com/luc-tielen/telescope_hoogle
---@brief ]]

local deps = require('haskell-tools.deps')
local actions = deps.require_telescope('telescope.actions')
local actions_state = deps.require_telescope('telescope.actions.state')
local entry_display = deps.require_telescope('telescope.pickers.entry_display')

---@class haskell-tools.hoogle.Helpers
local Helpers = {}

---@param buf number the telescope buffebuffer number
---@param map fun(mode:string,keys:string,action:function) callback for creating telescope keymaps
---@return boolean
function Helpers.hoogle_attach_mappings(buf, map)
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
    require('haskell-tools.config.internal').tools.open_url(entry.url)
  end)
  map('i', '<C-r>', function()
    -- Replace word under cursor
    local entry = actions_state.get_selected_entry()
    local func_name = entry.type_sig:match('([^%s]*)%s::')
    if not func_name then
      vim.notify('Hoogle (replace): Not a function.', vim.log.levels.WARN)
      return
    end
    actions.close(buf)
    vim.api.nvim_input('ciw' .. func_name .. '<ESC>')
  end)
  return true
end

---Format an html string to be displayed by Neovim
---@param html string
---@return string nvim_str
local function format_html(html)
  return html and html:gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&amp', '&') or ''
end

---@class haskell-tools.hoogle.telescope.Entry
---@field value string
---@field valid boolean
---@field type_sig string The entry's type signature
---@field module_name string The name of the module that contains the entry
---@field url string|nil The entry's Hackage URL
---@field docs string|nil The Hoogle entry's documentation
---@field display fun(TelescopeHoogleEntry):haskell-tools.telescope.Display
---@field ordinal string
---@field preview_command fun(TelescopeHoogleEntry, number):nil

---Show a preview in the Telescope previewer
---@param entry haskell-tools.hoogle.telescope.Entry
---@param buf number the Telescope preview buffer
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

---@class haskell-tools.telescope.Display

---@param entry haskell-tools.hoogle.telescope.Entry
---@return haskell-tools.telescope.Display
local function make_display(entry)
  local module = entry.module_name

  local displayer = entry_display.create {
    separator = '',
    items = {
      { width = module and #module + 1 or 0 },
      { remaining = true },
    },
  }
  return displayer { { module, 'Structure' }, { entry.type_sig, 'Type' } }
end

---@param hoogle_item string
---@return string type_signature
local function get_type_sig(hoogle_item)
  local name = hoogle_item:match('<span class=name><s0>(.*)</s0></span>')
  local sig = hoogle_item:match(':: (.*)')
  if name and sig then
    local name_with_type = (name .. ' :: ' .. format_html(sig)):gsub('%s+', ' ') -- trim duplicate whitespace
    return name_with_type
  end
  return hoogle_item
end

---@class haskell-tools.hoogle.Data
---@field module haskell-tools.hoogle.Module|nil
---@field item string|nil
---@field url string|nil
---@field docs string|nil

---@class haskell-tools.hoogle.Module
---@field name string

---@param data haskell-tools.hoogle.Data
---@return haskell-tools.hoogle.telescope.Entry|nil
function Helpers.mk_hoogle_entry(data)
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
    preview_command = show_preview,
  }
end

return Helpers

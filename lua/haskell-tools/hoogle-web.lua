local deps = require('haskell-tools.deps')
local Job = deps.require_plenary('plenary.job')
local async = deps.require_plenary('plenary.async')

-- This module provides hoogle web search capabilities, 
-- either via the browser, or using telescope.
-- The telescope search is mostly inspired by
-- telescope_hoogle by Luc Tielen, and is intended
-- as a fallback in case the plugin is not installed.
-- https://github.com/luc-tielen/telescope_hoogle
local M = {}

local function merge(...)
  return vim.tbl_deep_extend('keep', ...)
end

local function open_browser(url)
  local browser_cmd
  if vim.fn.has('unix') == 1 then
    if vim.fn.executable('sensible-browser') == 1 then
      browser_cmd = 'sensible-browser'
    else
      browser_cmd = 'xdg-open'
    end
  end
  if vim.fn.has('mac') == 1 then
    browser_cmd = 'open'
  end
  if browser_cmd then
    Job:new({
      command = browser_cmd,
      args = { vim.fn.fnameescape(url) },
    }):start()
  end
end

local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

local function mk_hoogle_request(search_term, opts)
  local hoogle_opts = opts.hoogle or {}
  local scope_param = hoogle_opts.scope and '&scope=' .. hoogle_opts.scope or ''
  return 'https://hoogle.haskell.org/?hoogle=' 
    .. urlencode(search_term)
    .. scope_param 
    .. (hoogle_opts.json and '&mode=json' or '')
end

local function setup_telescope_search()
  local pickers = deps.require_telescope('telescope.pickers')
  local finders = deps.require_telescope('telescope.finders')
  local previewers = deps.require_telescope('telescope.previewers')
  local actions = deps.require_telescope('telescope.actions')
  local actions_state = deps.require_telescope('telescope.actions.state')
  local config = deps.require_telescope('telescope.config').values
  local entry_display = deps.require_telescope('telescope.pickers.entry_display')

  local curl = deps.require_plenary('plenary.curl')

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
  end

  local function mk_hoogle_entry(data)
    local module_name = (data.module or {}).name
    local type_sig = get_type_sig(data.item)
    if not module_name or not type_sig then
      return nil
    end
    return {
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


  local function attach_mappings(buf, map)
    actions.select_default:replace(function()
      local entry = actions_state.get_selected_entry()
      local reg = vim.o.clipboard == 'unnamedplus' and '+' or '"'
      vim.fn.setreg(reg, entry.type_sig)
      actions.close(buf)
    end)
    map('i', '<C-b>', function()
      local entry = actions_state.get_selected_entry()
      open_browser(entry.url)
      actions.close(buf)
    end)
    return true
  end

  function M.telescope_search(search_term, opts)
    async.run(function()
      if vim.fn.executable('curl') == 0 then
        error("haskell-tools.hoogle-web: 'curl' executable not found! Aborting.")
        return
      end
      opts = merge(opts or {}, {
        layout_strategy = 'horizontal',
        layout_config = { preview_width = 80 },
        hoogle = { json = true },
      })
      local response = curl.get {
        url = mk_hoogle_request(search_term, opts),
        accept = 'application/json',
      }
      local results = vim.json.decode(response.body)
      pickers.new(opts, {
        prompt_title = 'Hoogle (web) search: ' .. search_term,
        finder = finders.new_table {
          results = results,
          entry_maker = mk_hoogle_entry
        },
        sorter = config.generic_sorter(opts),
        previewer = previewers.display_content.new(opts),
        attach_mappings = attach_mappings,
      }):find()
    end)
  end
end

local function setup_browser_search()
  function M.browser_search(search_term, opts)
    opts = merge(opts or {}, {
      hoogle = { json = false },
    })
    async.run(function()
      open_browser(mk_hoogle_request(search_term, opts))
    end)
  end
end

function M.setup()
  if deps.has_telescope() then
    setup_telescope_search()
  end
  setup_browser_search()
end

return M

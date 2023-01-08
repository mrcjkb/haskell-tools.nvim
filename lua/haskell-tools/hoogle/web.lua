local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')
local util = require('haskell-tools.util')

local hoogle_web = {}

local char_to_hex = function(c)
  return string.format('%%%02X', string.byte(c))
end

local function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub('\n', '\r\n')
  url = url:gsub('([^%w ])', char_to_hex)
  url = url:gsub(' ', '+')
  return url
end

local function mk_hoogle_request(search_term, opts)
  local hoogle_opts = opts.hoogle or {}
  local scope_param = hoogle_opts.scope and '&scope=' .. hoogle_opts.scope or ''
  local hoogle_request = vim.fn.fnameescape(
    'https://hoogle.haskell.org/?hoogle='
      .. urlencode(search_term)
      .. scope_param
      .. (hoogle_opts.json and '&mode=json' or '')
  )
  ht.log.debug { 'Hoogle web request', hoogle_request }
  return hoogle_request
end

local function setup_telescope_search()
  local pickers = deps.require_telescope('telescope.pickers')
  local finders = deps.require_telescope('telescope.finders')
  local previewers = deps.require_telescope('telescope.previewers')
  local config = deps.require_telescope('telescope.config').values
  local hoogle_util = require('haskell-tools.hoogle.util')
  local async = deps.require_plenary('plenary.async')

  local curl = deps.require_plenary('plenary.curl')

  function hoogle_web.telescope_search(search_term, opts)
    async.run(function()
      if vim.fn.executable('curl') == 0 then
        ht.log.error('curl executable not found.')
        error("haskell-tools.hoogle-web: 'curl' executable not found! Aborting.")
        return
      end
      opts = hoogle_util.merge_telescope_opts(opts)
      opts.hoogle = opts.hoogle or {}
      opts.hoogle.json = true

      local response = curl.get {
        url = mk_hoogle_request(search_term, opts),
        accept = 'application/json',
      }
      ht.log.debug { 'Hoogle web response', response }
      local results = vim.json.decode(response.body)
      pickers
        .new(opts, {
          prompt_title = 'Hoogle: ' .. search_term,
          finder = finders.new_table {
            results = results,
            entry_maker = hoogle_util.mk_hoogle_entry,
          },
          sorter = config.generic_sorter(opts),
          previewer = previewers.display_content.new(opts),
          attach_mappings = hoogle_util.hoogle_attach_mappings,
        })
        :find()
    end)
  end
end

local function setup_browser_search()
  function hoogle_web.browser_search(search_term, opts)
    opts = util.tbl_merge(opts or {}, {
      hoogle = { json = false },
    })
    util.open_browser(mk_hoogle_request(search_term, opts))
  end
end

function hoogle_web.setup()
  if deps.has_telescope() then
    setup_telescope_search()
  end
  setup_browser_search()
end

return hoogle_web

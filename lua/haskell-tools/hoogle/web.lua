---@mod haskell-tools.hoogle.web

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local log = require('haskell-tools.log')
local deps = require('haskell-tools.deps')
local util = require('haskell-tools.util')

---@class WebHoogleHandler
local WebHoogleHandler = {}

---@param c string A single character
---@return string The hex representation
local char_to_hex = function(c)
  return string.format('%%%02X', c:byte())
end

---Encode a URL so it can be opened in a browser
---@param url string
---@return string encoded_url
local function urlencode(url)
  url = url:gsub('\n', '\r\n')
  url = url:gsub('([^%w ])', char_to_hex)
  url = url:gsub(' ', '+')
  return url
end

---@class TelescopeHoogleWebOpts
---@field hoogle HoogleWebSearchOpts|nil

---@class HoogleWebSearchOpts
---@field scope string|nil The scope of the search
---@field json boolean|nil Whather to request JSON enocded results

---Build a Hoogle request URL
---@param search_term string
---@param opts TelescopeHoogleWebOpts
local function mk_hoogle_request(search_term, opts)
  local hoogle_opts = opts.hoogle or {}
  local scope_param = hoogle_opts.scope and '&scope=' .. hoogle_opts.scope or ''
  local hoogle_request = 'https://hoogle.haskell.org/?hoogle='
    .. urlencode(search_term)
    .. scope_param
    .. (hoogle_opts.json and '&mode=json' or '')
  log.debug { 'Hoogle web request', hoogle_request }
  return hoogle_request
end

if deps.has_telescope() then
  local pickers = deps.require_telescope('telescope.pickers')
  local finders = deps.require_telescope('telescope.finders')
  local previewers = deps.require_telescope('telescope.previewers')
  local hoogle_util = require('haskell-tools.hoogle.util')
  local async = deps.require_plenary('plenary.async')

  local curl = deps.require_plenary('plenary.curl')

  ---@param search_term string
  ---@param opts TelescopeHoogleWebOpts|nil
  ---@return nil
  function WebHoogleHandler.telescope_search(search_term, opts)
    local config = deps.require_telescope('telescope.config').values
    if not config then
      local msg = 'telescope.nvim has not been setup. Falling back to browser search.'
      log.warn(msg)
      vim.notify_once('haskell-tools.hoogle: ' .. msg, vim.log.levels.WARN)
      WebHoogleHandler.browser_search(search_term, opts)
      return
    end
    if vim.fn.executable('curl') == 0 then
      log.error('curl executable not found.')
      vim.notify("haskell-tools.hoogle-web: 'curl' executable not found! Aborting.", vim.log.levels.ERROR)
      return
    end
    opts = opts or {}
    opts.hoogle = opts.hoogle or {}
    opts.hoogle.json = true
    local url = mk_hoogle_request(search_term, opts)
    async.run(function()
      local response = curl.get {
        url = url,
        accept = 'application/json',
      }
      log.debug { 'Hoogle web response', response }
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

---@param search_term string
---@param opts TelescopeHoogleWebOpts|nil
---@return nil
function WebHoogleHandler.browser_search(search_term, opts)
  opts = util.tbl_merge(opts or {}, {
    hoogle = { json = false },
  })
  util.open_browser(mk_hoogle_request(search_term, opts))
end

return WebHoogleHandler

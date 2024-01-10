---@mod haskell-tools.hoogle.web

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local log = require('haskell-tools.log.internal')
local deps = require('haskell-tools.deps')
local OS = require('haskell-tools.os')
local compat = require('haskell-tools.compat')

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
  local HoogleHelpers = require('haskell-tools.hoogle.helpers')

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
    local curl_command = { 'curl', '--silent', url, '-H', 'Accept: application/json' }
    log.debug(curl_command)
    compat.system(curl_command, nil, function(result)
      ---@cast result vim.SystemCompleted
      log.debug { 'Hoogle web response', result }
      local response = result.stdout
      if result.code ~= 0 or response == nil then
        vim.notify('hoogle web: ' .. (result.stderr or 'error calling curl'), vim.log.levels.ERROR)
        return
      end
      local ok, results = pcall(vim.json.decode, response)
      vim.schedule(function()
        if not ok then
          log.error { 'Hoogle web response (invalid JSON)', curl_command, 'result: ' .. result }
          vim.notify(
            "haskell-tools.hoogle: Received invalid JSON from curl. Likely due to a failed request. See ':HtLog' for details'",
            vim.log.levels.ERROR
          )
          return
        end
        pickers
          .new(opts, {
            prompt_title = 'Hoogle: ' .. search_term,
            finder = finders.new_table {
              results = results,
              entry_maker = HoogleHelpers.mk_hoogle_entry,
            },
            sorter = config.generic_sorter(opts),
            previewer = previewers.display_content.new(opts),
            attach_mappings = HoogleHelpers.hoogle_attach_mappings,
          })
          :find()
      end)
    end)
  end
end

---@param search_term string
---@param opts TelescopeHoogleWebOpts|nil
---@return nil
function WebHoogleHandler.browser_search(search_term, opts)
  opts = vim.tbl_deep_extend('keep', opts or {}, {
    hoogle = { json = false },
  })
  OS.open_browser(mk_hoogle_request(search_term, opts))
end

return WebHoogleHandler

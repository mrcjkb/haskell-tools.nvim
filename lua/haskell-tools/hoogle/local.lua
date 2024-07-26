---@mod haskell-tools.hoogle.local

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local log = require('haskell-tools.log.internal')
local deps = require('haskell-tools.deps')

---@class haskell-tools.hoogle.handler.Local
local Local = {}

---@return boolean has_hoogle `true` if the `hoogle` executable exists
function Local.has_hoogle()
  return vim.fn.executable('hoogle') == 1
end

if not Local.has_hoogle() then
  return Local
end

if not deps.has_telescope() then
  return Local
end

---@class haskell-tools.hoogle.handler.Local.Opts
---@field entry_maker function|nil telescope entry maker
---@field count number|nil number of results to display

---Construct the hoogle cli arguments
---@param search_term string The Hoogle search term
---@param opts haskell-tools.hoogle.handler.Local.Opts
---@return string[] hoogle_args
local function mk_hoogle_args(search_term, opts)
  local count = opts.count or 50
  local args = vim.iter({ '--json', '--count=' .. count, search_term }):flatten():totable()
  log.debug { 'Hoogle local args', args }
  return args
end

local pickers = deps.require_telescope('telescope.pickers')
local finders = deps.require_telescope('telescope.finders')
local previewers = deps.require_telescope('telescope.previewers')
local HoogleHelpers = require('haskell-tools.hoogle.helpers')

---@param search_term string The Hoogle search term
---@param opts haskell-tools.hoogle.handler.Local.Opts|nil
---@return nil
function Local.telescope_search(search_term, opts)
  opts = opts or {}
  opts.entry_maker = opts.entry_maker or HoogleHelpers.mk_hoogle_entry
  local config = deps.require_telescope('telescope.config').values
  if not config then
    local msg = 'telescope.nvim has not been setup.'
    log.error(msg)
    vim.notify_once('haskell-tools.hoogle: ' .. msg, vim.log.levels.ERROR)
    return
  end
  local cmd = vim.list_extend({ 'hoogle' }, mk_hoogle_args(search_term, opts))
  vim.system(
    cmd,
    nil,
    vim.schedule_wrap(function(result)
      ---@cast result vim.SystemCompleted
      local output = result.stdout
      if result.code ~= 0 or output == nil then
        local err_msg = 'haskell-tools: hoogle search failed. Exit code: ' .. result.code
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return
      end
      local success, results = pcall(vim.json.decode, output)
      if not success then
        log.error { 'Hoogle: Could not process result.', output }
        vim.notify('Hoogle: Could not process result - ' .. vim.inspect(output), vim.log.levels.ERROR)
        return
      end
      if #results < 1 or output == 'No results found' then
        vim.notify('Hoogle: No results found.', vim.log.levels.INFO)
        return
      end
      pickers
        .new(opts, {
          prompt_title = 'Hoogle: ' .. search_term,
          sorter = config.generic_sorter(opts),
          finder = finders.new_table {
            results = results,
            entry_maker = HoogleHelpers.mk_hoogle_entry,
          },
          previewer = previewers.display_content.new(opts),
          attach_mappings = HoogleHelpers.hoogle_attach_mappings,
        })
        :find()
    end)
  )
end

return Local

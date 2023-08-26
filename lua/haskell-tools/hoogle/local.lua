---@mod haskell-tools.hoogle.local

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local log = require('haskell-tools.log')
local deps = require('haskell-tools.deps')

---@class LocalHoogleHandler
local HoogleLocal = {}

---@return boolean has_hoogle `true` if the `hoogle` executable exists
function HoogleLocal.has_hoogle()
  return vim.fn.executable('hoogle') == 1
end

if not HoogleLocal.has_hoogle() then
  return HoogleLocal
end

if not deps.has_telescope() then
  return HoogleLocal
end

---@class LocalHoogleOpts
---@field entry_maker function|nil telescope entry maker
---@field count number|nil number of results to display

---Construct the hoogle cli arguments
---@param search_term string The Hoogle search term
---@param opts LocalHoogleOpts
---@return string[] hoogle_args
local function mk_hoogle_args(search_term, opts)
  local count = opts.count or 50
  local args = vim.tbl_flatten { '--json', '--count=' .. count, search_term }
  log.debug { 'Hoogle local args', args }
  return args
end

local pickers = deps.require_telescope('telescope.pickers')
local finders = deps.require_telescope('telescope.finders')
local previewers = deps.require_telescope('telescope.previewers')
local HoogleHelpers = require('haskell-tools.hoogle.helpers')
local Job = deps.require_plenary('plenary.job')

---@param search_term string The Hoogle search term
---@param opts LocalHoogleOpts|nil
---@return nil
function HoogleLocal.telescope_search(search_term, opts)
  opts = opts or {}
  opts.entry_maker = opts.entry_maker or HoogleHelpers.mk_hoogle_entry
  local config = deps.require_telescope('telescope.config').values
  if not config then
    local msg = 'telescope.nvim has not been setup.'
    log.error(msg)
    vim.notify_once('haskell-tools.hoogle: ' .. msg, vim.log.levels.ERROR)
    return
  end
  Job:new({
    command = 'hoogle',
    args = mk_hoogle_args(search_term, opts),
    on_exit = function(j, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          local err_msg = 'haskell-tools: hoogle search failed. Exit code: ' .. exit_code
          log.error(err_msg)
          vim.notify(err_msg, vim.log.levels.ERROR)
          return
        end
        local output = j:result()[1]
        if #output < 1 then
          return
        elseif output == 'No results found' then
          vim.notify('Hoogle: No results found.', vim.log.levels.WARN)
          return
        end
        local success, results = pcall(vim.json.decode, output)
        if not success then
          log.error { 'Hoogle: Could not process result.', output }
          vim.notify('Hoogle: Could not process result - ' .. vim.inspect(output), vim.log.levels.ERROR)
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
    end,
  }):start()
end

return HoogleLocal

---@mod haskell-tools.hoogle.local

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')

local hoogle_local = {}

function hoogle_local.has_hoogle()
  if vim.fn.executable('hoogle') == 1 then
    ht.log.info('Local hoogle executable found.')
    return true
  end
  return false
end

local function mk_hoogle_args(search_term, opts)
  local count = opts.count or 50
  local args = vim.tbl_flatten { '--json', '--count=' .. count, search_term }
  ht.log.debug { 'Hoogle local args', args }
  return args
end

local function setup_telescope_search()
  local pickers = deps.require_telescope('telescope.pickers')
  local finders = deps.require_telescope('telescope.finders')
  local previewers = deps.require_telescope('telescope.previewers')
  local config = deps.require_telescope('telescope.config').values
  local hoogle_util = require('haskell-tools.hoogle.util')
  local Job = deps.require_plenary('plenary.job')

  function hoogle_local.telescope_search(search_term, opts)
    opts = hoogle_util.merge_telescope_opts(opts)
    opts.entry_maker = opts.entry_maker or hoogle_util.mk_hoogle_entry
    Job:new({
      command = 'hoogle',
      args = mk_hoogle_args(search_term, opts),
      on_exit = function(j, exit_code)
        vim.schedule(function()
          if exit_code ~= 0 then
            local err_msg = 'haskell-tools: hoogle search failed. Exit code: ' .. exit_code
            ht.log.error(err_msg)
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
            ht.log.error { 'Hoogle: Could not process result.', output }
            vim.notify('Hoogle: Could not process result - ' .. vim.inspect(output), vim.log.levels.ERROR)
            return
          end
          pickers
            .new(opts, {
              prompt_title = 'Hoogle: ' .. search_term,
              sorter = config.generic_sorter(opts),
              finder = finders.new_table {
                results = results,
                entry_maker = hoogle_util.mk_hoogle_entry,
              },
              previewer = previewers.display_content.new(opts),
              attach_mappings = hoogle_util.hoogle_attach_mappings,
            })
            :find()
        end)
      end,
    }):start()
  end
end

function hoogle_local.setup()
  if hoogle_local.has_hoogle() and deps.has_telescope() then
    ht.log.info('Setting up local hoogle telescope search.')
    setup_telescope_search()
  else
    ht.log.info('No local hoogle executable found.')
  end
end

return hoogle_local

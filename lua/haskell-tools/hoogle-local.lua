local deps = require('haskell-tools.deps')
local util = require('haskell-tools.util')

local M = {}

function M.has_hoogle()
  return vim.fn.executable('hoogle') == 1
end

local function mk_hoogle_args(search_term, opts)
  local count = opts.count or 50
  local cmd = vim.tbl_flatten { '--json', '--count=' .. count, search_term, }
  return cmd
end

local function setup_telescope_search()

  local pickers = deps.require_telescope('telescope.pickers')
  local finders = deps.require_telescope('telescope.finders')
  local previewers = deps.require_telescope('telescope.previewers')
  local config = deps.require_telescope('telescope.config').values
  local telescope_util = require('haskell-tools.telescope-util')
  local Job = deps.require_plenary('plenary.job')

  function M.telescope_search(search_term, opts)
    opts = util.tbl_merge(opts or {}, {
      layout_strategy = 'horizontal',
      layout_config = { preview_width = 80 },
    })
    opts.entry_maker = opts.entry_maker or telescope_util.mk_hoogle_entry
    Job:new({
      command = 'hoogle',
      args = mk_hoogle_args(search_term, opts),
      on_exit = function(j, return_val)
        vim.schedule(function()
          if (return_val ~= 0) then
            error('haskell-toos: hoogle search failed. Return value: ' .. return_val)
          end
          local output = j:result()[1]
          if #output < 1 then
            return
          end
          pickers.new(opts, {
            prompt_title = 'Hoogle: ' .. search_term,
            sorter = config.generic_sorter(opts),
            finder = finders.new_table {
              results = vim.json.decode(output),
              entry_maker = telescope_util.mk_hoogle_entry
            },
            previewer = previewers.display_content.new(opts),
            attach_mappings = telescope_util.hoogle_attach_mappings,
          }):find()
        end)
      end
    }):start()
  end
end

function M.setup()
  if M.has_hoogle() then
    setup_telescope_search()
  end
end

return M

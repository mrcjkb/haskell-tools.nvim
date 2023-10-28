local compat = require('haskell-tools.compat')

---@class DapInternal
local Dap = {}

---@param package_name string
---@param exe_name string
---@param package_dir string
---@param mains string[]
---@param source_dirs string[]
---@return HsEntryPoint[] entry_points
Dap.mk_entry_points = function(package_name, exe_name, package_dir, mains, source_dirs)
  ---@type HsEntryPoint[]
  local entry_points = {}
  for _, source_dir in pairs(source_dirs) do
    for _, main in pairs(mains) do
      local filename = compat.joinpath(package_dir, source_dir, main)
      if vim.fn.filereadable(filename) == 1 then
        local entry_point = {
          package_name = package_name,
          exe_name = exe_name,
          main = main,
          source_dir = source_dir,
          package_dir = package_dir,
        }
        table.insert(entry_points, entry_point)
      end
    end
  end
  return entry_points
end

return Dap

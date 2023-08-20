---@mod haskell-tools.internal-types

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Type definitions
---@brief ]]

---@class HsEntryPoint
---@field package_dir string
---@field package_name string
---@field exe_name string
---@field main string
---@field source_dir string

local Types = {}

---Evaluate a value that may be a function
---or an evaluated value
---@generic T
---@param value (fun():T)|T
---@return T
Types.evaluate = function(value)
  if type(value) == 'function' then
    return value()
  end
  return value
end

return Types

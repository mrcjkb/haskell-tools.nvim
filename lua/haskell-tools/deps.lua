---@mod haskell-tools.deps

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

---@class Deps
local Deps = {}

---@param modname string The name of the module
---@param on_available any|nil Callback. Can be a function that takes the module name as an argument or a value.
---@param on_not_available any|nil Callback to execute if the module is not available. Can be a function or a value.
---@return any result Return value of on_available or on_not_available
function Deps.if_available(modname, on_available, on_not_available)
  local has_mod, mod = pcall(require, modname)
  if has_mod and type(on_available) == 'function' then
    return on_available(mod)
  elseif has_mod then
    return on_available
  end
  if not on_not_available then
    return nil
  end
  if type(on_not_available) == 'function' then
    return on_not_available()
  end
  return on_not_available
end

---Require a module or fail
---@param modname string
---@param plugin_name string
---@return unknown
---@require
function Deps.require_or_err(modname, plugin_name)
  return Deps.if_available(modname, function(mod)
    return mod
  end, function()
    error('haskell-tools: This plugin requires the ' .. plugin_name .. ' plugin.')
  end)
end

---@param modname string The name of the module
---@return boolean
function Deps.has(modname)
  return Deps.if_available(modname, true, false)
end

---@return boolean
function Deps.has_telescope()
  return Deps.has('telescope')
end

---@return unknown
---@require
function Deps.require_telescope(modname)
  return Deps.require_or_err(modname, 'nvim-telescope/telescope.nvim')
end

---@return unknown
---@require
function Deps.require_toggleterm(modname)
  return Deps.require_or_err(modname, 'akinsho/toggleterm')
end

---@return boolean
function Deps.has_toggleterm()
  return Deps.has('toggleterm')
end

---@return unknown
---@require
function Deps.require_iron(modname)
  return Deps.require_or_err(modname, 'hkupty/iron.nvim')
end

return Deps

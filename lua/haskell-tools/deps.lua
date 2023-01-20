---@mod haskell-tools.deps

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

---@class Deps

---@type Deps
local deps = {}

---@param modname string The name of the module
---@param on_available any? Callback. Can be a function that takes the module name as an argument or a value.
---@param on_not_available any? Callback to execute if the module is not available. Can be a function or a value.
---@return any result Return value of on_available or on_not_available
function deps.if_available(modname, on_available, on_not_available)
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
function deps.require_or_err(modname, plugin_name)
  return deps.if_available(modname, function(mod)
    return mod
  end, function()
    error('haskell-tools: This plugin requires the ' .. plugin_name .. ' plugin.')
  end)
end

---@param modname string The name of the module
---@return boolean
function deps.has(modname)
  return deps.if_available(modname, true, false)
end

---@return boolean
function deps.has_telescope()
  return deps.has('telescope')
end

---@return unknown
function deps.require_telescope(modname)
  return deps.require_or_err(modname, 'nvim-telescope/telescope.nvim')
end

---@return unknown
function deps.require_plenary(modname)
  return deps.require_or_err(modname, 'nvim-lua/plenary.nvim')
end

---@return unknown
function deps.require_lspconfig(modname)
  return deps.require_or_err(modname, 'neovim/nvim-lspconfig')
end

---@return unknown
function deps.require_toggleterm(modname)
  return deps.require_or_err(modname, 'akinsho/toggleterm')
end

---@return unknown
function deps.require_iron(modname)
  return deps.require_or_err(modname, 'hkupty/iron.nvim')
end

return deps

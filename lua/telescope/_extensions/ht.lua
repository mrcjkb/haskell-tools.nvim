---@mod haskell-tools.telescope-extension haskell-tools Telescope extension
---@brief [[
--- If `telescope.nvim` is installed, `haskell-tools` will register the `ht` extenstion
--- with the following commands:
---
--- * `:Telescope ht package_files` - Search for files within the current (sub)package.
--- * `:Telescope ht package_hsfiles` - Search for Haskell files within the current (sub)package.
--- * `:Telescope ht package_grep` - Live grep within the current (sub)package.
--- * `:Telescope ht package_hsgrep` - Live grep Haskell files within the current (sub)package.
--- * `:Telescope ht hoogle_signature` - Run a Hoogle search for the type signature under the cursor.
---
--- To load the extension, call
---
--- >
--- require('telescope').load_extension('ht')
--- <
---
--- In Lua, you can access the extension with
---
--- >
--- local telescope = require('telescope')
--- telescope.extensions.ht.package_files()
--- telescope.extensions.ht.package_hsfiles()
--- telescope.extensions.ht.package_grep()
--- telescope.extensions.ht.package_hsgrep()
--- telescope.extensions.ht.hoogle_signature()
--- <
---
---@brief ]]

local deps = require('haskell-tools.deps')

return deps.if_available('telescope', function(telescope)
  local ht_extension = require('telescope._extensions.ht.extension')
  return telescope.register_extension(ht_extension)
end)

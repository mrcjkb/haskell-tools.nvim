local ht = require('haskell-tools')

--- @brief[[
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
--- @brief]]

return {
  exports = {
    -- Live grep within the current (sub)package
    package_grep = ht.project.telescope_package_grep,
    -- Live grep within Haskell files in the current (sub)package
    package_hsgrep = function(opts)
      opts = vim.tbl_deep_extend('keep', { type_filter = 'haskell' }, opts or {})
      ht.project.telescope_package_grep(opts)
    end,
    -- Find files within the current (sub)package
    package_files = ht.project.telescope_package_files,
    -- Find Haskell files within the current (sub)package
    package_hsfiles = function(opts)
      opts = vim.tbl_deep_extend('keep', { type_filter = 'haskell' }, opts or {})
      ht.project.telescope_package_grep(opts)
    end,
    hoogle_signature = ht.hoogle.hoogle_signature,
  },
}

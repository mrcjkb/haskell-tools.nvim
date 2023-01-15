local ht = require('haskell-tools')

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

local function n_assert(mod)
  if mod then
    return mod
  end
  local function notify_err(_)
    vim.notify('haskell-tools.nvim has not been set up yet.', vim.log.levels.ERROR)
  end
  return {
    telescope_package_grep = notify_err,
    telescope_package_files = notify_err,
    hoogle_signature = notify_err,
  }
end

return {
  exports = {
    -- Live grep within the current (sub)package
    package_grep = function(opts)
      n_assert(require('haskell-tools').project).telescope_package_grep(opts)
    end,
    -- Live grep within Haskell files in the current (sub)package
    package_hsgrep = function(opts)
      opts = vim.tbl_deep_extend('keep', { type_filter = 'haskell' }, opts or {})
      n_assert(require('haskell-tools').project).telescope_package_grep(opts)
    end,
    -- Find files within the current (sub)package
    package_files = function(opts)
      n_assert(require('haskell-tools').project).telescope_package_files(opts)
    end,
    -- Find Haskell files within the current (sub)package
    package_hsfiles = function(opts)
      opts = vim.tbl_deep_extend('keep', { type_filter = 'haskell' }, opts or {})
      n_assert(require('haskell-tools').project).telescope_package_grep(opts)
    end,
    hoogle_signature = function(opts)
      n_assert(require('haskell-tools').hoogle).hoogle_signature(opts)
    end,
  },
}

local deps = require('haskell-tools.deps')

return deps.if_available('telescope', function(telescope)
  local ht_extension = require('telescope._extensions.ht.extension')
  return telescope.register_extension(ht_extension)
end)



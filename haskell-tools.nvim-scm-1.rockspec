local MODREV, SPECREV = 'scm', '-1'
rockspec_format = '3.0'
package = 'haskell-tools.nvim'
version = MODREV .. SPECREV

description = {
  summary = 'Supercharge your Haskell experience in neovim!',
  detailed = [[
    Automatically configures the haskell-language-server neovim client
    and integrates with other haskell tools, such as hoogle and fast-tags.
  ]],
  labels = { 'neovim', 'lsp', 'haskell', 'plugin' },
  homepage = 'https://github.com/MrcJkb/haskell-tools.nvim',
  license = 'GPL-2.0',
}

dependencies = {
  'lua >= 5.1',
  'plenary.nvim',
}

source = {
  url = 'git://github.com/MrcJkb/haskell-tools.nvim',
}

build = {
  type = 'builtin',
  copy_directories = {
    'doc',
  },
}

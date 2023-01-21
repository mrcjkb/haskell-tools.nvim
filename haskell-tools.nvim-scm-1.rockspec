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
  'nvim-lspconfig',
  'plenary.nvim',
}

source = {
  url = 'http://github.com/MrcJkb/haskell-tools.nvim/archive/' .. MODREV .. '.zip',
  dir = 'haskell-tools.nvim-' .. MODREV,
}

if MODREV == 'scm' then
  source = {
    url = 'git://github.com/MrcJkb/haskell-tools.nvim',
  }
end

build = {
  type = 'builtin',
  copy_directories = {
    -- 'doc', # TODO: uncomment when docs have been added
  },
}

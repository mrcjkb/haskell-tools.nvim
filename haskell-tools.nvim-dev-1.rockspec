rockspec_format = "3.0"
package = "haskell-tools.nvim"
version = "dev-1"

description = {
  summary = "Supercharge your Haskell experience in Neovim!",
  detailed = "This plugin automatically configures the haskell-language-server builtin LSP client and integrates with other Haskell tools. See the README's #features section for more info.",
  homepage = "https://github.com/mrcjkb/haskell-tools.nvim",
  issues_url = "https://github.com/mrcjkb/haskell-tools.nvim/issues",
  maintainer = "mrcjkb",
  labels = {
    "dap",
    "debug-adapter-protocol",
    "haskell",
    "haskell-language-server",
    "language-server-protocol",
    "lsp",
    "neovim",
    "nvim",
    "plugin",
  },
  license = "GPL-2.0-only",
}

dependencies = {
  "lua==5.1",
}

source = {
  url = "git+https://github.com/mrcjkb/haskell-tools.nvim.git",
}

build = {
  type = "builtin",
  copy_directories = {
    "doc",
    "ftplugin",
  },
}

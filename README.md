# haskell-tools.nvim

> __[WIP]__ 

Improve your Haskell experience in [neovim](https://neovim.io/)!

![](./nvim-haskell.svg)

## Quick Links
- [Installation](#installation)
- [Quick Setup](#quick-setup)
- [Features](#features)
- [Advanced configuration](#advanced-configuration)

## Prerequisites

* `neovim >= 0.8`
* [`nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig)
* [`haskell-language-server`](https://haskell-language-server.readthedocs.io/en/latest/installation.html)


## Installation

Example using [`packer.nvim`](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'MrcJkb/haskell-tools.nvim',
  requires = {
    'neovim/nvim-lspconfig',
  }
}
```

## Quick Setup

This plugin automatically configures the haskell-language-server NeoVim client.
If using this plugin, __do not__ call the `lspconfig.hls` setup or set up the lsp manually, as doing so will cause conflicts.

To get started quickly with the default setup, add the following to your NeoVim config:

```lua
on_attach = function(_, bufnr)
-- See nvim-lspconfig's  suggested configuration for keymaps, etc.
end

require('haskell-tools').setup {
  hls = {
    on_attach = on_attach,
  },
}

```

## Features

[x] Basic haskell-language-server functionality on par with `nvim-lspconfig.hls`
[x] Clean shutdown of language server on exit to prevent corrupted files ([see ghc #14533](https://gitlab.haskell.org/ghc/ghc/-/issues/14533))


## Advanced configuration

To modify the language server configs, call

```lua

require('haskell-tools').setup {
  hls = {
    -- ...
    haskell = {
      formattingProvider = 'fourmolu', -- Defaults to 'ormolu'
      checkProject = false, -- Defaults to true, which could have a performance impact on large monorepos.
    }
  }
}

```

* The full list of defaults [can be found here](./lua/haskell-tools/config.lua)
* To view all available language server settings (including those not set by this plugin), run `haskell-language-server generate-default-config`
* For detailed descriptions of the configs, look at the [haskell-language-server documentation](https://haskell-language-server.readthedocs.io/en/latest/configuration.html).

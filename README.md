# haskell-tools.nvim

![](./nvim-haskell.svg)

# __[WIP]__ 

Improve your Haskell experience in [neovim](https://neovim.io/)!

## Quick Links
- [Installation](#installation)
- [Quick Setup](#quick-setup)
- [Features](#features)
- [Advanced configuration](#advanced-configuration)
- [Recommendations](#recommendations)

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
local on_attach = function(_, bufnr)
-- See nvim-lspconfig's  suggested configuration for keymaps, etc.
end

require('haskell-tools').setup {
  hls = {
    on_attach = on_attach,
  },
}

```

## Features

- [x] Basic haskell-language-server functionality on par with `nvim-lspconfig.hls`
- [x] Clean shutdown of language server on exit to prevent corrupted files ([see ghc #14533](https://gitlab.haskell.org/ghc/ghc/-/issues/14533))
- [x] Automatically adds capabilities for the following plugins, if loaded:
  * [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)


## Advanced configuration

To modify the language server configs, call

```lua

require('haskell-tools').setup {
  hls = {
    -- ...
    haskell = {
      formattingProvider = 'fourmolu', -- Defaults to 'ormolu'
      checkProject = false, -- Defaults to true, which could have a performance impact on large monorepos.
      -- ...
    }
  }
}

```

* The full list of defaults [can be found here](./lua/haskell-tools/config.lua)
* To view all available language server settings (including those not set by this plugin), run `haskell-language-server generate-default-config`
* For detailed descriptions of the configs, look at the [haskell-language-server documentation](https://haskell-language-server.readthedocs.io/en/latest/configuration.html).

## Recommendations

Here are some other plugins I recommend for Haskell (and nix) development in neovim:

* [MrcJkb/neotest-haskell](https://github.com/MrcJkb/neotest-haskell): Interact with tests in neovim
* [luc-tielen/telescope_hoogle](https://github.com/luc-tielen/telescope_hoogle): Hoogle search
* [MrcJkb/telescope-manix](https://github.com/MrcJkb/telescope-manix): Nix search
* [mfussenegger/nvim-lint](https://github.com/mfussenegger/nvim-lint): As a fallback in case there are problems with haskell-language-server (e.g. in large monorepos)
* [aloussase/scout](https://github.com/aloussase/scout): CLI for searching Hackage with telescope.nvim integration

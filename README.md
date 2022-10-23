# haskell-tools.nvim

![](./nvim-haskell.svg)

Supercharge your Haskell experience in [neovim](https://neovim.io/)!

## Quick Links
- [Installation](#installation)
- [Quick Setup](#quick-setup)
- [Features](#features)
- [Advanced configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)
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

:warning: __Do not call the `lspconfig.hls` setup or set up the lsp manually, as doing so may cause conflicts.__

To get started quickly with the default setup, add the following to your NeoVim config:

```lua
-- See nvim-lspconfig's  suggested configuration for keymaps, etc.
local on_attach = function(_, bufnr)
  -- haskell-language-server relies heavily on codeLenses,
  -- so auto-refresh (see advanced configuration) is enabled by default
  vim.keymap.set('n', '<space>ca', vim.lsp.codelens.run)
end

require('haskell-tools').setup {
  hls = {
    on_attach = on_attach,
  },
}
```

## Features

- [x] Basic haskell-language-server functionality on par with `nvim-lspconfig.hls`

### Beyond `nvim-lspconfig.hls`

- [x] Clean shutdown of language server on exit to prevent corrupted files ([see ghc #14533](https://gitlab.haskell.org/ghc/ghc/-/issues/14533)).
- [x] Automatically adds capabilities for the following plugins, if loaded:
  * [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) (provides completion sources for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)).
  * [nvim-lsp-selection-range](https://github.com/camilledejoye/nvim-lsp-selection-range) (Adds haskell-specific [expand selection](https://haskell-language-server.readthedocs.io/en/latest/features.html#selection-range) support).
- [x] Automatically refreshes code lenses by default, which haskell-language-server heavily relies on. [Can be disabled.](#advanced-configuration)
- [x] The following code lenses are currently supported:

##### [Show/Add type signatures for bindings without type signatures](https://haskell-language-server.readthedocs.io/en/latest/features.html#add-type-signature)
[![asciicast](https://asciinema.org/a/zC88fqMhPq25lHFYgEF6OxMgk.svg)](https://asciinema.org/a/zC88fqMhPq25lHFYgEF6OxMgk?t=0:04)

##### [Evaluate code snippets in comments](https://haskell-language-server.readthedocs.io/en/latest/features.html#evaluation-code-snippets-in-comments)
[![asciicast](https://asciinema.org/a/TffryPrWpBkLnBK6dKXvOxd41.svg)](https://asciinema.org/a/TffryPrWpBkLnBK6dKXvOxd41?t=0:04)

##### [Make import lists fully explicit](https://haskell-language-server.readthedocs.io/en/latest/features.html#make-import-lists-fully-explicit-code-lens)
[![asciicast](https://asciinema.org/a/l2ggVaN5eQbOj9iGkaethnS7P.svg)](https://asciinema.org/a/l2ggVaN5eQbOj9iGkaethnS7P?t=0:02)

##### [Fix module names that do not match the file path](https://haskell-language-server.readthedocs.io/en/latest/features.html#fix-module-names)
[![asciicast](https://asciinema.org/a/n2qd2zswLOonl2ZEb8uL4MHsG.svg)](https://asciinema.org/a/n2qd2zswLOonl2ZEb8uL4MHsG?t=0:02)

### Planned

For planned features, refer to the [issues](https://github.com/MrcJkb/haskell-tools.nvim/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement).


## Advanced configuration

To modify the language server configs, call

```lua
require('haskell-tools').setup {
  tools = { -- haskell-tools options
    codeLens = {
      -- Whether to automatically display/refresh codeLenses
      autoRefresh = false, -- defaults to true
    },
  },
  hls = { -- LSP client options
    -- ...
    haskell = { -- haskell-language-server options
      formattingProvider = 'fourmolu', -- Defaults to 'ormolu'
      checkProject = false, -- Defaults to true, which could have a performance impact on large monorepos.
      -- ...
    }
  }
}
```

* The full list of defaults [can be found here](./lua/haskell-tools/config.lua).
* To view all available language server settings (including those not set by this plugin), run `haskell-language-server generate-default-config`.
* For detailed descriptions of the configs, look at the [haskell-language-server documentation](https://haskell-language-server.readthedocs.io/en/latest/configuration.html).

### How to disable individual code lenses

Some code lenses might be more interesting than others.
For example, the `importLens` could be annoying if you prefer to import everything or use a custom prelude.
Individual code lenses can be turned off by disabling them in the respective plugin configurations:

```lua
hls = {
  haskell = {
    plugin = {
      class = { -- missing class methods
        codeLensOn = false,
      },
      importLens = { -- make import lists fully explicit
        codeLensOn = false,
      },
      refineImports = { -- refine imports
        codeLensOn = false,
      },
      tactics = { -- wingman
        codeLensOn = false,
      },
      moduleName = { -- fix module names
        globalOn = false,
      },
      eval = { -- evaluate code snippets
        globalOn = false,
      },
      ['ghcide-type-lenses'] = { -- show/add missing type signatures
        globalOn = false,
      },
    },
  },
},
```

## Troubleshooting

#### LSP features not working
Check which version of GHC you are using (`:LspInfo`).
Sometimes, certain features take some time to be implemented for the latest GHC versions.
You can see how well a specific GHC version is supported [here](https://haskell-language-server.readthedocs.io/en/latest/support/index.html).

## Recommendations

Here are some other plugins I recommend for Haskell (and nix) development in neovim:

* [MrcJkb/neotest-haskell](https://github.com/MrcJkb/neotest-haskell): Interact with tests in neovim.
* [luc-tielen/telescope_hoogle](https://github.com/luc-tielen/telescope_hoogle): Hoogle search.
* [MrcJkb/telescope-manix](https://github.com/MrcJkb/telescope-manix): Nix search.
* [mfussenegger/nvim-lint](https://github.com/mfussenegger/nvim-lint): As a fallback in case there are problems with haskell-language-server (e.g. in large monorepos).
* [aloussase/scout](https://github.com/aloussase/scout): CLI for searching Hackage with telescope.nvim integration.



![](./nvim-haskell.svg)

`haskell-tools.nvim`

Supercharge your Haskell experience in [neovim](https://neovim.io/)!

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)
![Haskell](https://img.shields.io/badge/Haskell-5e5086?style=for-the-badge&logo=haskell&logoColor=white)

## Quick Links
- [Installation](#installation)
- [Quick Setup](#quick-setup)
- [Features](#features)
- [Advanced configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)
- [Recommendations](#recommendations)

## Prerequisites

### Required

* `neovim >= 0.8`
* [`nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig)
* [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim)
* [`haskell-language-server`](https://haskell-language-server.readthedocs.io/en/latest/installation.html)

### Optional

* [`telescope.nvim`](https://github.com/nvim-telescope/telescope.nvim)
* A local [`hoogle`](https://github.com/ndmitchell/hoogle/blob/master/docs/Install.md) installation (recommended for better hoogle search performance)

## Installation

Example using [`packer.nvim`](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'MrcJkb/haskell-tools.nvim',
  requires = {
    'neovim/nvim-lspconfig',
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim', -- optional
  },
  -- tag = 'x.y.z' -- [^1]
}
```
[^1] It is suggested to use the [latest release tag](./CHANGELOG.md) 
     and to update it manually, if you would like to avoid breaking changes.

## Quick Setup

This plugin automatically configures the haskell-language-server neovim client.

:warning: __Do not call the `lspconfig.hls` setup or set up the lsp manually, as doing so may cause conflicts.__

To get started quickly with the default setup, add the following to your neovim config:

```lua
local ht = require('haskell-tools')

local opts = { noremap = true, silent = true, buffer = bufnr }
ht.setup {
  hls = {
    -- See nvim-lspconfig's  suggested configuration for keymaps, etc.
    on_attach = function(client, bufnr)
      -- haskell-language-server relies heavily on codeLenses,
      -- so auto-refresh (see advanced configuration) is enabled by default
      vim.keymap.set('n', '<space>ca', vim.lsp.codelens.run, opts)
      vim.keymap.set('n', '<space>hs', ht.hoogle.hoogle_signature, opts)
      -- default_on_attach(client, bufnr)  -- if defined, see nvim-lspconfig
    end,
  },
}
```

If using a local `hoogle` installation, [follow these instructions](https://github.com/ndmitchell/hoogle/blob/master/docs/Install.md#generate-a-hoogle-database)
to generate a database.

## Features

- [x] Basic haskell-language-server functionality on par with `nvim-lspconfig.hls`

### Beyond `nvim-lspconfig.hls`

- [x] Clean shutdown of language server on exit to prevent corrupted files ([see ghc #14533](https://gitlab.haskell.org/ghc/ghc/-/issues/14533)).
- [x] Automatically adds capabilities for the following plugins, if loaded:
  * [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) (provides completion sources for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)).
  * [nvim-lsp-selection-range](https://github.com/camilledejoye/nvim-lsp-selection-range) (Adds haskell-specific [expand selection](https://haskell-language-server.readthedocs.io/en/latest/features.html#selection-range) support).
- [x] Automatically refreshes code lenses by default, which haskell-language-server heavily relies on. [Can be disabled.](#advanced-configuration)
- [x] The following code lenses are currently supported:

#### [Show/Add type signatures for bindings without type signatures](https://haskell-language-server.readthedocs.io/en/latest/features.html#add-type-signature)
[![asciicast](https://asciinema.org/a/zC88fqMhPq25lHFYgEF6OxMgk.svg)](https://asciinema.org/a/zC88fqMhPq25lHFYgEF6OxMgk?t=0:04)

#### [Evaluate code snippets in comments](https://haskell-language-server.readthedocs.io/en/latest/features.html#evaluation-code-snippets-in-comments)
[![asciicast](https://asciinema.org/a/TffryPrWpBkLnBK6dKXvOxd41.svg)](https://asciinema.org/a/TffryPrWpBkLnBK6dKXvOxd41?t=0:04)

#### [Make import lists fully explicit](https://haskell-language-server.readthedocs.io/en/latest/features.html#make-import-lists-fully-explicit-code-lens)
[![asciicast](https://asciinema.org/a/l2ggVaN5eQbOj9iGkaethnS7P.svg)](https://asciinema.org/a/l2ggVaN5eQbOj9iGkaethnS7P?t=0:02)

#### [Fix module names that do not match the file path](https://haskell-language-server.readthedocs.io/en/latest/features.html#fix-module-names)
[![asciicast](https://asciinema.org/a/n2qd2zswLOonl2ZEb8uL4MHsG.svg)](https://asciinema.org/a/n2qd2zswLOonl2ZEb8uL4MHsG?t=0:02)

### Beyond haskell-language-server

The below features are not implemented by haskell-language-server.

#### Hoogle-search for signature

* Search for the type signature under the cursor.
* Falls back to the word under the cursor if the type signature cannot be determined.
* Telescope keymaps:
  - `<CR>` to copy the selected entry (<name> :: <signature>) to the clipboard.
  - `<C-b>` to open the selected entry's Hackage URL in a browser.
  - `<C-r>` to replace the word under the cursor with the selected entry.

```lua
require('haskell-tools').hoogle.hoogle_signature()
```

[![asciicast](https://asciinema.org/a/4GSmXrCvpt7idBHnuZVQQkJ9R.svg)](https://asciinema.org/a/4GSmXrCvpt7idBHnuZVQQkJ9R)

#### Use Hoogle search to fill holes

With the `<C-r>` keymap, the Hoogle search telescope integration can be used to fill holes.

[![asciicast](https://asciinema.org/a/xEWKbTELrnJD0wNbC5t6jL6Tw.svg)](https://asciinema.org/a/xEWKbTELrnJD0wNbC5t6jL6Tw?t=0:04)

### Planned

For planned features, refer to the [issues](https://github.com/MrcJkb/haskell-tools.nvim/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement).


## Advanced configuration

To modify the default configs, call

```lua
-- defaults
require('haskell-tools').setup {
  tools = { -- haskell-tools options
    codeLens = {
      -- Whether to automatically display/refresh codeLenses
      autoRefresh = true,
    },
    hoogle = {
      -- 'auto': Choose a mode automatically, based on what is available.
      -- 'telescope-local': Force use of a local installation.
      -- 'telescope-web': The online version (depends on curl).
      -- 'browser': Open hoogle search in the default browser.
      mode = 'auto', 
    },
  },
  hls = { -- LSP client options
    -- ...
    haskell = { -- haskell-language-server options
      formattingProvider = 'ormolu', 
      checkProject = true, -- Setting this to true could have a performance impact on large mono repos.
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
* [luc-tielen/telescope_hoogle](https://github.com/luc-tielen/telescope_hoogle): Live Hoogle search.
* [MrcJkb/telescope-manix](https://github.com/MrcJkb/telescope-manix): Nix search.
* [mfussenegger/nvim-lint](https://github.com/mfussenegger/nvim-lint): As a fallback in case there are problems with haskell-language-server (e.g. in large mono repos).
* [aloussase/scout](https://github.com/aloussase/scout): CLI for searching Hackage with telescope.nvim integration.



<h1 align="center">
  <img src="./nvim-haskell.svg" alt="haskell-tools.nvim">
</h1>

🦥 Supercharge your Haskell experience in [Neovim](https://neovim.io/)!

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)
![Haskell](https://img.shields.io/badge/Haskell-5e5086?style=for-the-badge&logo=haskell&logoColor=white)
![Nix](https://img.shields.io/badge/nix-0175C2?style=for-the-badge&logo=NixOS&logoColor=white)

[![Nix build](https://github.com/MrcJkb/haskell-tools.nvim/actions/workflows/nix-build.yml/badge.svg)](https://github.com/MrcJkb/haskell-tools.nvim/actions/workflows/nix-build.yml)
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-3-grey.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

## Quick Links
- [Installation](#installation)
- [Quick Setup](#quick-setup)
- [Features](#features)
- [Advanced configuration](#advanced-configuration)
  - [Available functions](#available-functions)
  - [Available commands](#available-commands)
  - [Telescope extension](#telescope-extension)
- [Troubleshooting](#troubleshooting)
- [Recommendations](#recommendations)
- [Contributing](./CONTRIBUTING.md)


## Prerequisites

### Required

* `neovim >= 0.8`
* [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim)

### Optional

* [`haskell-language-server`](https://haskell-language-server.readthedocs.io/en/latest/installation.html) (recommended)
* [`telescope.nvim`](https://github.com/nvim-telescope/telescope.nvim)
* A local [`hoogle`](https://github.com/ndmitchell/hoogle/blob/master/docs/Install.md) installation (recommended for better hoogle search performance)
* [`fast-tags`](https://github.com/elaforge/fast-tags) (for automatic tag generation as a fallback for `vim.lsp.tagfunc`).


## Installation

This plugin is available on LuaRocks.

[![LuaRocks](https://img.shields.io/luarocks/v/MrcJkb/haskell-tools.nvim?logo=lua&color=purple)](https://luarocks.org/modules/MrcJkb/haskell-tools.nvim)

If you use a plugin manager that does not support LuaRocks, you have to declare the dependencies yourself.

Example using `packer.nvim`:

```lua
use {
  'mrcjkb/haskell-tools.nvim',
  requires = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim', -- optional
  },
  branch = '1.x.x', -- recommended
}
```
>**Note**
>
>It is suggested to use the stable branch if you would like to avoid breaking changes.

For NixOS users with flakes enabled, this project provides outputs in the form of a package and an overlay; use it as you wish in your nixos or home-manager configuration.
It is also available on `nixpkgs`.

## Quick Setup

This plugin automatically configures the `haskell-language-server` builtin LSP client and integrates with other haskell tools.
See the [Features](#features) section for more info.

>**Warning**
>
> Do not call the [`nvim-lspconfig.hls`](https://github.com/neovim/nvim-lspconfig) setup or set up the lsp manually, as doing so may cause conflicts.

To get started quickly with the default setup, add the following Add the following to `~/.config/nvim/ftplugin/haskell.lua`[^1]:

[^1]: See `:help base-directories`

```lua
local ht = require('haskell-tools')
local def_opts = { noremap = true, silent = true, }
ht.start_or_attach {
  hls = {
    on_attach = function(client, bufnr)
      local opts = vim.tbl_extend('keep', def_opts, { buffer = bufnr, })
      -- haskell-language-server relies heavily on codeLenses,
      -- so auto-refresh (see advanced configuration) is enabled by default
      vim.keymap.set('n', '<space>ca', vim.lsp.codelens.run, opts)
      vim.keymap.set('n', '<space>hs', ht.hoogle.hoogle_signature, opts)
    end,
  },
}
-- Suggested keymaps that do not depend on haskell-language-server
-- Toggle a GHCi repl for the current package
vim.keymap.set('n', '<leader>rr', ht.repl.toggle, def_opts)
-- Toggle a GHCi repl for the current buffer
vim.keymap.set('n', '<leader>rf', function()
  ht.repl.toggle(vim.api.nvim_buf_get_name(0))
end, def_opts)
vim.keymap.set('n', '<leader>rq', ht.repl.quit, def_opts)
```

>**Note**
>
> * For more LSP related keymaps, [see the `nvim-lspconfig` suggestions](https://github.com/neovim/nvim-lspconfig#suggested-configuration).
> * If using a local `hoogle` installation, [follow these instructions](https://github.com/ndmitchell/hoogle/blob/master/docs/Install.md#generate-a-hoogle-database)
to generate a database.
> * If you prefer, you can instead call `require('haskell-tools').setup {}` with the same options as `start_or_attach()` in your Neovim config.
>   In this case, `haskell-tools.nvim` will set up filetype autocommands for you.

## Features

- [x] Basic haskell-language-server functionality on par with `nvim-lspconfig.hls`

### Beyond `nvim-lspconfig.hls`

- [x] Dynamically load `haskell-language-server` settings per project from JSON files.
- [x] Clean shutdown of language server on exit to prevent corrupted files ([see ghc #14533](https://gitlab.haskell.org/ghc/ghc/-/issues/14533)).
- [x] Automatically adds capabilities for the following plugins, if loaded:
  * [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) (provides completion sources for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)).
  * [nvim-lsp-selection-range](https://github.com/camilledejoye/nvim-lsp-selection-range) (Adds haskell-specific [expand selection](https://haskell-language-server.readthedocs.io/en/latest/features.html#selection-range) support).
- [x] Automatically refreshes code lenses by default, which haskell-language-server heavily relies on. [Can be disabled.](#advanced-configuration)
- [x] The following code lenses are currently supported:

#### [Show/Add type signatures for bindings without type signatures](https://haskell-language-server.readthedocs.io/en/latest/features.html#add-type-signature)
[![](https://asciinema.org/a/zC88fqMhPq25lHFYgEF6OxMgk.svg)](https://asciinema.org/a/zC88fqMhPq25lHFYgEF6OxMgk?t=0:04)

#### [Evaluate code snippets in comments](https://haskell-language-server.readthedocs.io/en/latest/features.html#evaluation-code-snippets-in-comments)
[![](https://asciinema.org/a/TffryPrWpBkLnBK6dKXvOxd41.svg)](https://asciinema.org/a/TffryPrWpBkLnBK6dKXvOxd41?t=0:04)

You can also evaluate all code snippets at once:

[![](https://asciinema.org/a/ljdU8AhJL6rfe0OgV8ryaCtHY.svg)](https://asciinema.org/a/ljdU8AhJL6rfe0OgV8ryaCtHY)

#### [Make import lists fully explicit](https://haskell-language-server.readthedocs.io/en/latest/features.html#make-import-lists-fully-explicit-code-lens)
[![](https://asciinema.org/a/l2ggVaN5eQbOj9iGkaethnS7P.svg)](https://asciinema.org/a/l2ggVaN5eQbOj9iGkaethnS7P?t=0:02)

#### [Fix module names that do not match the file path](https://haskell-language-server.readthedocs.io/en/latest/features.html#fix-module-names)
[![](https://asciinema.org/a/n2qd2zswLOonl2ZEb8uL4MHsG.svg)](https://asciinema.org/a/n2qd2zswLOonl2ZEb8uL4MHsG?t=0:02)

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

[![](https://asciinema.org/a/4GSmXrCvpt7idBHnuZVQQkJ9R.svg)](https://asciinema.org/a/4GSmXrCvpt7idBHnuZVQQkJ9R)

#### Hole-driven development powered by Hoogle

With the `<C-r>` keymap, the Hoogle search telescope integration can be used to fill holes.

[![](https://asciinema.org/a/xEWKbTELrnJD0wNbC5t6jL6Tw.svg)](https://asciinema.org/a/xEWKbTELrnJD0wNbC5t6jL6Tw?t=0:04)

#### GHCi repl

Start a GHCi repl for the current project / buffer.

* Automagically detects the appropriate command (`cabal new-repl`, `stack ghci` or `ghci`) for your project.
* Choose between a builtin handler or [`toggleterm.nvim`](https://github.com/akinsho/toggleterm.nvim).
* Dynamically create a repl command for [`iron.nvim`](https://github.com/hkupty/iron.nvim) (see [advanced configuration](#advanced-configuration)).
* Interact with the repl from within Haskell files using a lua API.

[![](https://asciinema.org/a/HtTdq1tqxoRVjt4hEf22tInLV.svg)](https://asciinema.org/a/HtTdq1tqxoRVjt4hEf22tInLV)

#### Open project/package files for the current buffer

[![](https://asciinema.org/a/LBZ8jceyWZv9kwrSqskxZTGlr.svg)](https://asciinema.org/a/LBZ8jceyWZv9kwrSqskxZTGlr)


#### Hover actions

Inspired by [rust-tools.nvim](https://github.com/simrat39/rust-tools.nvim), this plugin adds the following hover actions (if available):

* Hoogle search for signature.
* Open documentation in browser.
* Open source in browser.
* Go to definition.
* Find references.

Additionally, the default behaviour of stylizing markdown is disabled. And the hover buffer's filetype is set to markdown,
so that [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) users can benefit from syntax highliting of code snippets.

[![](https://asciinema.org/a/AqYEBSIVVSw5qPUHumoxHHiUy.svg)](https://asciinema.org/a/AqYEBSIVVSw5qPUHumoxHHiUy)


#### Automatically generate tags

On attaching, Neovim's LSP client will set up `tagfunc` (`:h tagfunc`) to query the language server for locations to jump to.
If no location is found, it will fall back to a `tags` file.

If [`fast-tags`](https://github.com/elaforge/fast-tags) is installed,
this plugin will set up `autocmd`s to automatically generate tags:

* For the whole project, when starting a session.
* For the current (sub)package, when writing a file.

This feature can be tweaked or disabled in the [advanced configuration](#advanced-configuration).


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
      -- (explicitly set to false to disable)
      autoRefresh = true,
    },
    hoogle = {
      -- 'auto': Choose a mode automatically, based on what is available.
      -- 'telescope-local': Force use of a local installation.
      -- 'telescope-web': The online version (depends on curl).
      -- 'browser': Open hoogle search in the default browser.
      mode = 'auto',
    },
    hover = {
      -- Whether to disable haskell-tools hover and use the builtin lsp's default handler
      disable = false,
      -- Set to nil to disable
      border = {
        { '╭', 'FloatBorder' },
        { '─', 'FloatBorder' },
        { '╮', 'FloatBorder' },
        { '│', 'FloatBorder' },
        { '╯', 'FloatBorder' },
        { '─', 'FloatBorder' },
        { '╰', 'FloatBorder' },
        { '│', 'FloatBorder' },
      },
      -- Stylize markdown (the builtin lsp's default behaviour).
      -- Setting this option to false sets the file type to markdown and enables
      -- Treesitter syntax highligting for Haskell snippets if nvim-treesitter is installed
      stylize_markdown = false,
      -- Whether to automatically switch to the hover window
      auto_focus = false,
    },
    definition = {
      -- Configure vim.lsp.definition to fall back to hoogle search
      -- (does not affect vim.lsp.tagfunc)
      hoogle_signature_fallback = false,
    },
    repl = {
      -- 'builtin': Use the simple builtin repl
      -- 'toggleterm': Use akinsho/toggleterm.nvim
      handler = 'builtin',
      builtin = {
        create_repl_window = function(view)
          -- create_repl_split | create_repl_vsplit | create_repl_tabnew | create_repl_cur_win
          return view.create_repl_split { size = vim.o.lines / 3 }
        end
      },
      -- Can be overriden to either `true` or `false`. The default behaviour depends on the handler.
      auto_focus = nil,
    },
    -- Set up autocmds to generate tags (using fast-tags)
    -- e.g. so that `vim.lsp.tagfunc` can fall back to Haskell tags
    tags = {
      enable = vim.fn.executable('fast-tags') == 1,
      -- Events to trigger package tag generation
      package_events = { 'BufWritePost' },
    },
  },
  hls = { -- LSP client options
    -- ...
    default_settings = {
      haskell = { -- haskell-language-server options
        formattingProvider = 'ormolu',
        checkProject = true, -- Setting this to true could have a performance impact on large mono repos.
        -- ...
      }
    }
  }
}
```

* The full list of defaults [can be found here](./lua/haskell-tools/config.lua).
* To view all available language server settings (including those not set by this plugin), run `haskell-language-server generate-default-config`.
* For detailed descriptions of the configs, look at the [haskell-language-server documentation](https://haskell-language-server.readthedocs.io/en/latest/configuration.html).

### How to dynamically load different `haskell-language-server` settings per project

By default, this plugin will look for a `hls.json` file in the project root directory, and attempt to load it.
If the file does not exist, or it can't be decoded, the `hls.default_settings` will be used.

You can change this behaviour with the `hls.settings` config:

```lua
local ht = require('haskell-tools')
ht.setup {
  -- ...
  hls = {
    settings = function(project_root)
      return ht.lsp.load_hls_settings(project_root, {
        settings_file_pattern = 'hls.json'
      })
    end,
  },
}
```

### How to disable individual code lenses

Some code lenses might be more interesting than others.
For example, the `importLens` could be annoying if you prefer to import everything or use a custom prelude.
Individual code lenses can be turned off by disabling them in the respective plugin configurations:

```lua
hls = {
  settings = {
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
},
```

>**Note**
>
>Alternatively, you can [dynamically enable/disable different code lenses per project](#how-to-dynamically-load-different-haskell-language-server-settings-per-project).

### Launch `haskell-language-server` on Cabal files

Since version `1.9.0.0`, `haskell-language-server` can launch on Cabal files.
You can either attach the LSP client in a `~/.config/nvim/ftplugin/cabal.lua` file[^1], or call `haskell-tools.setup()`.

### Set up [`iron.nvim`](https://github.com/hkupty/iron.nvim) to use `haskell-tools.nvim`

Depends on [iron.nvim/#300](https://github.com/hkupty/iron.nvim/pull/300).

```lua
local iron = require("iron.core")
iron.setup {
  config = {
    repl_definition = {
      haskell = {
        command = function(meta)
          local file = vim.api.nvim_buf_get_name(meta.current_bufnr)
          -- call `require` in case iron is set up before haskell-tools
          return require('haskell-tools').repl.mk_repl_cmd(file)
        end,
      },
    },
  },
}
```

### Available functions

For a complete overview, enter `:help haskell-tools` in Neovim.

#### LSP

```lua
local ht = require('haskell-tools')
-- Start or attach the LSP client.
ht.lsp.start()

-- Stop the LSP client.
ht.lsp.stop()

-- Restart the LSP client.
ht.lsp.restart()

-- Callback for dynamically loading haskell-language-server settings
ht.lsp.load_hls_settings(project_root)

-- Evaluate all code snippets in comments
ht.lsp.buf_eval_all()
```

#### Hoogle

```lua
local ht = require('haskell-tools')
-- Run a hoogle signature search for the value under the cursor
ht.hoogle.hoogle_signature()
```

#### Repl

```lua
local ht = require('haskell-tools')
-- Toggle a GHCi repl for the current project
ht.repl.toggle()

-- Toggle a GHCi repl for `file` (must be a Haskell file)
ht.repl.toggle(file)

-- Quit the repl
ht.repl.quit()

-- Paste a command to the repl from register `reg`. (`reg` defaults to '"')
ht.repl.paste(reg)

-- Query the repl for the type of register `reg`. (`reg` defaults to '"')
ht.repl.paste_type(reg)

-- Query the repl for the type of word under the cursor
ht.repl.cword_type()

-- Query the repl for info on register `reg`. (`reg` defaults to '"')
ht.repl.paste_info(reg)

-- Query the repl for info on the word under the cursor
ht.repl.cword_info()

-- Load a file into the repl
ht.repl.load_file(file)

-- Reload the repl
ht.repl.reload()
```

#### Project

```lua
local ht = require('haskell-tools')
-- Open the project file for the current buffer (cabal.project or stack.yaml)
ht.project.open_project_file()

-- Open the package.yaml file for the current buffer
ht.project.open_package_yaml()

-- Open the *.cabal file for the current buffer
ht.project.open_package_cabal()

-- Search for files within the current (sub)package
-- `opts`: Optional telescope.nvim find_files options
ht.project.telescope_package_files(opts)
-- Live grep within the current (sub)package
-- `opts`: Optional telescope.nvim live_grep options
ht.project.telescope_package_grep(opts)
```

#### Tags

The following functions depend on [`fast-tags`](https://github.com/elaforge/fast-tags).

```lua
local ht = require('haskell-tools')

-- Generate tags for the whole project
-- `path`: An optional file path, defaults to the current buffer
-- `opts`: Optional options:
-- `opts.refresh`: Whether to refresh tags if they have already been generated for a project
ht.tags.generate_project_tags(path, opts)

-- Generate tags for the whole project
-- `path`: An optional file path, defaults to the current buffer
ht.tags.generate_package_tags(path)
```


### Available commands

#### LSP

* `:HlsStart` - Start the LSP client.
* `:HlsStop` - Stop the LSP client.
* `:HlsRestart` - Restart the LSP client.

#### Project

* `:HsProjectFile` - Open the project file for the current buffer (cabal.project or stack.yaml).
* `:HsPackageYaml` - Open the package.yaml file for the current buffer.
* `:HsPackageCabal` - Open the *.cabal file for the current buffer.

### Telescope extension

If [`telescope.nvim`](https://github.com/nvim-telescope/telescope.nvim) is installed, `haskell-tools.nvim` will register the `ht` extenstion
with the following commands:

* `:Telescope ht package_files` - Search for files within the current (sub)package.
* `:Telescope ht package_hsfiles` - Search for Haskell files within the current (sub)package.
* `:Telescope ht package_grep` - Live grep within the current (sub)package.
* `:Telescope ht package_hsgrep` - Live grep Haskell files within the current (sub)package.
* `:Telescope ht hoogle_signature` - Run a Hoogle search for the type signature under the cursor.

To load the extension, call

```lua
require('telescope').load_extension('ht')
```

## Troubleshooting

For a health check, run `:checkhealth haskell-tools`

#### LSP features not working
Check which version of GHC you are using (`haskell-language-server-werapper --version`).
Sometimes, certain features take some time to be implemented for the latest GHC versions.
You can see how well a specific GHC version is supported [here](https://haskell-language-server.readthedocs.io/en/latest/support/index.html).

#### Minimal config

To troubleshoot this plugin with a minimal config in a temporary directory, use [minimal.lua](./tests/minimal.lua).

```console
mkdir -p /tmp/minimal/
# The first start will install the plugins into the temporary directory
NVIM_DATA_MINIMAL=/tmp/minimal nvim -u minimal.lua
# Quit Neovim and start it up again with the plugins loaded
NVIM_DATA_MINIMAL=/tmp/minimal nvim -u minimal.lua
```

#### Logs

To enable debug logging, set the log level to `DEBUG` (`:h vim.log.levels`):

```lua
require('haskell-tools').setup {
  tools = { -- haskell-tools options
    log = {
      level = vim.log.levels.DEBUG,
    },
  },
}
```

You can also temporarily set the log level by calling

```lua
:lua require('haskell-tools').log.set_level(vim.log.levels.DEBUG)
```

You can find the log files by calling

```lua
-- haskell-tools.nvim log
:lua =require('haskell-tools').log.get_logfile()
-- haskell-language-server logs
:lua =require('haskell-tools').log.get_hls_logfile()
```
or open them by calling

```lua
:lua require('haskell-tools').log.nvim_open_logfile()
:lua require('haskell-tools').log.nvim_open_hls_logfile()
```

## Recommendations

Here are some other plugins I recommend for Haskell (and nix) development in neovim:

* [neotest-haskell](https://github.com/MrcJkb/neotest-haskell): Interact with tests in neovim.
* [telescope_hoogle](https://github.com/luc-tielen/telescope_hoogle): Live Hoogle search.
* [telescope-manix](https://github.com/MrcJkb/telescope-manix): Nix search.
* [nvim-lint](https://github.com/mfussenegger/nvim-lint): As a fallback in case there are problems with haskell-language-server (e.g. in large mono repos).
* [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter): For syntax highlighting, and much more.
* [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects): For TreeSitter-based textobjects.

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center"><a href="https://github.com/fabfianda"><img src="https://avatars.githubusercontent.com/u/275653?v=4?s=100" width="100px;" alt="fabfianda"/><br /><sub><b>fabfianda</b></sub></a><br /><a href="https://github.com/MrcJkb/haskell-tools.nvim/commits?author=fabfianda" title="Documentation">📖</a></td>
      <td align="center"><a href="https://github.com/MangoIV"><img src="https://avatars.githubusercontent.com/u/40720523?v=4?s=100" width="100px;" alt="Mango The Fourth"/><br /><sub><b>Mango The Fourth</b></sub></a><br /><a href="#infra-MangoIV" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a></td>
      <td align="center"><a href="https://github.com/yen3"><img src="https://avatars.githubusercontent.com/u/387292?v=4?s=100" width="100px;" alt="Yen3"/><br /><sub><b>Yen3</b></sub></a><br /><a href="https://github.com/MrcJkb/haskell-tools.nvim/commits?author=yen3" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!

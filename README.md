<!-- markdownlint-disable -->
<br />
<div align="center">
  <a href="https://github.com/mrcjkb/haskell-tools.nvim">
    <img src="./nvim-haskell.svg" alt="haskell-tools.nvim">
  </a>
  <p align="center">
    <a href="https://github.com/mrcjkb/haskell-tools.nvim/issues">Report Bug</a>
  </p>
  <p>
    <strong>
      Supercharge your Haskell experience in <a href="https://neovim.io/">Neovim</a>!
    </strong>
  </p>
  <p>🦥</p>
</div>
<!-- markdownlint-restore -->

[![Neovim][neovim-shield]][neovim-url]
[![Lua][lua-shield]][lua-url]
[![Haskell][haskell-shield]][haskell-url]
[![Nix][nix-shield]][nix-url]

[![GPL2 License][license-shield]][license-url]
[![Issues][issues-shield]][issues-url]
[![Build Status][ci-shield]][ci-url]
[![LuaRocks][luarocks-shield]][luarocks-url]

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-13-orange.svg?style=for-the-badge)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

## Quick Links

- [Installation](#installation)
- [Quick Setup](#quick-setup)
- [Features](#features)
- [Advanced configuration](#advanced-configuration)
  - [Available functions and commands](#available-functions-and-commands)
  - [Telescope extension](#telescope-extension)
- [Troubleshooting](#troubleshooting)
- [Recommendations](#recommendations)
- [Contributing](./CONTRIBUTING.md)

## Prerequisites

### Required

- `neovim >= 0.8`
- [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim)

### Optional

- [`haskell-language-server`](https://haskell-language-server.readthedocs.io/en/latest/installation.html)
  (recommended).
- [`telescope.nvim`](https://github.com/nvim-telescope/telescope.nvim).
- A local [`hoogle`](https://github.com/ndmitchell/hoogle/blob/master/docs/Install.md)
  installation (recommended for better hoogle search performance).
- [`fast-tags`](https://github.com/elaforge/fast-tags)
  (for automatic tag generation as a fallback for [`vim.lsp.tagfunc`](https://neovim.io/doc/user/lsp.html#vim.lsp.tagfunc())).
- [`haskell-debug-adapter`](https://github.com/phoityne/haskell-debug-adapter/) and
  [`nvim-dap`](https://github.com/mfussenegger/nvim-dap).

## Installation

This plugin is [available on LuaRocks][luarocks-url].

If you use a plugin manager that does not support LuaRocks,
you have to declare the dependencies yourself.

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

To manually generate documentation, use `:helptags ALL`.

>**Note**
>
> For NixOS users with flakes enabled, this project provides outputs in the
> form of a package and an overlay; use it as you wish in your NixOS or
> home-manager configuration.
> It is also available in `nixpkgs`.

## Quick Setup

This plugin automatically configures the `haskell-language-server` builtin LSP
client and integrates with other haskell tools.
See the [Features](#features) section for more info.

>**Warning**
>
> Do not call the [`nvim-lspconfig.hls`](https://github.com/neovim/nvim-lspconfig)
> setup or set up the lsp manually, as doing so may cause conflicts.

To get started quickly with the default setup, add the following to `~/.config/nvim/ftplugin/haskell.lua`[^1]:

[^1]: See [`:help base-directories`](https://neovim.io/doc/user/starting.html#base-directories)

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
      vim.keymap.set('n', '<space>ea', ht.lsp.buf_eval_all, opts)
    end,
  },
}

-- Suggested keymaps that do not depend on haskell-language-server:
local bufnr = vim.api.nvim_get_current_buf()
-- set buffer = bufnr in ftplugin/haskell.lua
local opts = { noremap = true, silent = true, buffer = bufnr }

-- Toggle a GHCi repl for the current package
vim.keymap.set('n', '<leader>rr', ht.repl.toggle, opts)
-- Toggle a GHCi repl for the current buffer
vim.keymap.set('n', '<leader>rf', function()
  ht.repl.toggle(vim.api.nvim_buf_get_name(0))
end, def_opts)
vim.keymap.set('n', '<leader>rq', ht.repl.quit, opts)

-- Detect nvim-dap launch configurations
-- (requires nvim-dap and haskell-debug-adapter)
ht.dap.discover_configurations(bufnr)
```

>**Note**
>
> - For more LSP related keymaps, [see the `nvim-lspconfig` suggestions](https://github.com/neovim/nvim-lspconfig#suggested-configuration).
> - If using a local `hoogle` installation, [follow these instructions](https://github.com/ndmitchell/hoogle/blob/master/docs/Install.md#generate-a-hoogle-database)
to generate a database.
> - If you prefer, you can instead call `require('haskell-tools').setup {}` with
>   the same options as `start_or_attach()` in your Neovim config.
>   In this case, `haskell-tools.nvim` will set up filetype autocommands for you.

## Features

- [x] **Set up a `haskell-language-server` client.**
- [x] **Dynamically load `haskell-language-server` settings per project
  from JSON files.**
- [x] **Clean shutdown of language server on exit to prevent corrupted files**
      ([see ghc #14533](https://gitlab.haskell.org/ghc/ghc/-/issues/14533)).
- [x] **Automatically adds capabilities for the following plugins, if loaded:**
  - [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp)
    (provides completion sources for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)).
  - [nvim-lsp-selection-range](https://github.com/camilledejoye/nvim-lsp-selection-range)
    (Adds haskell-specific [expand selection](https://haskell-language-server.readthedocs.io/en/latest/features.html#selection-range)
    support).
- [x] **Automatically refreshes code lenses by default,**
      which `haskell-language-server` heavily relies on. [Can be disabled.](#advanced-configuration)

![codeLens](https://user-images.githubusercontent.com/12857160/219738949-c20ed266-3b2d-441e-82fe-faf50f5c582a.gif)

- [x] **Evaluate all code snippets at once**

`haskell-language-server` can evaluate code snippets using code lenses.
`haskell-tools.nvim` provides a `require('haskell-tools').lsp.buf_eval_all()`
shortcut to evaluate all of them at once.

![evalAll](https://user-images.githubusercontent.com/12857160/219743339-e7b7f4e0-478b-4310-a903-36d0a5564937.gif)

- [x] **Hoogle-search for signature**

- Search for the type signature under the cursor.
- Falls back to the word under the cursor if the type signature cannot be determined.
- Telescope keymaps:
  - `<CR>` to copy the selected entry (`<name> :: <signature>`) to the clipboard.
  - `<C-b>` to open the selected entry's Hackage URL in a browser.
  - `<C-r>` to replace the word under the cursor with the selected entry.

```lua
require('haskell-tools').hoogle.hoogle_signature()
```

![hoogleSig](https://user-images.githubusercontent.com/12857160/219745914-505a8fc8-9cb9-49fe-b763-a0dea2a3420b.gif)

- [x] **Hole-driven development powered by Hoogle**

With the `<C-r>` keymap,
the Hoogle search telescope integration can be used to fill holes.

![hoogleHole](https://user-images.githubusercontent.com/12857160/219751911-f45e4131-afad-47b3-b016-1d341c71c114.gif)

- [x] **GHCi repl**

Start a GHCi repl for the current project / buffer.

- Automagically detects the appropriate command (`cabal new-repl`, `stack ghci`
  or `ghci`) for your project.
- Choose between a builtin handler or [`toggleterm.nvim`](https://github.com/akinsho/toggleterm.nvim).
- Dynamically create a repl command for [`iron.nvim`](https://github.com/hkupty/iron.nvim)
  (see [advanced configuration](#advanced-configuration)).
- Interact with the repl from within Haskell files using a lua API.

![repl](https://user-images.githubusercontent.com/12857160/219758588-68f3c06f-5804-4279-b23d-1bdcc050d892.gif)

- [x] **Open project/package files for the current buffer**

![commands](https://user-images.githubusercontent.com/12857160/219760916-06785cd5-f90a-4bb9-9ca8-94edbd655d46.gif)

- [x] **Hover actions**

Inspired by [rust-tools.nvim](https://github.com/simrat39/rust-tools.nvim),
this plugin adds the following hover actions (if available):

- Hoogle search.
- Open documentation in browser.
- Open source in browser.
- Go to definition.
- Go to type definition.
- Find references.

Additionally, the default behaviour of stylizing markdown is disabled.
And the hover buffer's filetype is set to markdown,
so that [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
users can benefit from syntax highlighting of code snippets.

![hoverActions](https://user-images.githubusercontent.com/12857160/219763211-61fc4207-4300-41f2-99c4-6a420cf940f2.gif)

- [x] **Automatically generate tags**

On attaching, Neovim's LSP client will set up [`tagfunc`](https://neovim.io/doc/user/lsp.html#vim.lsp.tagfunc())
to query the language server for locations to jump to.
If no location is found, it will fall back to a `tags` file.

If [`fast-tags`](https://github.com/elaforge/fast-tags) is installed,
this plugin will set up `autocmd`s to automatically generate tags:

- For the whole project, when starting a session.
- For the current (sub)package, when writing a file.

This feature can be tweaked or disabled in the [advanced configuration](#advanced-configuration).

- [x] **Auto-detect `haskell-debug-adapter` configurations**

If the [`nvim-dap`](https://github.com/mfussenegger/nvim-dap) plugin is installed,
you can use `haskell-tools.nvim` to auto-detect [`haskell-debug-adapter`](https://hackage.haskell.org/package/haskell-debug-adapter)
configurations.

![dap](https://user-images.githubusercontent.com/12857160/232348888-4fea5393-d624-417e-b994-6eb44113a3d9.gif)

>**Note**
>
>`haskell-debug-adapter` is an experimental design and implementation of
>a debug adapter for Haskell.

- [ ] **Planned**

For planned features, refer to the [issues](https://github.com/MrcJkb/haskell-tools.nvim/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement).

## Advanced configuration

To modify the default configs, call

```lua
-- defaults
require('haskell-tools').start_or_attach {
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
      -- Whether to disable haskell-tools hover
      -- and use the builtin lsp's default handler
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
      -- Treesitter syntax highligting for Haskell snippets
      -- if nvim-treesitter is installed
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
      -- Which backend to prefer if both stack and cabal files are present
      prefer = vim.fn.executable('stack') and 'stack' or 'cabal',
      builtin = {
        create_repl_window = function(view)
          -- create_repl_split | create_repl_vsplit | create_repl_tabnew | create_repl_cur_win
          return view.create_repl_split { size = vim.o.lines / 3 }
        end
      },
      -- Can be overriden to either `true` or `false`.
      -- The default behaviour depends on the handler.
      auto_focus = nil,
    },
    -- Set up autocmds to generate tags (using fast-tags)
    -- e.g. so that `vim.lsp.tagfunc` can fall back to Haskell tags
    tags = {
      enable = vim.fn.executable('fast-tags') == 1,
      -- Events to trigger package tag generation
      package_events = { 'BufWritePost' },
    },
    dap = {
      cmd = { 'haskell-debug-adapter' },
    },
  },
  hls = { -- LSP client options
    -- ...
    default_settings = {
      haskell = { -- haskell-language-server options
        formattingProvider = 'ormolu',
        -- Setting this to true could have a performance impact on large mono repos.
        checkProject = true,
        -- ...
      }
    }
  }
}
```

- The full list of defaults [can be found here](./lua/haskell-tools/config.lua).
- To view all available language server settings
  (including those not set by this plugin), run `haskell-language-server generate-default-config`.
- For detailed descriptions of the configs,
  look at the [haskell-language-server documentation](https://haskell-language-server.readthedocs.io/en/latest/configuration.html).

### How to dynamically load different `haskell-language-server` settings per project

By default, this plugin will look for a `hls.json` file in the project root directory,
and attempt to load it.
If the file does not exist, or it can't be decoded,
the `hls.default_settings` will be used.

You can change this behaviour with the `hls.settings` config:

```lua
local ht = require('haskell-tools')
ht.start_or_attach {
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
For example, the `importLens` could be annoying if you prefer to import
everything or use a custom prelude.
Individual code lenses can be turned off by disabling them in the respective
plugin configurations:

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
You can either attach the LSP client in a `~/.config/nvim/ftplugin/cabal.lua`
file[^1], or call `haskell-tools.setup()`.

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

### Create `haskell-debug-adapter` launch configurations

There are two ways this plugin will detect `haskell-debug-adapter` launch configurations:

1. Automatically, by parsing Cabal or Stack project files.
1. By loading a [`launch.json`](https://github.com/phoityne/hdx4vsc/tree/master/configs)
  file in the project root.

### Available functions and commands

For a complete overview, enter `:help haskell-tools` in Neovim.

#### LSP

- `:HlsStart` - Start the LSP client.
- `:HlsStop` - Stop the LSP client.
- `:HlsRestart` - Restart the LSP client.

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

- `:HsProjectFile` - Open the project file for the current buffer
  (cabal.project or stack.yaml).
- `:HsPackageYaml` - Open the package.yaml file for the current buffer.
- `:HsPackageCabal` - Open the *.cabal file for the current buffer.

```lua
local ht = require('haskell-tools')
-- Open the project file for the current buffer (cabal.project or stack.yaml)
ht.project.open_project_file()

-- Open the package.yaml file for the current buffer
ht.project.open_package_yaml()

-- Open the *.cabal file for the current buffer
ht.project.open_package_cabal()

-- Search for files within the current (sub)package
---@param opts: Optional telescope.nvim `find_files` options
ht.project.telescope_package_files(opts)
-- Live grep within the current (sub)package
---@param opts: Optional telescope.nvim `live_grep` options
ht.project.telescope_package_grep(opts)
```

#### Tags

The following functions depend on [`fast-tags`](https://github.com/elaforge/fast-tags).

```lua
local ht = require('haskell-tools')

-- Generate tags for the whole project
---@param path: An optional file path, defaults to the current buffer
---@param opts: Optional options:
---@param opts.refresh: Whether to refresh tags
--- if they have already been generated for a project
ht.tags.generate_project_tags(path, opts)

-- Generate tags for the whole project
---@param path: An optional file path, defaults to the current buffer
ht.tags.generate_package_tags(path)
```

### Telescope extension

If [`telescope.nvim`](https://github.com/nvim-telescope/telescope.nvim) is installed,
`haskell-tools.nvim` will register the `ht` extenstion
with the following commands:

- `:Telescope ht package_files` - Search for files within the current (sub)package.
- `:Telescope ht package_hsfiles` - Search for Haskell files within the current (sub)package.
- `:Telescope ht package_grep` - Live grep within the current (sub)package.
- `:Telescope ht package_hsgrep` - Live grep Haskell files within the current (sub)package.
- `:Telescope ht hoogle_signature` - Run a Hoogle search for the type signature
  under the cursor.

To load the extension, call

```lua
require('telescope').load_extension('ht')
```

#### DAP

```lua
local ht = require('haskell-tools')

---@param bufnr integer The buffer number
---@param opts table? Optional
---@param opts.autodetect: (boolean)
--- Whether to auto-detect launch configurations
---@param opts.settings_file_pattern: (string)
--- File name or pattern to search for. Defaults to 'launch.json'
ht.dap.discover_configurations(bufnr, opts)
```

## Troubleshooting

For a health check, run `:checkhealth haskell-tools`

### LSP features not working

Check which versions of `hls` and GHC you are using
(`haskell-language-server-wrapper --version`).
Sometimes, certain features take some time to be implemented for the latest GHC versions.
You can see how well a specific GHC version is supported [here](https://haskell-language-server.readthedocs.io/en/latest/support/index.html).

### Minimal config

To troubleshoot this plugin with a minimal config in a temporary directory,
you can try [minimal.lua](./tests/minimal.lua).

```console
mkdir -p /tmp/minimal/
# The first start will install the plugins into the temporary directory
NVIM_DATA_MINIMAL=/tmp/minimal nvim -u minimal.lua
# Quit Neovim and start it up again with the plugins loaded
NVIM_DATA_MINIMAL=/tmp/minimal nvim -u minimal.lua
```

> **Note**
>
> This plugin is only tested on Linux.
> It should work on MacOS, and basic features should also work on Windows
> (since version `1.9.5`), but this has not been tested.
> Features that rely on external tools, such as `hoogle`,
> `fast-tags` or `ghci` are likely to break on non-Unix-like operating systems.

#### Logs

To enable debug logging, set the log level to `DEBUG`[^2]:

[^2]: See [`:help vim.log.levels`](https://neovim.io/doc/user/lua.html#vim.log.levels):

```lua
require('haskell-tools').start_or_attach {
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

- [neotest-haskell](https://github.com/MrcJkb/neotest-haskell):
  Interact with tests in neovim.
- [haskell-snippets.nvim](https://github.com/mrcjkb/haskell-snippets.nvim)
  Collection of Haskell snippets for [LuaSnip](https://github.com/L3MON4D3/LuaSnip).
- [telescope_hoogle](https://github.com/luc-tielen/telescope_hoogle):
  Live Hoogle search.
- [telescope-manix](https://github.com/MrcJkb/telescope-manix):
  Nix search.
- [nvim-lint](https://github.com/mfussenegger/nvim-lint):
  As a fallback in case there are problems with haskell-language-server
  (e.g. in large mono repos).
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter):
  For syntax highlighting, and much more.
- [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects):
  For TreeSitter-based textobjects.

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/fabfianda"><img src="https://avatars.githubusercontent.com/u/275653?v=4?s=100" width="100px;" alt="fabfianda"/><br /><sub><b>fabfianda</b></sub></a><br /><a href="https://github.com/mrcjkb/haskell-tools.nvim/commits?author=fabfianda" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/MangoIV"><img src="https://avatars.githubusercontent.com/u/40720523?v=4?s=100" width="100px;" alt="Mango The Fourth"/><br /><sub><b>Mango The Fourth</b></sub></a><br /><a href="#infra-MangoIV" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/yen3"><img src="https://avatars.githubusercontent.com/u/387292?v=4?s=100" width="100px;" alt="Yen3"/><br /><sub><b>Yen3</b></sub></a><br /><a href="https://github.com/mrcjkb/haskell-tools.nvim/commits?author=yen3" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/sebastianselander"><img src="https://avatars.githubusercontent.com/u/70573736?v=4?s=100" width="100px;" alt="Sebastian Selander"/><br /><sub><b>Sebastian Selander</b></sub></a><br /><a href="https://github.com/mrcjkb/haskell-tools.nvim/commits?author=sebastianselander" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/typesafety"><img src="https://avatars.githubusercontent.com/u/21952939?v=4?s=100" width="100px;" alt="Thomas Li"/><br /><sub><b>Thomas Li</b></sub></a><br /><a href="https://github.com/mrcjkb/haskell-tools.nvim/commits?author=typesafety" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/teto"><img src="https://avatars.githubusercontent.com/u/886074?v=4?s=100" width="100px;" alt="Matthieu Coudron"/><br /><sub><b>Matthieu Coudron</b></sub></a><br /><a href="#infra-teto" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/mrcjkb/haskell-tools.nvim/issues?q=author%3Ateto" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://mzchael.com"><img src="https://avatars.githubusercontent.com/u/44309097?v=4?s=100" width="100px;" alt="Michael Lan"/><br /><sub><b>Michael Lan</b></sub></a><br /><a href="https://github.com/mrcjkb/haskell-tools.nvim/issues?q=author%3Amizlan" title="Bug reports">🐛</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="http://dhruvas.vercel.app"><img src="https://avatars.githubusercontent.com/u/66675022?v=4?s=100" width="100px;" alt="Dhruva Srinivas"/><br /><sub><b>Dhruva Srinivas</b></sub></a><br /><a href="https://github.com/mrcjkb/haskell-tools.nvim/commits?author=carrotfarmer" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://gacallea.info/"><img src="https://avatars.githubusercontent.com/u/3269984?v=4?s=100" width="100px;" alt="Andrea Callea (he/him/his)"/><br /><sub><b>Andrea Callea (he/him/his)</b></sub></a><br /><a href="https://github.com/mrcjkb/haskell-tools.nvim/issues?q=author%3Agacallea" title="Bug reports">🐛</a> <a href="#userTesting-gacallea" title="User Testing">📓</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://monique.dev"><img src="https://avatars.githubusercontent.com/u/70070?v=4?s=100" width="100px;" alt="Cyber Oliveira"/><br /><sub><b>Cyber Oliveira</b></sub></a><br /><a href="https://github.com/mrcjkb/haskell-tools.nvim/issues?q=author%3Amoniquelive" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Br3akp01nt"><img src="https://avatars.githubusercontent.com/u/91327649?v=4?s=100" width="100px;" alt="Br3akp01nt"/><br /><sub><b>Br3akp01nt</b></sub></a><br /><a href="#userTesting-Br3akp01nt" title="User Testing">📓</a> <a href="https://github.com/mrcjkb/haskell-tools.nvim/issues?q=author%3ABr3akp01nt" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Alper-Celik"><img src="https://avatars.githubusercontent.com/u/110625473?v=4?s=100" width="100px;" alt="Alper Çelik"/><br /><sub><b>Alper Çelik</b></sub></a><br /><a href="https://github.com/mrcjkb/haskell-tools.nvim/issues?q=author%3AAlper-Celik" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mauke"><img src="https://avatars.githubusercontent.com/u/278465?v=4?s=100" width="100px;" alt="mauke"/><br /><sub><b>mauke</b></sub></a><br /><a href="https://github.com/mrcjkb/haskell-tools.nvim/commits?author=mauke" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors)
specification. Contributions of any kind welcome!

<!-- MARKDOWN LNIKS & IMAGES -->
[neovim-shield]: https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white
[neovim-url]: https://neovim.io/
[lua-shield]: https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white
[lua-url]: https://www.lua.org/
[nix-shield]: https://img.shields.io/badge/nix-0175C2?style=for-the-badge&logo=NixOS&logoColor=white
[nix-url]: https://nixos.org/
[haskell-shield]: https://img.shields.io/badge/Haskell-5e5086?style=for-the-badge&logo=haskell&logoColor=white
[haskell-url]: https://www.haskell.org/
[issues-shield]: https://img.shields.io/github/issues/mrcjkb/haskell-tools.nvim.svg?style=for-the-badge
[issues-url]: https://github.com/mrcjkb/haskell-tools.nvim/issues
[license-shield]: https://img.shields.io/github/license/mrcjkb/haskell-tools.nvim.svg?style=for-the-badge
[license-url]: https://github.com/mrcjkb/haskell-tools.nvim/blob/master/LICENSE
[ci-shield]: https://img.shields.io/github/actions/workflow/status/mrcjkb/haskell-tools.nvim/nix-build.yml?style=for-the-badge
[ci-url]: https://github.com/mrcjkb/haskell-tools.nvim/actions/workflows/nix-build.yml
[luarocks-shield]: https://img.shields.io/luarocks/v/MrcJkb/haskell-tools.nvim?logo=lua&color=purple&style=for-the-badge
[luarocks-url]: https://luarocks.org/modules/MrcJkb/haskell-tools.nvim

<!-- markdownlint-disable -->
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.10] - 2024-05-30

### Fixed

- LSP: Force-extend Neovim's default client capabilities
  with detected plugin capabilities, to ensure plugin capability
  extensions take precedence in case of conflict.

## [3.1.9] - 2024-05-04

### Changed

- Add compatibility layers for Neovim API that has been
  deprecated in Neovim nightly.

## [3.1.8] - 2024-02-23

### Reverted

- Don't run `ftplugin` more than once on the same buffer.
  This prevented the LSP client from reattaching when
  running `:e`.

## [3.1.7] - 2024-02-20

### Fixed

- Missing vimdoc in generated helpfile.

## [3.1.6] - 2024-01-27

### Performance

- Don't run `ftplugin` more than once on the same buffer.

## [3.1.5] - 2024-01-25

### Changed

- Initialization: Lazy-require `haskell-tools` fields.
  This prevents configs from being initialized early if
  calling `require('haskell-tools')` before setting
  `vim.g.haskell_tools`.

## [3.1.4] - 2024-01-20

### Fixed

- Hoogle: Don't escape URLs when opening in browser [[#336](https://github.com/mrcjkb/haskell-tools.nvim/issues/336)].

## [3.1.3] - 2024-01-11

### Fixed

- LSP: Add safety to `:HlsRestart` command,
  to prevent it from retrying indefinitely.

## [3.1.2] - 2024-01-10

### Fixed

- Hoogle (web): Error handling for invalid `curl` output [[#322](https://github.com/mrcjkb/haskell-tools.nvim/issues/322)].

## [3.1.1] - 2023-12-22

### Fixed

- Health: Only report error if `lspconfig.hls` has been set up,
  not other configurations.

## [3.1.0] - 2023-12-18

### Added

- Health: Warn if there are unrecognized configs in `vim.g.haskell_tools`.

### Fixed

- Health: Check if `vim.g.haskell_tools` is set,
  but hasn't been sourced before initialization.
- Hoogle (web): Make `curl` silent.

## [3.0.2] - 2023-11-25

### Fixed

- Remove default setting for `cabalFormattingProvider`,
  falling back to haskell-language-server's default.

## [3.0.1] - 2023-11-23

### Fixed

- Don't attempt to generate project tags if no project root is found.

## [3.0.0] - 2023-10-28

### Changed

- Remove `plenary.nvim` dependency.
  POTENTIALLY BREAKING: This should not break anything, but removing a dependency is worth
  a major version bump, just in case.
  NOTE: `plenary.nvim` is still a dependency of `telescope.nvim`.
- POTENTIALLY BREAKING: Bump minimum Neovim version requirement to `0.9`.
  This plugin may still work with Neovim `0.8`, but its compatibility is not tested.
- New, fabulous logo.

![](https://raw.githubusercontent.com/mrcjkb/haskell-tools.nvim/e6e7afa8f9cacd4a65b7707e38feedaf64b8e21a/nvim-haskell.svg)

### Added

- Add filetype information to the LSP client [#275](https://github.com/mrcjkb/haskell-tools.nvim/issues/275).

## [2.4.0] - 2023-10-13

### Added
- `vim.g.haskell_tools` can now also be a function that returns
  a configuration table.
- `HlsLog` and `HtLog`, `HtSetLogLevel` commands.

### Fixed
- Configure `haskell-language-server` to log to a temporary file by default,
  to prevent huge log files [#264](https://github.com/mrcjkb/haskell-tools.nvim/issues/264).

### Changed
- Don't send an error notification if the name of the buffer
  cannot be determined when starting the LSP client.
- `checkhealth`: Report on whether or not `vim.g.haskell_tools` is set.

## [2.3.0] - 2023-09-20
### Added
- Health: Check for conflicting `lspconfig.hls` configuration.
- New commands: `HlsEvalAll`, `HtReplToggle`, `HtReplQuit`, `HtReplLoad`, `HtReplReload`

### Fixed
- Builtin repl: Broken toggle

## [2.2.0] - 2023-09-12
### Added
- Automatically add `foldingRange` LSP client capabilities if [`nvim-ufo`](https://github.com/kevinhwang91/nvim-ufo)
  is installed.

## [2.1.0] - 2023-09-10
### Added
- Automatically discover debug adapter launch configurations if `nvim-dap` and `haskell-debug-adapter`
  are detected.
  This can be disabled by setting the `vim.g.haskell_tools.dap.auto_discover` option to `false`.

### Fixed
- Hoogle replace (`<C-r>`) no longer switches to insert mode.

## [2.0.2] - 2023-09-02
### Fixed
- Hover: Decode url-encoded (type-)definition paths in hover actions ([#238](https://github.com/mrcjkb/haskell-tools.nvim/issues/238)).

## [2.0.1] - 2023-09-01
### Fixed
- Re-add public `haskell-tools.log` API.

## [2.0.0] - 2023-08-27
### Changed
- New, more stable architecture.
- BREAKING: Remove `setup` API.
- BREAKING: Remove `start_or_attach` API.
  `vim.g.haskell_tools` can be used for configuration instead.
- BREAKING: `haskell-tools` now
  automatically initialises and attaches when opening a Haskell or Cabal file.
  You can fine-tune this behaviour in the config.
- BREAKING: Removed `haskell-tools.dap.nvim_dap` (copy of the `dap` module).
- BREAKING configuration changes:
  - `hover.disable` has been changed to `hover.enable` for consistency.
  - `hls_log` (undocumented) has been moved to `hls.logfile`.
- Repl: Add `--ghc-option -Wwarn` to `cabal repl` command.

### Added
- Only attach cabal LSP clients if using `haskell-language-server > 1.9.0.0`.
- By default, fall back to `haskell-language-server` if `haskell-language-server-wrapper`
  is not found [#233](https://github.com/mrcjkb/haskell-tools.nvim/issues/233).

### Fixed
- LSP client: Don't fail if `hls.on_attach` fails.

## [1.11.3] - 2023-08-06
### Fixed
- Fix bug that broke codelens auto-refresh and lsp stop/restart [#229](https://github.com/mrcjkb/haskell-tools.nvim/issues/229).

## [1.11.2] - 2023-08-03
### Fixed
- Cabal: Do not advertise `server_capabilities` for `foldingRangeProvider`
  and `selectionRangeProvider` ([#223](https://github.com/mrcjkb/haskell-tools.nvim/issues/223)).
  Prevents error messages caused by plugins that provide LSP client capabilities that are
  not built-in to Neovim.

## [1.11.1] - 2023-07-17
### Fixed
- Hover: Fix error message when using go-to-definition/typeDefinition hover actions
  with neovim-nightly (10.x).

## [1.11.0] - 2023-07-05
### Changed
- Improvements to type signature detection from `textDocument/hover` docs.

### Added
- Hover: Hoogle search entries for all detected type signatures.

### Fixed
- repl: If both stack and cabal files are present, prefer stack if it is installed.
  This is configurable with the option `tools.repl.prefer`.

## [1.10.2] - 2023-05-22
### Fixed
- Do not use deprecated health check API in neovim > 0.9.
- Health checks: Parsing of dependency versions without a newline causes error message.

## [1.10.1] - 2023-05-4
### Fixed
- Typo in `dap` module potentially leading to errors on warning logs.

## [1.10.0] - 2023-04-17
### Added
- Support for [`nvim-dap`](https://github.com/mfussenegger/nvim-dap)
  with [`haskell-debug-adapter`](https://hackage.haskell.org/package/haskell-debug-adapter),
  an experimental debug adapter for Haskell.

## [1.9.7] - 2023-04-15
### Fixed
- Remove some prints.

## [1.9.6] - 2023-04-09
### Fixed
- Loading files with `'builtin'` repl handler (#177).

## [1.9.5] - 2023-04-06
### Fixed
- Prevent infinite recursion on strange operating systems in path iteration (#171).

## [1.9.4] - 2023-04-02
### Fixed
- Repl: Detection of single-package cabal projects.
- Hoogle (web): URL escaping.
### Changed
- Remove rockspec (not needed, due to luarocks-tag-release-workflow).
- `HsProjectFile`: Try `stack.yml` first, then fall back to `cabal.project` and then to `*.cabal`.

## [1.9.3] - 2023-03-08
### Fixed
- Silent failure and unexpected error message if `haskell-language-server` executable is not found (#154).

## [1.9.2] - 2023-03-06
### Fixed
- Initialisation of client capabilities when `nvim-cmp` is not installed.

## [1.9.1] - 2023-02-20
### Fixed
- Typo in the logfile name.

## [1.9.0] - 2023-02-17
### Added
- LSP: Evaluate all code snippets in comments at once.
- Support setup in ftplugin/haskell.lua.
### Fixed
- Check if attached LSP client supports codeLens before refreshing.
- Telescope extension can now be registered before haskell-tools has been setup.

## [1.8.0] - 2023-02-03
### Changed
- Set up LSP client without `nvim-lspconfig` (removes the dependency).
- Hover actions: Shorten locations relative to file, package or project.
- Only show definition/typeDefinition hover actions if they are in different locations.
### Added
- Rockspec for automatic dependency management by LuaRocks-compatible plugin managers.
- LuaRocks tag release workflow.
- `HlsStart`, `HlsStop` and `HlsRestart` commands.
- Dynamically load `haskell-language-server` settings JSON from project root, if available.
- Health checks, runnable with `:checkhealth haskell-tools`.
- Validate configs during setup.
- Hover action for `textDocument/typeDefinition`.

## [1.7.0] - 2023-01-27
### Fixed
- Fall back to hoogle browser search if telescope is not set up.
### Changed
- Do not set a default layout for telescope Hoogle search.

## [1.6.0] - 2023-01-21
### Added
- Ability to temporarily set the log level via `ht.log.set_level(level)`.
- `tools.repl.auto_focus` option.
- Vimdocs
### Fixed
- repl.toggleterm: Do not close on failure.
- repl: Quote file names.

## [1.5.1] - 2023-01-08
### Fixed
- Set default log level to `vim.log.levels.WARN`.

## [1.5.0] - 2023-01-08
### Added
- Support for `hls-cabal-plugin` and `hls-cabal-fmt` plugins.
- Add logging
### Fixed
- Packer init in minimal config for reproducing issues locally.

## [1.4.4] - 2022-12-20
### Fixed
- Pass the custom options to hoogle telescope, so that users' custom telescope
  themes, etc. can be supported.

## [1.4.3] - 2022-12-06
### Fixed
- Error message shown if hoogle is installed, but telescope is missing

## [1.4.2] - 2022-11-19
### Fixed
- Bug causing hls to always use default settings
- Prevent concatenatenation with nil on tags generation if package root can't be found

## [1.4.1] - 2022-11-19
### Fixed
- Project tags not being generated on session start

## [1.4.0] - 2022-11-18
### Added
- Automatically generate project & package tags if [`fast-tags`](https://github.com/elaforge/fast-tags) is installed.
- Configuration for falling back to hoogle search if `vim.lsp.definition` fails.
- Nix flake setup.
### Fixed
- Hover actions improvements:
  - Always show 'Go to definition' if location is found.
  - Offer Hoogle search for package <> name if location is not found.
- Hoogle search: Replace multiple whitespace with single space.
- CodeLens: Only auto-refresh on buffer the LSP client has attached to.

## [1.3.0] - 2022-11-14
### Added
- Hover actions
- Command for loading files into the repl.
- Ability to paste multiple valid Haskell lines into the repl.
- `repl.paste_info` and `repl.cword_info` functions.
- Telescope live_grep and find_files commands for current package
- Register Telescope extension
### Fixed
- Fix broken `<C-b>` keymap to open Hoogle entry in the browser

## [1.2.0] - 2022-11-09
### Added
- GHCi repl integration: Automagically detect the command to start GHCi and load the current buffer.
- Interact with the GHCi repl from any buffer using lua functions.
- `:HsProjectFile`, `:HsPackageYaml` and `:HsPackageCabal` commands to open project/package files for the current buffer.
### Changed
- Do not close Hoogle Telescope prompt on `<C-b>` (open hackage docs in browser).
### Fixed
- Auto-refresh code lenses only for Haskell files

## [1.1.0] - 2022-10-29
### Added
- Keymap to replace word under cursor when hoogling type signature
### Fixed
- Fix broken telescope hoogle_attach_mappings call, causing error message on entry selection

## [1.0.0] - 2022-10-25
### Added
- Hoogle search (BREAKING CHANGE: Depends on [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim))
- Hoogle search for signature under cursor (telescope-local, telescope-web or browser)
- Automatic registration of selection range capabilities if [nvim-lsp-selection-range](https://github.com/camilledejoye/nvim-lsp-selection-range) is loaded.

## [0.2.0] - 2022-10-18
### Added
- Basic automatic codeLens refresh (can be disabled by setting `tools.codeLens.autoRefresh = false`).
### Fixed
- Clean exit of language server on quit.

## [0.1.0] - 2022-10-15
### Added
- Basic haskell-language-server client support on par with `nvim-lspconfig.hls`.
- Clean shutdown on exit to prevent file corruption ([see ghc #14533](https://gitlab.haskell.org/ghc/ghc/-/issues/14533)).

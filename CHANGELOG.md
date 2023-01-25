# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- Set up LSP client without `nvim-lspconfig` (removes the dependency).
### Added
- `HlsStart`, `HlsStop` and `HlsRestart` commands.

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

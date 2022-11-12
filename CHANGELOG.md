# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Command for loading files into the repl.
- Ability to paste multiple valid Haskell lines into the repl.
- `repl.paste_info` and `repl.cword_info` functions.

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

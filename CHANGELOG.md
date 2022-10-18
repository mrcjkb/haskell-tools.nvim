# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Basic automatic codeLens refresh (can be disabled by setting `tools.codeLens.autoRefresh = false`)

## [0.1.0]
### Added
- Basic haskell-language-server client support on par with `nvim-lspconfig.hls`
- Clean shutdown on exit to prevent file corruption ([see ghc #14533](https://gitlab.haskell.org/ghc/ghc/-/issues/14533))

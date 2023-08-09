---@toc haskell-tools.contents

---@mod intro Introduction
---@brief [[
---This plugin automatically configures the `haskell-language-server` builtin LSP client
---and integrates with other haskell tools.
---@brief ]]
---
---@brief [[
---WARNING:
---Do not call the `lspconfig.hls` setup or set up the lsp manually,
---as doing so may cause conflicts.
---@brief ]]
---
---@brief [[
---NOTE: This plugin is a filetype plugin.
---There is no need to call a `setup` function.
---@brief ]]

---@mod haskell-tools The haskell-tools module

---@brief [[
---Entry-point into this plugin's public API.

---@brief ]]

---@class HaskellTools
local HaskellTools = {
  lsp = require('haskell-tools.lsp'),
  hoogle = require('haskell-tools.hoogle'),
  repl = require('haskell-tools.repl'),
  project = require('haskell-tools.project'),
  tags = require('haskell-tools.tags'),
  ---@type HsDapTools | nil
  dap = require('haskell-tools.dap') or nil,
}

return HaskellTools

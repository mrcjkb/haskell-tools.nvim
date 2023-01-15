---@mod intro Introduction

---@brief [[
---This plugin automatically configures the `haskell-language-server` builtin LSP client
---and integrates with other haskell tools.
---
---Warning:
---Do not call the `lspconfig.hls` setup or set up the lsp manually,
---as doing so may cause conflicts.
---
---@brief ]]

---@mod haskell-tools The haskell-tools module

---@class haskell-tools
---@field config HaskellToolsConfig? The configuration
---@field log table? The logging module
---@field lsp table? The LSP module
---@field hoogle table? The Hoogle module
---@field repl table? The GHCi repl module
---@field project table? The project module
---@field tags table? The tags module

---Entry-point into this plugin's public API.
---
---@type haskell-tools
local ht = {
  config = nil,
  log = nil,
  lsp = nil,
  hoogle = nil,
  repl = nil,
  project = nil,
  tags = nil,
}

---Sets up the plugin.
---Must be called before using this plugin's API.
---
---@param opts HTOpts? the plugin configuration.
---@usage [[
---local ht = require('haskell-tools')
---local def_opts = { noremap = true, silent = true, }
---ht.setup {
---   hls = {
---     on_attach = function(client, bufnr)
---       --- Set keybindings, etc. here.
---     end,
---   },
--- }
---@usage ]]
---@see haskell-tools.config for the default configuration.
---@see lspconfig-keybindings for suggested keybindings by `nvim-lspconfig`.
function ht.setup(opts)
  local config = require('haskell-tools.config')
  ht.config = config
  local log = require('haskell-tools.log')
  ht.log = log
  local lsp = require('haskell-tools.lsp')
  ht.lsp = lsp
  local hoogle = require('haskell-tools.hoogle')
  ht.hoogle = hoogle
  local repl = require('haskell-tools.repl')
  ht.repl = repl
  local project = require('haskell-tools.project')
  ht.project = project
  local tags = require('haskell-tools.tags')
  ht.tags = tags

  config.setup(opts)
  log.setup()
  log.debug { 'Config', config.options }
  lsp.setup()
  hoogle.setup()
  repl.setup()
  project.setup()
  tags.setup()
end

return ht

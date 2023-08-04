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

local config = require('haskell-tools.config')

---@class HaskellTools
local HaskellTools = {
  lsp = require('haskell-tools.lsp'),
  hoogle = require('haskell-tools.hoogle'),
  repl = require('haskell-tools.repl'),
  project = require('haskell-tools.project'),
  tags = require('haskell-tools.tags'),
  dap = require('haskell-tools.dap'),
}

---Starts or attaches an LSP client to the current buffer and sets up the plugin if necessary.
---You should not need to call this function, as it will be called automatically
---when you open a Haskell or Cabal file.
---
---If you want to use it with a filetype that is not officially supported by this plugin,
---you can call it in ~/.config/nvim/ftplugin/after/<filetype>.lua
---
---@param opts nil No longer used. Set `vim.g.haskell_tools` instead
---@see haskell-tools.config for configuration options.
---@see lspconfig-keybindings for suggested keybindings by `nvim-lspconfig`.
---@see ftplugin
---@see base-directories
---@usage [[
----- In your neovim configuration, set:
---vim.g.haskell_tools = {
---   tools = {
---   -- ...
---   },
---   hls = {
---     on_attach = function(client, bufnr)
---       -- Set keybindings, etc. here.
---     end,
---     -- ...
---   },
--- }
----- In `~/.config/nvim/ftplugin/after/<filetype>.lua`, call
---local ht = require('haskell-tools')
---ht.start_or_attach()
---@usage ]]
function HaskellTools.start_or_attach(opts)
  if opts ~= nil then
    local msg = [[
      haskell-tools.nvim: start_or_attach(opts) no longer takes any arguments.
      Please use vim.g.haskell_tools to configure haskell-tools.nvim instead.
      :help haskell-tools for more info.
    ]]
    vim.notify_once(msg, vim.log.levels.WARN)
  end
  local hls_bin = config.options.hls.cmd[1]
  if vim.fn.executable(hls_bin) ~= 0 then
    HaskellTools.lsp.start()
  end
  if config.options.tools.tags.enable then
    HaskellTools.tags.generate_project_tags(nil, { refresh = false })
  end
end

return HaskellTools

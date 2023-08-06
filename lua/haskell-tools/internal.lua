---@mod haskell-tools.internal

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- The internal API for use by this plugin's ftplugins
---@brief ]]

local HTConfig = require('haskell-tools.config.internal')
local util = require('haskell-tools.util')
local HaskellTools = require('haskell-tools')

---@class InternalApi
local InternalApi = {}

---Starts or attaches an LSP client to the current buffer and sets up the plugin if necessary.
---
---@see haskell-tools.config for configuration options.
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
function InternalApi.start_or_attach()
  if util.evaluate(HTConfig.hls.auto_attach) then
    HaskellTools.lsp.start()
  end
  if util.evaluate(HTConfig.tools.tags.enable) then
    HaskellTools.tags.generate_project_tags(nil, { refresh = false })
  end
end

return InternalApi

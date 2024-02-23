---@mod haskell-tools.internal

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- The internal API for use by this plugin's ftplugins
---@brief ]]

local HTConfig = require('haskell-tools.config.internal')

---@class InternalApi
local InternalApi = {}

---@return boolean tf Is LSP supported for the current buffer?
local function buf_is_lsp_supported()
  local bufnr = vim.api.nvim_get_current_buf()
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  if not HtProjectHelpers.is_cabal_file(bufnr) then
    return true
  end
  local LspHelpers = require('haskell-tools.lsp.helpers')
  return LspHelpers.is_hls_version_with_cabal_support()
end

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
local function start_or_attach()
  local Types = require('haskell-tools.types.internal')
  local HaskellTools = require('haskell-tools')
  if Types.evaluate(HTConfig.hls.auto_attach) and buf_is_lsp_supported() then
    HaskellTools.lsp.start()
  end
  if Types.evaluate(HTConfig.tools.tags.enable) then
    HaskellTools.tags.generate_project_tags(nil, { refresh = false })
  end
end

---Auto-discover nvim-dap launch configurations (if auto-discovery is enabled)
local function dap_discover()
  local auto_discover = HTConfig.dap.auto_discover
  if not auto_discover then
    return
  elseif type(auto_discover) == 'boolean' then
    return require('haskell-tools').dap.discover_configurations()
  end
  ---@cast auto_discover AddDapConfigOpts
  local bufnr = vim.api.nvim_get_current_buf()
  require('haskell-tools').dap.discover_configurations(bufnr, auto_discover)
end

---ftplugin implementation
function InternalApi.ftplugin()
  start_or_attach()
  dap_discover()
end

return InternalApi

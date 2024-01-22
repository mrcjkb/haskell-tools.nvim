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

---@param module string
---@return table
local function lazy_require(module)
  return setmetatable({}, {
    __index = function(_, key)
      return require(module)[key]
    end,
    __newindex = function(_, key, value)
      require(module)[key] = value
    end,
  })
end

---@class HaskellTools
local HaskellTools = {
  ---@type HlsTools
  lsp = lazy_require('haskell-tools.lsp'),
  ---@type HoogleTools
  hoogle = lazy_require('haskell-tools.hoogle'),
  ---@type HsReplTools
  repl = lazy_require('haskell-tools.repl'),
  ---@type HsProjectTools
  project = lazy_require('haskell-tools.project'),
  ---@type FastTagsTools
  tags = lazy_require('haskell-tools.tags'),
  ---@type HsDapTools
  dap = lazy_require('haskell-tools.dap'),
  ---@type HaskellToolsLog
  log = lazy_require('haskell-tools.log'),
}

return HaskellTools

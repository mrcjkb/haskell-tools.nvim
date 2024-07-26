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
  ---@type haskell-tools.Hls
  lsp = lazy_require('haskell-tools.lsp'),
  ---@type haskell-tools.Hoogle
  hoogle = lazy_require('haskell-tools.hoogle'),
  ---@type haskell-tools.Repl
  repl = lazy_require('haskell-tools.repl'),
  ---@type haskell-tools.Project
  project = lazy_require('haskell-tools.project'),
  ---@type haskell-tools.FastTags
  tags = lazy_require('haskell-tools.tags'),
  ---@type haskell-tools.Dap
  dap = lazy_require('haskell-tools.dap'),
  ---@type haskell-tools.Log
  log = lazy_require('haskell-tools.log'),
}

return HaskellTools

---@mod haskell-tools.lsp.definition LSP textDocument/definition override

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local log = require('haskell-tools.log.internal')

local lsp_definition = {}

---@param opts table<string,any>|nil
---@return nil
function lsp_definition.mk_hoogle_fallback_definition_handler(opts)
  return function(_, result, ...)
    local ht = require('haskell-tools')
    if #result > 0 then
      local default_handler = vim.lsp.handlers['textDocument/definition']
      return default_handler(_, result, ...)
    end
    log.debug('Definition not found. Falling back to Hoogle search.')
    vim.notify('Definition not found. Falling back to Hoogle search...', vim.log.levels.WARN)
    ht.hoogle.hoogle_signature(opts or {})
  end
end

return lsp_definition

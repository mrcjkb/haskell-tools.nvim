---@mod haskell-tools.lsp.definition LSP textDocument/definition override

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local log = require('haskell-tools.log.internal')

local lsp_definition = {}

---@param opts table<string,any>|nil
---@return lsp.Handler
function lsp_definition.mk_hoogle_fallback_definition_handler(opts)
  return function(_, result, ctx, ...)
    local ht = require('haskell-tools')
    if #result > 0 then
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      local encoding = client and client.offset_encoding or 'utf-8'
      vim.lsp.util.show_document(result[1], encoding, { focus = true })
      return
    end
    log.debug('Definition not found. Falling back to Hoogle search.')
    vim.notify('Definition not found. Falling back to Hoogle search...', vim.log.levels.WARN)
    ht.hoogle.hoogle_signature(opts or {})
  end
end

return lsp_definition

local ht = require('haskell-tools')
local lsp_util = vim.lsp.util

local definition = {}

definition.setup = function(config)
  local orig_handler = vim.lsp.handlers['textDocument/definition']
  local function mk_hoogle_fallback_definition_handler(opts)
    return function(_, result, ...)
      if #result > 0 then
        return orig_handler(_, result, ...)
      end
      vim.notify('Definition not found. Falling back to Hoogle search...', vim.log.levels.WARN)
      ht.hoogle.hoogle_signature(opts or {})
    end
  end

  if config.hoogle_signature_fallback == true then
    local orig_buf_definition = vim.lsp.buf.definition
    vim.lsp.buf.definition = function(opts)
      local clients = vim.lsp.get_active_clients { bufnr = vim.api.nvim_get_current_buf() }
      if #clients < 1 then
        return
      end
      local client = clients[1]
      if client.name == 'hls' then
        local params = lsp_util.make_position_params()
        vim.lsp.buf_request(0, 'textDocument/definition', params, mk_hoogle_fallback_definition_handler(opts))
      else
        orig_buf_definition(opts)
      end
    end
  end
end

return definition

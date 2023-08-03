---@mod haskell-tools.lsp.util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- LSP utilities
---@brief ]]

local util = {}

---@diagnostic disable-next-line: deprecated
util.get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients

util.haskell_client_name = 'haskell-tools.nvim'
util.cabal_client_name = 'haskell-tools.nvim (cabal)'

---@param bufnr number the buffer to get clients for
---@return lsp.Client[] haskell_clients
---@see util.get_clients
function util.get_active_haskell_clients(bufnr)
  return util.get_clients { bufnr = bufnr, name = util.cabal_client_name }
end

---@param bufnr number the buffer to get clients for
---@return lsp.Client[] cabal_clinets
---@see util.get_clients
function util.get_active_cabal_clients(bufnr)
  return util.get_clients { bufnr = bufnr, name = util.cabal_client_name }
end

---@param bufnr number the buffer to get clients for
---@return lsp.Client[] ht_clients The haskell + cabal clients
---@see util.get_clients
---@see util.get_active_haskell_clients
---@see util.get_active_cabal_clients
function util.get_active_ht_clients(bufnr)
  local clients = {}
  vim.list_extend(clients, util.get_active_haskell_clients(bufnr))
  vim.list_extend(clients, util.get_active_cabal_clients(bufnr))
  return clients
end

return util

---@mod haskell-tools.lsp.util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- LSP utilities
---@brief ]]

local HtUtil = require('haskell-tools.util')

---@class LspUtil
local LspUtil = {}

LspUtil.get_clients = vim.lsp.get_clients
  ---@diagnostic disable-next-line: deprecated
  or vim.lsp.get_active_clients

LspUtil.haskell_client_name = 'haskell-tools.nvim'
LspUtil.cabal_client_name = 'haskell-tools.nvim (cabal)'

---@param bufnr number the buffer to get clients for
---@return lsp.Client[] haskell_clients
---@see util.get_clients
function LspUtil.get_active_haskell_clients(bufnr)
  return LspUtil.get_clients { bufnr = bufnr, name = LspUtil.haskell_client_name }
end

---@param bufnr number the buffer to get clients for
---@return lsp.Client[] cabal_clinets
---@see util.get_clients
function LspUtil.get_active_cabal_clients(bufnr)
  return LspUtil.get_clients { bufnr = bufnr, name = LspUtil.cabal_client_name }
end

---@param bufnr number the buffer to get clients for
---@return lsp.Client[] ht_clients The haskell + cabal clients
---@see util.get_clients
---@see util.get_active_haskell_clients
---@see util.get_active_cabal_clients
function LspUtil.get_active_ht_clients(bufnr)
  local clients = {}
  vim.list_extend(clients, LspUtil.get_active_haskell_clients(bufnr))
  vim.list_extend(clients, LspUtil.get_active_cabal_clients(bufnr))
  return clients
end

---@return string[] cmd The command to invoke haskell-language-server
LspUtil.get_hls_cmd = function()
  local HTConfig = require('haskell-tools.config.internal')
  local cmd = HtUtil.evaluate(HTConfig.hls.cmd)
  ---@cast cmd string[]
  assert(type(cmd) == 'table', 'haskell-tools: hls.cmd should evaluate to a string[]')
  assert(#cmd > 1, 'haskell-tools: hls.cmd evaluates to an empty list.')
  return cmd
end

---Returns nil if the hls version cannot be determined.
---@return number[]|nil hls_version The haskell-language-server version
local function get_hls_version()
  local hls_bin = LspUtil.get_hls_cmd()[1]
  if vim.fn.executable(hls_bin) ~= 1 then
    return nil
  end
  local handle = io.popen(hls_bin .. ' --version')
  if not handle then
    return nil
  end
  local output, error_msg = handle:read('*a')
  handle:close()
  if error_msg then
    return nil
  end
  local version_str = output:match('version:%s([^%s]*)%s.*')
  if not version_str then
    return nil
  end
  local function parse_version()
    local version = {}
    for str in string.gmatch(version_str, '([^%.]+)') do
      table.insert(version, tonumber(str))
    end
    return #version > 1 and version
  end
  local ok, version = pcall(parse_version)
  return ok and version or nil
end

---@return boolean
LspUtil.is_hls_version_with_cabal_support = function()
  local version = get_hls_version()
  -- XXX: If the version cannot be parsed, we assume it supports
  --- cabal (in case there is a newer version that we cannot
  --- parse the version from).
  return version == nil or version[1] > 1 or version[2] >= 9
end

return LspUtil

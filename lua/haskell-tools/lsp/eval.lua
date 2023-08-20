---@mod haskell-tools.lsp.eval LSP code snippet evaluation
---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- General utility functions that may need to be moded somewhere else
---@brief ]]
local eval = {}

local LspHelpers = require('haskell-tools.lsp.helpers')

---@param bufnr number The buffer number
---@return table[] The `evalCommand` lenses, in reverse order
local function get_eval_command_lenses(bufnr, exclude_lines)
  exclude_lines = exclude_lines or {}
  local eval_cmd_lenses = {}
  for _, lens in pairs(vim.lsp.codelens.get(bufnr)) do
    if lens.command.command:match('evalCommand') and not vim.tbl_contains(exclude_lines, lens.range.start.line) then
      table.insert(eval_cmd_lenses, 1, lens)
    end
  end
  return eval_cmd_lenses
end

---@param client table LSP client
---@param lens table
---@param bufnr number
---@param exclude_lines number[]|nil -- (optional) `codeLens.range.start.line`s to exclude
---@return nil
local function go(client, bufnr, lens, exclude_lines)
  local command = lens.command
  client.request_sync('workspace/executeCommand', command, 1000, bufnr)
  exclude_lines[#exclude_lines + 1] = lens.range.start.line
  local new_lenses = get_eval_command_lenses(bufnr, exclude_lines)
  if #new_lenses > 0 then
    go(client, bufnr, new_lenses[1], exclude_lines)
  end
end

---@param bufnr number|nil The buffer number
---@return nil
function eval.all(bufnr)
  bufnr = bufnr or vim.api.nvim_win_get_buf(0)
  local clients = LspHelpers.get_active_ht_clients(bufnr)
  if not clients or #clients == 0 then
    return
  end
  local client = clients[1]
  local lenses = get_eval_command_lenses(bufnr)
  if #lenses > 0 then
    go(client, bufnr, lenses[1], {})
    vim.lsp.codelens.refresh()
  end
end

return eval

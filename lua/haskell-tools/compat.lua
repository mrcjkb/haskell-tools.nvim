---@diagnostic disable: deprecated, duplicate-doc-field, duplicate-doc-alias
---@mod haskell-tools.compat Functions for backward compatibility with older Neovim versions
---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local compat = {}

compat.joinpath = vim.fs.joinpath or function(...)
  return (table.concat({ ... }, '/'):gsub('//+', '/'))
end

compat.get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients

compat.uv = vim.uv or vim.loop

--- @class vim.SystemCompleted
--- @field code integer
--- @field signal integer
--- @field stdout? string
--- @field stderr? string

--- @alias lsp.Client vim.lsp.Client

compat.system = vim.system
  -- wrapper around vim.fn.system to give it a similar API to vim.system
  or function(cmd, _, on_exit)
    local output = vim.fn.system(cmd)
    local ok = vim.v.shell_error
    ---@type vim.SystemCompleted
    local systemObj = {
      signal = 0,
      stdout = ok and (output or '') or nil,
      stderr = not ok and (output or '') or nil,
      code = vim.v.shell_error,
    }
    on_exit(systemObj)
    return systemObj
  end

---@type fun(tbl:table):table
compat.tbl_flatten = vim.iter and function(tbl)
  return vim.iter(tbl):flatten(math.huge):totable()
end or vim.tbl_flatten

return compat

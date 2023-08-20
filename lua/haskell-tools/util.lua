---@mod haskell-tools.util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- General utility functions that may need to be moded somewhere else
---@brief ]]

---@class HtUtil
local HtUtil = {}

---Trim leading and trailing whitespace.
---@param str string
---@return string trimmed
HtUtil.trim = function(str)
  return (str:match('^%s*(.*)') or str):gsub('%s*$', '')
end

---@param str string
---@return integer indent
HtUtil.get_indent = function(str)
  return #(str:match('^(%s+)%S') or '')
end

---Evaluate a value that may be a function
---or an evaluated value
---@generic T
---@param value (fun():T)|T
---@return T
HtUtil.evaluate = function(value)
  if type(value) == 'function' then
    return value()
  end
  return value
end

---@param bufnr number The buffer number
---@return boolean is_cabal_file
HtUtil.is_cabal_file = function(bufnr)
  local filetype = vim.bo[bufnr].filetype
  return filetype == 'cabal' or filetype == 'cabalproject'
end

return HtUtil

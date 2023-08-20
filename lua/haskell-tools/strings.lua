---@mod haskell-tools.strings

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Helper functions for working with strings
---@brief ]]

---@class StringsUtil
local Strings = {}

---Trim leading and trailing whitespace.
---@param str string
---@return string trimmed
Strings.trim = function(str)
  return (str:match('^%s*(.*)') or str):gsub('%s*$', '')
end

return Strings

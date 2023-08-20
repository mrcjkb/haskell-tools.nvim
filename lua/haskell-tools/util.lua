---@mod haskell-tools.util

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- General utility functions that may need to be moved somewhere else
---@brief ]]

---@class HtUtil
local HtUtil = {}

---TODO: Move this to a "strings" module?
---Trim leading and trailing whitespace.
---@param str string
---@return string trimmed
HtUtil.trim = function(str)
  return (str:match('^%s*(.*)') or str):gsub('%s*$', '')
end

return HtUtil

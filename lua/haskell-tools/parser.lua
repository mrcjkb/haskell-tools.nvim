---@mod haskell-tools.parser

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Parsing functions
---@brief ]]

---@class HtParser
local HtParser = {}

--- Pretty-print a type signature
--- @param sig string|nil The raw signature
--- @return string|nil pp_sig The pretty-printed signature
local function pp_signature(sig)
  local pp_sig = sig
    and sig
      :gsub('\n', ' ') -- join lines
      :gsub('forall .*%.%s', '') -- hoogle cannot search for `forall a.`
      :gsub('^%s*(.-)%s*$', '%1') -- trim
  return pp_sig
end

--- Get the type signature of the word under the cursor from markdown
--- @param func_name string the name of the function
--- @param docs string Markdown docs
--- @return string|nil function_signature Type signature, or the word under the cursor if none was found
--- @return string[] signatures Other type signatures returned by hls
HtParser.try_get_signatures_from_markdown = function(func_name, docs)
  local all_sigs = {}
  ---@type string|nil
  local raw_func_sig = docs:match('```haskell\n' .. func_name .. '%s::%s([^```]*)')
  for code_block in docs:gmatch('```haskell\n([^```]*)\n```') do
    ---@type string|nil
    local sig = code_block:match('::%s([^```]*)')
    local pp_sig = sig and pp_signature(sig)
    if sig and not vim.tbl_contains(all_sigs, pp_sig) then
      table.insert(all_sigs, pp_sig)
    end
  end
  return raw_func_sig and pp_signature(raw_func_sig), all_sigs
end

---@param str string
---@return integer indent
HtParser.get_indent = function(str)
  return #(str:match('^(%s+)%S') or '')
end

return HtParser

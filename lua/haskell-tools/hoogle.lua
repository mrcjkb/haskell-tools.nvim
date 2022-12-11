local ht = require('haskell-tools')
local hoogle_web = require('haskell-tools.hoogle.web')
local hoogle_local = require('haskell-tools.hoogle.local')
local deps = require('haskell-tools.deps')
local ht_util = require('haskell-tools.util')
local lsp_util = vim.lsp.util

local M = {
  handler = nil,
}

local function setup_handler(opts)
  if opts.mode == 'telescope-web' then
    M.handler = hoogle_web.telescope_search
  elseif opts.mode == 'telescope-local' then
    M.handler = hoogle_local.telescope_search
  elseif opts.mode == 'browser' then
    M.handler = hoogle_web.browser_search
  elseif opts.mode == 'auto' then
    if not deps.has_telescope() then
      M.handler = hoogle_web.browser_search
    elseif hoogle_local.has_hoogle() then
      M.handler = hoogle_local.telescope_search
    else
      M.handler = hoogle_web.telescope_search
    end
  end
end

local function on_lsp_hoogle_signature(options)
  return function(_, result, _, _)
    if not (result and result.contents) then
      vim.notify('hoogle: No information available')
      return
    end
    local signature = ht_util.get_signature_from_markdown(result.contents.value)
    if signature and signature ~= '' then
      ht.hoogle.handler(signature, options)
    end
  end
end


local function lsp_hoogle_signature(options)
  local params = lsp_util.make_position_params()
  return vim.lsp.buf_request(0, 'textDocument/hover', params, on_lsp_hoogle_signature(options))
end

-- @param table
-- @field string?: search_term - an optional search_term to search for
function M.hoogle_signature(options)
  options = options or {}
  if options.search_term then
    ht.hoogle.handler(options.search_term)
    return
  end
  local clients = vim.lsp.get_active_clients { bufnr = vim.api.nvim_get_current_buf() }
  if #clients > 0 then
    lsp_hoogle_signature(options)
  else
    local cword = vim.fn.expand('<cword>')
    ht.hoogle.handler(cword, options)
  end
end

function M.setup()
  hoogle_web.setup()
  hoogle_local.setup()
  local opts = ht.config.options.tools.hoogle
  setup_handler(opts)
end

return M

---@mod haskell-tools.hoogle haskell-tools Hoogle search

local ht = require('haskell-tools')
local hoogle_web = require('haskell-tools.hoogle.web')
local hoogle_local = require('haskell-tools.hoogle.local')
local deps = require('haskell-tools.deps')
local ht_util = require('haskell-tools.util')
local lsp_util = vim.lsp.util

---@class HaskellToolsHoogle
---@field hoogle_signature function Hoogle search for a symbol's type signature
---@field setup function
---@field handler unknown the internal handler

---@type HaskellToolsHoogle
local hoogle = {
  handler = nil,
}

local function set_web_handler()
  hoogle.handler = hoogle_web.telescope_search
  ht.log.debug('hoogle.handler = telescope-web')
end

local function set_local_handler()
  hoogle.handler = hoogle_local.telescope_search
  ht.log.debug('hoogle.handler = telescope-local')
end

local function set_browser_handler()
  hoogle.handler = hoogle_web.browser_search
  ht.log.debug('hoogle.handler = browser')
end

local function setup_handler(opts)
  if opts.mode == 'telescope-web' then
    set_web_handler()
  elseif opts.mode == 'telescope-local' then
    set_local_handler()
  elseif opts.mode == 'browser' then
    set_browser_handler()
  elseif opts.mode == 'auto' then
    if not deps.has_telescope() then
      set_browser_handler()
    elseif hoogle_local.has_hoogle() then
      set_local_handler()
    else
      set_web_handler()
    end
  end
end

local function mk_lsp_hoogle_signature_handler(options)
  return function(_, result, _, _)
    if not (result and result.contents) then
      vim.notify('hoogle: No information available')
      return
    end
    local signature = ht_util.get_signature_from_markdown(result.contents.value)
    ht.log.debug { 'Hoogle LSP signature search', signature }
    if signature and signature ~= '' then
      ht.hoogle.handler(signature, options)
    end
  end
end

local function lsp_hoogle_signature(options)
  local params = lsp_util.make_position_params()
  return vim.lsp.buf_request(0, 'textDocument/hover', params, mk_lsp_hoogle_signature_handler(options))
end

--- @param options table? Includes the `search_term` and options to pass to the telescope picker (if available)
function hoogle.hoogle_signature(options)
  options = options or {}
  ht.log.debug { 'Hoogle signature search options', options }
  if options.search_term then
    ht.hoogle.handler(options.search_term)
    return
  end
  local clients = vim.lsp.get_active_clients { bufnr = vim.api.nvim_get_current_buf() }
  if #clients > 0 then
    lsp_hoogle_signature(options)
  else
    ht.log.debug('Hoogle signature search: No clients attached. Falling back to <cword>.')
    local cword = vim.fn.expand('<cword>')
    ht.hoogle.handler(cword, options)
  end
end

--- Setup the Hoogle module. Called by the haskell-tools setup.
function hoogle.setup()
  ht.log.debug('Hoogle setup...')
  hoogle_web.setup()
  hoogle_local.setup()
  local opts = ht.config.options.tools.hoogle
  setup_handler(opts)
end

return hoogle

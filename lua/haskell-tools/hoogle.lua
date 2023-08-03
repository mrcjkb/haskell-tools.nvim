---@mod haskell-tools.hoogle haskell-tools Hoogle search

local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')
local ht_util = require('haskell-tools.util')
local ht_lsp_util = require('haskell-tools.lsp.util')
local lsp_util = vim.lsp.util

local handler = function(_, _)
  ht.log.error('Hoogle search called without a handler.')
end

local hoogle = {}

---@param options table
---@return fun(err: lsp.ResponseError|nil, result: any, context: lsp.HandlerContext, config: table|nil)
local function mk_lsp_hoogle_signature_handler(options)
  return function(_, result, _, _)
    if not (result and result.contents) then
      vim.notify('hoogle: No information available')
      return
    end
    local func_name = vim.fn.expand('<cword>')
    local signature_or_func_name = ht_util.try_get_signatures_from_markdown(func_name, result.contents.value)
      or func_name
    ht.log.debug { 'Hoogle LSP signature search', signature_or_func_name }
    if signature_or_func_name ~= '' then
      handler(signature_or_func_name, options)
    end
  end
end

---@param options table
local function lsp_hoogle_signature(options)
  local params = lsp_util.make_position_params()
  return vim.lsp.buf_request(0, 'textDocument/hover', params, mk_lsp_hoogle_signature_handler(options))
end

---@param options table<string,any>|nil Includes the `search_term` and options to pass to the telescope picker (if available)
---@return nil
function hoogle.hoogle_signature(options)
  options = options or {}
  ht.log.debug { 'Hoogle signature search options', options }
  if options.search_term then
    handler(options.search_term)
    return
  end
  local clients = ht_lsp_util.get_clients { bufnr = vim.api.nvim_get_current_buf() }
  if #clients > 0 then
    lsp_hoogle_signature(options)
  else
    ht.log.debug('Hoogle signature search: No clients attached. Falling back to <cword>.')
    local cword = vim.fn.expand('<cword>')
    handler(cword, options)
  end
end

---Setup the Hoogle module. Called by the haskell-tools setup.
---@return nil
function hoogle.setup()
  ht.log.debug('Hoogle setup...')
  local opts = ht.config.options.tools.hoogle
  local hoogle_web = require('haskell-tools.hoogle.web')
  local hoogle_local = require('haskell-tools.hoogle.local')

  ---@return nil
  local function set_web_handler()
    handler = hoogle_web.telescope_search
    ht.log.debug('handler = telescope-web')
  end

  ---@return nil
  local function set_local_handler()
    handler = hoogle_local.telescope_search
    ht.log.debug('handler = telescope-local')
  end

  ---@return nil
  local function set_browser_handler()
    handler = hoogle_web.browser_search
    ht.log.debug('handler = browser')
  end

  if opts.mode == 'telescope-web' then
    set_web_handler()
  elseif opts.mode == 'telescope-local' then
    if not hoogle_local.has_hoogle() then
      local msg = 'handler set to "telescope-local" but no hoogle executable found.'
      ht.log.warn(msg)
      vim.notify('haskell-tools.hoogle: ' .. msg, vim.log.levels.WARN)
      set_web_handler()
      return
    end
    if not deps.has_telescope() then
      local msg = 'handler set to "telescope-local" but telescope.nvim is not installed.'
      ht.log.warn(msg)
      vim.notify('haskell-tools.hoogle: ' .. msg, vim.log.levels.WARN)
      set_web_handler()
      return
    end
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

return hoogle

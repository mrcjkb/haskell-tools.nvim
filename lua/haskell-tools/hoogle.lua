---@mod haskell-tools.hoogle haskell-tools Hoogle search

local log = require('haskell-tools.log.internal')
local lsp_util = vim.lsp.util

---@type fun(sig_or_func_name:string, options:table|nil):nil
local handler

---@param options table
---@return fun(err: lsp.ResponseError|nil, result: any, context: lsp.HandlerContext, config: table|nil)
local function mk_lsp_hoogle_signature_handler(options)
  return function(_, result, _, _)
    if not (result and result.contents) then
      vim.notify('hoogle: No information available')
      return
    end
    local func_name = vim.fn.expand('<cword>')
    ---@cast func_name string
    local HtParser = require('haskell-tools.parser')
    local signature_or_func_name = HtParser.try_get_signatures_from_markdown(func_name, result.contents.value)
      or func_name
    log.debug { 'Hoogle LSP signature search', signature_or_func_name }
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

local HTConfig = require('haskell-tools.config.internal')
local opts = HTConfig.tools.hoogle
local hoogle_web = require('haskell-tools.hoogle.web')
local hoogle_local = require('haskell-tools.hoogle.local')

---@return nil
local function set_web_handler()
  handler = hoogle_web.telescope_search
  log.debug('handler = telescope-web')
end

---@return nil
local function set_local_handler()
  handler = hoogle_local.telescope_search
  log.debug('handler = telescope-local')
end

---@return nil
local function set_browser_handler()
  handler = hoogle_web.browser_search
  log.debug('handler = browser')
end

if opts.mode == 'telescope-web' then
  set_web_handler()
elseif opts.mode == 'telescope-local' then
  if not hoogle_local.has_hoogle() then
    local msg = 'handler set to "telescope-local" but no hoogle executable found.'
    log.warn(msg)
    vim.notify('haskell-tools.hoogle: ' .. msg, vim.log.levels.WARN)
    set_web_handler()
    return
  end
  local deps = require('haskell-tools.deps')
  if not deps.has_telescope() then
    local msg = 'handler set to "telescope-local" but telescope.nvim is not installed.'
    log.warn(msg)
    vim.notify('haskell-tools.hoogle: ' .. msg, vim.log.levels.WARN)
    set_web_handler()
    return
  end
  set_local_handler()
elseif opts.mode == 'browser' then
  set_browser_handler()
elseif opts.mode == 'auto' then
  local deps = require('haskell-tools.deps')
  if not deps.has_telescope() then
    set_browser_handler()
  elseif hoogle_local.has_hoogle() then
    set_local_handler()
  else
    set_web_handler()
  end
end

---@class HoogleTools
local HoogleTools = {}

---@param options table<string,any>|nil Includes the `search_term` and options to pass to the telescope picker (if available)
---@return nil
HoogleTools.hoogle_signature = function(options)
  options = options or {}
  log.debug { 'Hoogle signature search options', options }
  if options.search_term then
    handler(options.search_term)
    return
  end
  local LspHelpers = require('haskell-tools.lsp.helpers')
  local clients = LspHelpers.get_clients { bufnr = vim.api.nvim_get_current_buf() }
  if #clients > 0 then
    lsp_hoogle_signature(options)
  else
    log.debug('Hoogle signature search: No clients attached. Falling back to <cword>.')
    local cword = vim.fn.expand('<cword>')
    ---@cast cword string
    handler(cword, options)
  end
end

return HoogleTools

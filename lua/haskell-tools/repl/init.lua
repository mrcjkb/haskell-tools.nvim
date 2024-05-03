---@mod haskell-tools.repl haskell-tools GHCi REPL module

---@bruief [[
---Tools for interaction with a GHCi REPL
---@bruief ]]

---@brief [[
--- The following commands are available:
---
--- * `:HtReplToggle` - Toggle a GHCi repl.
--- * `:HtReplQuit` - Quit the current repl.
--- * `:HtReplLoad` - Load a Haskell file into the repl.
--- * `:HtReplReload` - Reload the current repl.
---@brief ]]

local log = require('haskell-tools.log.internal')
local Types = require('haskell-tools.types.internal')
local compat = require('haskell-tools.compat')

---Extend a repl command for `file`.
---If `file` is `nil`, create a repl the nearest package.
---@param cmd string[] The command to extend
---@param file string|nil An optional project file
---@return string[]|nil
local function extend_repl_cmd(cmd, file)
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  if file == nil then
    file = vim.api.nvim_buf_get_name(0)
    log.debug('extend_repl_cmd: No file specified. Using current buffer: ' .. file)
    local project_root = HtProjectHelpers.match_project_root(file)
    local subpackage = project_root and HtProjectHelpers.get_package_name(file)
    if subpackage then
      table.insert(cmd, subpackage)
      log.debug { 'extend_repl_cmd: Extended cmd with package.', cmd }
      return cmd
    else
      log.debug { 'extend_repl_cmd: No subpackage or no package found.', cmd }
      return cmd
    end
  end
  log.debug('extend_repl_cmd: File: ' .. file)
  local project_root = HtProjectHelpers.match_project_root(file)
  local subpackage = project_root and HtProjectHelpers.get_package_name(file)
  if not subpackage then
    log.debug { 'extend_repl_cmd: No package found.', cmd }
    return cmd
  end
  if vim.endswith(file, '.hs') then
    table.insert(cmd, file)
  else
    log.debug('extend_repl_cmd: Not a Haskell file.')
    table.insert(cmd, subpackage)
  end
  log.debug { 'extend_repl_cmd', cmd }
  return cmd
end

---Create a cabal repl command for `file`.
---If `file` is `nil`, create a repl the nearest package.
---@param file string|nil
---@return string[]|nil command
local function mk_cabal_repl_cmd(file)
  return extend_repl_cmd({ 'cabal', 'repl', '--ghc-option', '-Wwarn' }, file)
end

---Create a stack repl command for `file`.
---If `file` is `nil`, create a repl the nearest package.
---@param file string|nil
---@return string[]|nil command
local function mk_stack_repl_cmd(file)
  return extend_repl_cmd({ 'stack', 'ghci' }, file)
end

---Create the command to create a repl for a file.
---If `file` is `nil`, create a repl for the nearest package.
---@param file string|nil
---@return table|nil command
local function mk_repl_cmd(file)
  local chk_path = file
  if not chk_path then
    chk_path = vim.api.nvim_buf_get_name(0)
    if vim.fn.filewritable(chk_path) == 0 then
      local err_msg = 'haskell-tools.repl: File not found. Has it been saved? ' .. chk_path
      log.error(err_msg)
      vim.notify(err_msg, vim.log.levels.ERROR)
      return nil
    end
  end
  local HTConfig = require('haskell-tools.config.internal')
  local opts = HTConfig.tools.repl
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  if Types.evaluate(opts.prefer) == 'stack' and HtProjectHelpers.is_stack_project(chk_path) then
    return mk_stack_repl_cmd(file)
  end
  if HtProjectHelpers.is_cabal_project(chk_path) then
    return mk_cabal_repl_cmd(file)
  end
  if HtProjectHelpers.is_stack_project(chk_path) then
    return mk_stack_repl_cmd(file)
  end
  if vim.fn.executable('ghci') == 1 then
    local cmd = compat.tbl_flatten { 'ghci', file and { file } or {} }
    log.debug { 'mk_repl_cmd', cmd }
    return cmd
  end
  local err_msg = 'haskell-tools.repl: No ghci executable found.'
  log.error(err_msg)
  vim.notify(err_msg, vim.log.levels.ERROR)
  return nil
end

local HTConfig = require('haskell-tools.config.internal')
local opts = HTConfig.tools.repl
---@type ReplHandlerImpl
local handler

local handler_type = Types.evaluate(opts.handler)
---@cast handler_type ReplHandler
if handler_type == 'toggleterm' then
  log.info('handler = toggleterm')
  handler = require('haskell-tools.repl.toggleterm')(mk_repl_cmd, opts)
else
  if handler_type ~= 'builtin' then
    log.warn('Invalid repl handler type. Falling back to builtin')
    vim.notify_once(
      'haskell-tools.repl: the handler "' .. handler_type .. '" is invalid. Defaulting to "builtin".',
      vim.log.levels.WARN
    )
  else
    log.info('handler = builtin')
  end
  handler = require('haskell-tools.repl.builtin')(mk_repl_cmd, opts)
end

local function handle_reg(cmd, reg)
  local data = vim.fn.getreg(reg or '"')
  handler.send_cmd(cmd .. ' ' .. data)
end

local function handle_cword(cmd)
  local cword = vim.fn.expand('<cword>')
  handler.send_cmd(cmd .. ' ' .. cword)
end

---@param lines string[]
local function repl_send_lines(lines)
  if #lines > 1 then
    handler.send_cmd(':{')
    for _, line in ipairs(lines) do
      handler.send_cmd(line)
    end
    handler.send_cmd(':}')
  else
    handler.send_cmd(lines[1])
  end
end

---@class HsReplTools
local HsReplTools = {}

HsReplTools.mk_repl_cmd = mk_repl_cmd

---Create the command to create a repl for the current buffer.
---@return table|nil command
HsReplTools.buf_mk_repl_cmd = function()
  local file = vim.api.nvim_buf_get_name(0)
  return mk_repl_cmd(file)
end

---Toggle a GHCi REPL
HsReplTools.toggle = handler.toggle

---Quit the REPL
HsReplTools.quit = handler.quit

---Can be used to send text objects to the repl.
---@usage [[
---vim.keymap.set('n', 'ghc', ht.repl.operator, {noremap = true})
---@usage ]]
---@see operatorfunc
HsReplTools.operator = function()
  local old_operator_func = vim.go.operatorfunc
  _G.op_func_send_to_repl = function()
    local start = vim.api.nvim_buf_get_mark(0, '[')
    local finish = vim.api.nvim_buf_get_mark(0, ']')
    local text = vim.api.nvim_buf_get_text(0, start[1] - 1, start[2], finish[1], finish[2] + 1, {})
    repl_send_lines(text)
    vim.go.operatorfunc = old_operator_func
    _G.op_func_formatting = nil
  end
  vim.go.operatorfunc = 'v:lua.op_func_send_to_repl'
  vim.api.nvim_feedkeys('g@', 'n', false)
end

---Paste from register `reg` to the REPL
---@param reg string|nil register (defaults to '"')
HsReplTools.paste = function(reg)
  local data = vim.fn.getreg(reg or '"')
  ---@cast data string
  if vim.endswith(data, '\n') then
    data = data:sub(1, #data - 1)
  end
  local lines = vim.split(data, '\n')
  if #lines <= 1 then
    lines = { data }
  end
  repl_send_lines(lines)
end

---Query the REPL for the type of register `reg`
---@param reg string|nil register (defaults to '"')
HsReplTools.paste_type = function(reg)
  handle_reg(':t', reg)
end

---Query the REPL for the type of word under the cursor
HsReplTools.cword_type = function()
  handle_cword(':t')
end

---Query the REPL for info on register `reg`
---@param reg string|nil register (defaults to '"')
HsReplTools.paste_info = function(reg)
  handle_reg(':i', reg)
end

---Query the REPL for the type of word under the cursor
HsReplTools.cword_info = function()
  handle_cword(':i')
end

---Load a file into the REPL
---@param filepath string The absolute file path
HsReplTools.load_file = function(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    local err_msg = 'File: ' .. filepath .. ' does not exist or is not readable.'
    log.error(err_msg)
    vim.notify(err_msg, vim.log.levels.ERROR)
  end
  handler.send_cmd(':l ' .. filepath)
end

---Reload the repl
HsReplTools.reload = function()
  handler.send_cmd(':r')
end

vim.keymap.set('n', 'ghc', HsReplTools.operator, { noremap = true })

local commands = {
  {
    'HtReplToggle',
    ---@param tbl table
    function(tbl)
      local filepath = tbl.args ~= '' and vim.fn.expand(tbl.args)
      ---@cast filepath string
      HsReplTools.toggle(filepath)
    end,
    { nargs = '?' },
  },
  {
    'HtReplLoad',
    ---@param tbl table
    function(tbl)
      local filepath = vim.fn.expand(tbl.args)
      ---@cast filepath string
      HsReplTools.load_file(filepath)
    end,
    { nargs = 1 },
  },
  {
    'HtReplQuit',
    function()
      HsReplTools.quit()
    end,
    {},
  },
  {
    'HtReplReload',
    function()
      HsReplTools.reload()
    end,
    {},
  },
}

for _, command in ipairs(commands) do
  vim.api.nvim_create_user_command(unpack(command))
end

return HsReplTools

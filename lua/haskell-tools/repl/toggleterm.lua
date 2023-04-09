---@mod haskell-tools.repl.toggleterm

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---Wraps the toggleterm.nvim API to provide a GHIi repl.

---@brief ]]

local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')
local ht_util = require('haskell-tools.util')

local toggleterm = {
  terminal = nil,
}

local last_cmd = ''

---@param cmd string?
local function is_new_cmd(cmd)
  return last_cmd ~= (cmd or '')
end

---@param mk_repl_cmd fun(string?):string[]? Function for building the repl that takes an optional file path
---@param opts ReplOpts
---@return nil
function toggleterm.setup(mk_repl_cmd, opts)
  opts = opts or vim.empty_dict()
  if opts.auto_focus == nil then
    toggleterm.go_back = true
  else
    toggleterm.go_back = not opts.auto_focus
  end
  ht.log.debug('repl.toggleterm setup')
  local Terminal = deps.require_toggleterm('toggleterm.terminal').Terminal

  ---@param cmd string The command to execute in the terminal
  ---@return unknown
  local function mk_new_terminal(cmd)
    local terminal_opts = {
      cmd = cmd,
      hidden = true,
      close_on_exit = false,
      on_stdout = function(_, job, data, name)
        ht.log.debug { 'Job ' .. job .. ' - stdout', data, name }
      end,
      on_stderr = function(_, job, data, name)
        ht.log.warn { 'Job ' .. job .. ' - stderr', data, name }
      end,
      on_exit = function(_, job, exit_code, name)
        ht.log.debug { 'Job ' .. job .. ' - exit code ' .. exit_code, name }
      end,
    }
    ht.log.debug { 'Creating new terminal', terminal_opts }
    return Terminal:new(terminal_opts)
  end

  --- @param filepath string? Path of the file to load into the repl
  function toggleterm.toggle(filepath, _)
    opts = opts or vim.empty_dict()
    if filepath and not vim.endswith(filepath, '.hs') then
      local err_msg = 'haskell-tools.repl.toggleterm: Not a Haskell file: ' .. filepath
      ht.log.error(err_msg)
      vim.notify(err_msg, vim.log.levels.ERROR)
      return
    end
    local cmd = mk_repl_cmd(filepath and ht_util.quote(filepath)) or {}
    if #cmd == 0 then
      local err_msg = 'haskell-tools.repl.toggleterm: Could not create a repl command.'
      ht.log.error(err_msg)
      vim.notify(err_msg, vim.log.levels.ERROR)
      return
    end
    local cmd_str = table.concat(cmd, ' ')
    if is_new_cmd(cmd_str) then
      ht.log.debug { 'repl.toggleterm: New command', cmd_str }
      toggleterm.quit()
    end
    local cur_win = vim.api.nvim_get_current_win()
    local is_normal_mode = vim.api.nvim_get_mode().mode == 'n'
    toggleterm.terminal = toggleterm.terminal or mk_new_terminal(cmd_str)
    local function toggle()
      toggleterm.terminal:toggle()
    end
    local success, result = pcall(toggle)
    if not success then
      ht.log.error { 'repl.toggleterm: toggle failed', result }
    end
    if cur_win ~= -1 and toggleterm.go_back then
      vim.api.nvim_set_current_win(cur_win)
      if is_normal_mode then
        vim.cmd('stopinsert')
      end
    end
    last_cmd = cmd_str
  end

  ---Quit the repl
  ---@retrun nil
  function toggleterm.quit()
    if toggleterm.terminal ~= nil then
      ht.log.debug('repl.toggleterm: sending quit to repl.')
      local success, result = pcall(toggleterm.send_cmd, ':q')
      if not success then
        ht.log.warn { 'repl.toggleterm: Could not send quit command', result }
      end
      toggleterm.terminal:close()
      toggleterm.terminal = nil
    end
  end

  ---Send a command to the repl, followed by <cr>
  ---@param txt string the command text to send
  ---@return nil
  function toggleterm.send_cmd(txt)
    opts = opts or vim.empty_dict()
    vim.tbl_extend('force', {
      go_back = false,
    }, opts)
    if toggleterm.terminal ~= nil then
      toggleterm.terminal:send(txt, toggleterm.go_back)
    end
  end
end

return toggleterm

local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')

local toggleterm = {
  terminal = nil,
}

local last_cmd = ''

-- @param string?
local function is_new_cmd(cmd)
  return last_cmd ~= (cmd or '')
end

-- @param function(string?): Function for building the repl (string?: file path)
function toggleterm.setup(mk_repl_cmd)
  ht.log.debug('repl.toggleterm setup')
  local Terminal = deps.require_toggleterm('toggleterm.terminal').Terminal

  local function mk_new_terminal(cmd)
    local opts = {
      cmd = cmd,
      hidden = true,
      close_on_exit = true,
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
    ht.log.debug { 'Creating new terminal', opts }
    return Terminal:new(opts)
  end

  -- @param string?: Optional path of the file to load into the repl
  function toggleterm.toggle(file)
    if file and not vim.endswith(file, '.hs') then
      local err_msg = 'haskell-tools.repl.toggleterm: Not a Haskell file: ' .. file
      ht.log.error(err_msg)
      vim.notify(err_msg, vim.log.levels.ERROR)
      return
    end
    local cmd = table.concat(mk_repl_cmd(file) or {}, ' ')
    if cmd == '' then
      local err_msg = 'haskell-tools.repl.toggleterm: Could not create a repl command.'
      ht.log.error(err_msg)
      vim.notify(err_msg, vim.log.levels.ERROR)
      return
    end
    if is_new_cmd(cmd) then
      ht.log.debug { 'repl.toggleterm: New command', cmd }
      toggleterm.quit()
    end
    toggleterm.terminal = toggleterm.terminal or mk_new_terminal(cmd)
    local function toggle()
      toggleterm.terminal:toggle()
    end
    local success, result = pcall(toggle)
    if not success then
      ht.log.error { 'repl.toggleterm: toggle failed', result }
    end
    last_cmd = cmd
  end

  -- Quit the repl
  function toggleterm.quit()
    if toggleterm.terminal ~= nil then
      ht.log.debug('repl.toggleterm: sending quit to repl.')
      local success, result = pcall(toggleterm.send_cmd, ':q')
      if not success then
        ht.log.warn { 'repl.toggleterm: Could not send quit command', result }
      end
      toggleterm.terminal = nil
    end
  end

  -- Send a command to the repl, followed by <cr>
  -- @param string
  -- @param table?
  function toggleterm.send_cmd(txt, opts)
    opts = opts or vim.empty_dict()
    vim.tbl_extend('force', {
      go_back = false,
    }, opts)
    if toggleterm.terminal ~= nil then
      toggleterm.terminal:send(txt, opts.go_back)
    end
  end
end

return toggleterm

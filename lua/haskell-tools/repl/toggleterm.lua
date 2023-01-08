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
    toggleterm.terminal = toggleterm.terminal or Terminal:new { cmd = cmd, hidden = true, close_on_exit = true }
    toggleterm.terminal:toggle()
    last_cmd = cmd
  end

  -- Quit the repl
  function toggleterm.quit()
    if toggleterm.terminal ~= nil then
      toggleterm.send_cmd(':q')
      toggleterm.terminal = nil
    end
  end

  -- Send a command to the repl, followed by <cr>
  -- @param string
  -- @param table?
  function toggleterm.send_cmd(txt, opts)
    vim.tbl_extend('force', {
      go_back = false,
    }, opts)
    if toggleterm.terminal ~= nil then
      toggleterm.terminal:send(txt, opts.go_back)
    end
  end
end

return toggleterm

local deps = require('haskell-tools.deps')

local M = {
  terminal = nil,
}

local last_cmd = ''

-- @param string?
local function is_new_cmd(cmd)
  return last_cmd ~= (cmd or '')
end

-- @param function(string?): Function for building the repl (string?: file path)
function M.setup(mk_repl_cmd)
  local Terminal = deps.require_toggleterm('toggleterm.terminal').Terminal

  -- @param string?: Optional path of the file to load into the repl
  function M.toggle(file)
    if file and not vim.endswith(file, '.hs') then
      return
    end
    local cmd = table.concat(mk_repl_cmd(file) or {}, ' ')
    if cmd == '' then
      vim.notify('haskell-tools.repl.toggleterm: Could not create a repl command.', vim.log.levels.DEBUG)
      return
    end
    if is_new_cmd(cmd) then
      M.quit()
    end
    M.terminal = M.terminal or Terminal:new({ cmd = cmd, hidden = true, close_on_exit = true, })
    M.terminal:toggle()
    last_cmd = cmd
  end

  -- Quit the repl
  function M.quit()
    if M.terminal ~= nil then
      M.send_cmd(':q')
      M.terminal = nil
    end
  end
  
  -- Send a command to the repl, followed by <cr>
  -- @param string
  -- @param table?
  function M.send_cmd(txt, opts)
    vim.tbl_extend('force', { 
      go_back = false,
    }, opts)
    if M.terminal ~= nil then
      M.terminal:send(txt, opts.go_back)
    end
  end
end
return M

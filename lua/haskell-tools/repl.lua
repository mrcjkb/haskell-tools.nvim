local ht = require('haskell-tools')
local project = require('haskell-tools.project-util')

-- Tools for interaction with a ghci repl
local M = {
}

-- Extend a repl command for `file`.
-- If `file` is `nil`, create a repl the nearest package.
-- @param cmd: table: the command to extend
-- @param file: string | nil
-- @param on_no_package: function(table) | nil: handler in case no package is found
-- @return table | nil
local function extend_repl_cmd(cmd, file, on_no_package)
  on_no_package = on_no_package or function(_) return nil end
  if file == nil then
    file = vim.api.nvim_buf_get_name(0)
    local pkg = project.get_package_name(file)
    if pkg then
      table.insert(cmd, pkg)
      return cmd
    else
      return on_no_package(cmd)
    end
  end
  local pkg = project.get_package_name(file)
  if not pkg then return on_no_package(cmd) end
  if vim.endswith(file, '.hs') then
    table.insert(cmd, file)
  else
    table.insert(cmd, pkg)
  end
  return cmd
end

-- Create a cabal repl command for `file`.
-- If `file` is `nil`, create a repl the nearest package.
-- @param string | nil: file
-- @return table | nil
local function mk_cabal_repl_cmd(file)
  return extend_repl_cmd({ 'cabal', 'new-repl', }, file)
end

-- Create a stack repl command for `file`.
-- If `file` is `nil`, create a repl the nearest package.
-- @param string | nil: file
-- @return table | nil
local function mk_stack_repl_cmd(file)
  return extend_repl_cmd({ 'stack', 'ghci', }, file, function(cmd) return cmd end)
end

-- Create the command to create a repl for a file.
-- If `file` is `nil`, create a repl the nearest package.
-- @param string | nil: file
-- @return table | nil
function M.mk_repl_cmd(file)
  local chk_path = file
  if not chk_path then
    chk_path = vim.api.nvim_buf_get_name(0)
    if vim.fn.filewritable(chk_path) == 0 then
      return nil
    end
  end
  if project.is_cabal_project(chk_path) then
    return mk_cabal_repl_cmd(file)
  end
  if project.is_stack_project(chk_path) then
    return mk_stack_repl_cmd(file)
  end
  if vim.fn.executable('ghci') == 1 then
    return vim.tbl_flatten { 'ghci', file and { file } or {}}
  end
  return nil
end

-- Create the command to create a repl for the current buffer.
-- @return table | nil
function M.buf_mk_repl_cmd()
  local file = vim.api.nvim_buf_get_name(0)
  return M.mk_repl_cmd(file)
end

function M.setup()
  local opts = ht.config.options.tools.repl
  local handler = {}
  if opts.handler == 'toggleterm' then
    local toggleterm = require('haskell-tools.repl.toggleterm')
    toggleterm.setup(M.mk_repl_cmd)
    handler = toggleterm
  else
    local builtin = require('haskell-tools.repl.builtin')
    builtin.setup(M.mk_repl_cmd, opts.builtin)
    handler = builtin
  end
  -- Toggle a GHCi repl
  -- @param string?: optional file path
  M.toggle = handler.toggle

  -- Quit the repl
  M.quit = handler.quit

  -- Paste from register `reg` to the repl
  -- @param string?: register (defaults to '"')
  function M.paste(reg)
    local data = vim.fn.getreg(reg or '"')
    if vim.endswith(data, '\n') then
      data = data:sub(1, #data - 1)
    end
    local lines = vim.split(data, '\n')
    if #lines > 1 then
      handler.send_cmd(':{')
      for _, line in ipairs(lines) do
        handler.send_cmd(line)
      end
      handler.send_cmd(':}')
    else
      handler.send_cmd(data)
    end
  end

  -- Query the repl for the type of register `reg`
  -- @param string?: register (defaults to '"')
  function M.paste_type(reg)
    local data = vim.fn.getreg(reg or '"')
    handler.send_cmd(':t ' .. data)
  end

  -- Load a file into the repl
  -- @param string: absolute file path
  function M.load_file(file)
    if vim.fn.filereadable(file) == 0 then
      vim.notify('File: ' .. file .. ' does not exist or is not readable.', vim.log.levels.ERROR)
    end
    handler.send_cmd(':l ' .. file)
  end

  -- Query the repl for the type of word under the cursor
  -- @param string?: register (defaults to '"')
  function M.cword_type()
    local cword = vim.fn.expand('<cword>')
    handler.send_cmd(':t ' .. cword)
  end

end

return M

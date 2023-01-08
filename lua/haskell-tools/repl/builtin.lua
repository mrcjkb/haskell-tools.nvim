local ht = require('haskell-tools')

-- Utility functions for the ghci repl module.
-- Not part of the public API.
local builtin = {}

local view = {}

-- the repl
local repl = nil

-- Check if a repl is loaded
local function repl_is_loaded()
  return repl ~= nil
    and repl.bufnr ~= nil
    and repl.job_id ~= nil
    and repl.cmd ~= nil
    and vim.api.nvim_buf_is_loaded(repl.bufnr)
end

-- @param table?
local function is_new_cmd(cmd)
  return repl ~= nil and repl.cmd ~= nil and table.concat(repl.cmd) ~= table.concat(cmd or {})
end

-- Creates a repl on buffer with id `bufnr`.
-- @param number: bufnr - buffer to be used.
-- @param function: cmd - command to start the repl
-- @param table?: opts {
--  delete_buffer_on_exit: bool
-- }
local function buf_create_repl(bufnr, cmd, opts)
  vim.api.nvim_win_set_buf(0, bufnr)
  opts = vim.tbl_extend('force', vim.empty_dict(), opts or {})
  if opts.delete_buffer_on_exit then
    opts.on_exit = function()
      local winid = vim.fn.bufwinid(bufnr)
      vim.api.nvim_win_close(winid, true)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end
  ht.log.debug { 'repl.builtin: Opening terminal', cmd, opts }
  local job_id = vim.fn.termopen(cmd, opts)
  repl = {
    bufnr = bufnr,
    job_id = job_id,
    cmd = cmd,
  }
  ht.log.debug { 'repl.builtin: Created repl.', repl }
end

-- Create a split
-- @param function? | number?
local function create_split(size)
  size = size and (type(size) == 'function' and size() or size) or vim.o.lines / 3
  local args = vim.empty_dict()
  table.insert(args, size)
  table.insert(args, 'split')
  vim.cmd(table.concat(args, ' '))
end

-- Create a vertical split
-- @param function? | number?
local function create_vsplit(size)
  size = size and (type(size) == 'function' and size() or size) or vim.o.columns / 2
  local args = vim.empty_dict()
  table.insert(args, size)
  table.insert(args, 'vsplit')
  vim.cmd(table.concat(args, ' '))
end

-- Create a new tab
local function create_tab(_)
  vim.cmd('tabnew')
end

-- Create a new repl (or toggle its visibility)
-- @param function(function|number): create_win: function for creating the window
-- @param function: mk_cmd: function for creating the repl command
-- @param table?: opts = {
--  delete_buffer_on_exit: bool?
--  size: function? | number?
-- }
local function create_or_toggle(create_win, mk_cmd, opts)
  local cmd = mk_cmd()
  if cmd == nil then
    local err_msg = 'haskell-tools.repl.builtin: Could not create a repl command.'
    ht.log.error(err_msg)
    vim.notify(err_msg, vim.log.levels.ERROR)
    return
  end
  if is_new_cmd(cmd) then
    ht.log.debug { 'repl.builtin: New command', cmd }
    builtin.quit()
  end
  if repl_is_loaded() then
    ht.log.debug('repl.builtin: is loaded')
    local winid = vim.fn.bufwinid(repl.bufnr)
    if winid ~= -1 then
      ht.log.debug('repl.builtin: Hiding window ' .. winid)
      vim.api.nvim_win_hide(winid)
    else
      create_win()
      vim.api.nvim_set_current_buf(repl.bufnr)
      winid = vim.fn.bufwinid(repl.bufnr)
      ht.log.debug('repl.builtin: Created window ' .. winid)
      vim.api.nvim_set_current_win(winid)
    end
    return
  end
  ht.log.debug('repl.builtin: is not loaded')
  opts = opts or vim.empty_dict()
  local bufnr = vim.api.nvim_create_buf(true, true)
  create_win()
  vim.api.nvim_set_current_buf(bufnr)
  local winid = vim.fn.bufwinid(bufnr)
  ht.log.debug('repl.builtin: Created window ' .. winid)
  vim.api.nvim_set_current_win(winid)
  buf_create_repl(bufnr, cmd, opts)
end

-- Create a new repl in a horizontal split
-- @param table?: opts = {
--  delete_buffer_on_exit: bool?
--  size: function? | number?
-- }
-- @return function(table)
function view.create_repl_split(opts)
  return function(mk_cmd)
    create_or_toggle(create_split, mk_cmd, opts)
  end
end

-- Create a new repl in a vertical split
-- @param table?: opts = {
--  delete_buffer_on_exit: bool?
--  size: function? | number?
-- }
-- @return function(table)
function view.create_repl_vsplit(opts)
  return function(mk_cmd)
    create_or_toggle(create_vsplit, mk_cmd, opts)
  end
end

-- Create a new repl in a new tab
-- @param table?: opts = {
--  delete_buffer_on_exit: bool?
-- }
-- @return function(table)
function view.create_repl_tabnew(opts)
  return function(mk_cmd)
    create_or_toggle(create_tab, mk_cmd, opts)
  end
end

-- Create a new repl in the current window
-- @param table?: opts = {
--  delete_buffer_on_exit: bool?
-- }
-- @return function(table)
function view.create_repl_cur_win(opts)
  return function(mk_cmd)
    create_or_toggle(function(_) end, mk_cmd, opts)
  end
end

-- @param function(string?)
-- @param table
function builtin.setup(mk_repl_cmd, opts)
  ht.log.debug { 'repl.builtin setup', opts }
  -- @param string?: Optional path of the file to load into the repl
  function builtin.toggle(file)
    local cur_win = vim.api.nvim_get_current_win()
    if file and not vim.endswith(file, '.hs') then
      local err_msg = 'haskell-tools.repl.builtin: Not a Haskell file: ' .. file
      ht.log.error(err_msg)
      vim.notify(err_msg, vim.log.levels.ERROR)
      return
    end
    local function mk_repl_cmd_wrapped()
      return mk_repl_cmd(file)
    end
    local create_or_toggle_callback = opts.create_repl_window(view)
    create_or_toggle_callback(mk_repl_cmd_wrapped)
    if cur_win ~= -1 then
      vim.api.nvim_set_current_win(cur_win)
    end
  end

  -- Quit the repl
  function builtin.quit()
    if not repl_is_loaded() then
      return
    end
    ht.log.debug('repl.builtin: sending quit to repl.')
    local success, result = pcall(builtin.send_cmd, ':q')
    if not success then
      ht.log.warn { 'repl.builtin: Could not send quit command', result }
    end
    local winid = vim.fn.bufwinid(repl.bufnr)
    if winid ~= -1 then
      vim.api.nvim_win_close(winid, true)
    end
    vim.api.nvim_buf_delete(repl.bufnr, { force = true })
  end

  -- Send a command to the repl, followed by <cr>
  -- @param string
  function builtin.send_cmd(txt)
    if not repl_is_loaded() then
      return
    end
    local cr = '\13'
    local function repl_set_cursor()
      local winid = vim.fn.bufwinid(repl.bufnr)
      if winid ~= -1 then
        vim.api.nvim_win_set_cursor(winid, { vim.api.nvim_buf_line_count(repl.bufnr), 0 })
      end
    end
    repl_set_cursor()
    vim.api.nvim_chan_send(repl.job_id, txt .. cr)
    repl_set_cursor()
  end
end

return builtin

---@mod haskell-tools.repl.builtin

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---Utility functions for the ghci repl module.
---@brief ]]

local ht = require('haskell-tools')

local builtin = {}

---@type ReplView
local view = {}

---@class BuiltinRepl
---@field bufnr number
---@field job_id number
---@field cmd string[]

---@type BuiltinRepl
local repl = nil

---@return boolean repl_is_loaded `true` if a repl is loaded
local function repl_is_loaded()
  return repl ~= nil and vim.api.nvim_buf_is_loaded(repl.bufnr)
end

--- @param cmd string[]?
local function is_new_cmd(cmd)
  return repl ~= nil and table.concat(repl.cmd) ~= table.concat(cmd or {})
end

---Creates a repl on buffer with id `bufnr`.
---@param bufnr number Buffer to be used.
---@param cmd string[] command to start the repl
---@param opts ReplViewOpts?
---@return nil
local function buf_create_repl(bufnr, cmd, opts)
  vim.api.nvim_win_set_buf(0, bufnr)
  opts = vim.tbl_extend('force', vim.empty_dict(), opts or {})
  local function delete_repl_buf()
    local winid = vim.fn.bufwinid(bufnr)
    vim.api.nvim_win_close(winid, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
  if opts.delete_buffer_on_exit then
    opts.on_exit = function(_, exit_code, _)
      ht.log.debug('repl.builtin: exit')
      if exit_code ~= 0 then
        local msg = 'repl.builtin: non-zero exit code: ' .. exit_code
        ht.log.warn(msg)
        vim.notify(msg, vim.log.levels.WARN)
      end
      delete_repl_buf()
    end
    local repl_log = function(logger)
      return function(_, data, name)
        logger { 'repl.builtin', data, name }
      end
    end
    opts.on_stdout = repl_log(ht.log.debug)
    opts.on_stderr = repl_log(ht.log.warn)
    opts.on_stdin = repl_log(ht.log.debug)
  end
  ht.log.debug { 'repl.builtin: Opening terminal', cmd, opts }
  local job_id = vim.fn.termopen(cmd, opts)
  if not job_id then
    ht.log.error('repl.builtin: Failed to open a terminal')
    vim.notify('haskell-tools: Could not start the repl.', vim.log.levels.ERROR)
    delete_repl_buf()
    return
  end
  repl = {
    bufnr = bufnr,
    job_id = job_id,
    cmd = cmd,
  }
  ht.log.debug { 'repl.builtin: Created repl.', repl }
end

---Create a split
---@param size function|number?
local function create_split(size)
  size = size and (type(size) == 'function' and size() or size) or vim.o.lines / 3
  local args = vim.empty_dict()
  table.insert(args, size)
  table.insert(args, 'split')
  vim.cmd(table.concat(args, ' '))
end

---Create a vertical split
---@param size function|number?
local function create_vsplit(size)
  size = size and (type(size) == 'function' and size() or size) or vim.o.columns / 2
  local args = vim.empty_dict()
  table.insert(args, size)
  table.insert(args, 'vsplit')
  vim.cmd(table.concat(args, ' '))
end

---Create a new tab
---@param _ any
local function create_tab(_)
  vim.cmd('tabnew')
end

---Create a new repl (or toggle its visibility)
---@param create_win function|number Function for creating the window or an existing window number
---@param mk_cmd fun():string[] Function for creating the repl command
---@param opts ReplViewOpts?
---@return nil
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

---Create a new repl in a horizontal split
---@param opts ReplViewOpts?
---@return fun(function) create_repl
function view.create_repl_split(opts)
  return function(mk_cmd)
    create_or_toggle(create_split, mk_cmd, opts)
  end
end

---Create a new repl in a vertical split
---@param opts ReplViewOpts?
---@return fun(function) create_repl
function view.create_repl_vsplit(opts)
  return function(mk_cmd)
    create_or_toggle(create_vsplit, mk_cmd, opts)
  end
end

---Create a new repl in a new tab
---@param opts ReplViewOpts?
---@return fun(function) create_repl
function view.create_repl_tabnew(opts)
  return function(mk_cmd)
    create_or_toggle(create_tab, mk_cmd, opts)
  end
end

---Create a new repl in the current window
---@param opts ReplViewOpts?
---@return fun(function) create_repl
function view.create_repl_cur_win(opts)
  return function(mk_cmd)
    create_or_toggle(function(_) end, mk_cmd, opts)
  end
end

---@param mk_repl_cmd fun(string):(string[]?)
---@param options ReplOpts
function builtin.setup(mk_repl_cmd, options)
  ht.log.debug { 'repl.builtin setup', options }
  builtin.go_back = options.auto_focus ~= true

  ---@param filepath string path of the file to load into the repl
  ---@param _ table?
  function builtin.toggle(filepath, _)
    local cur_win = vim.api.nvim_get_current_win()
    if filepath and not vim.endswith(filepath, '.hs') then
      local err_msg = 'haskell-tools.repl.builtin: Not a Haskell file: ' .. filepath
      ht.log.error(err_msg)
      vim.notify(err_msg, vim.log.levels.ERROR)
      return
    end

    ---@return string[]?
    local function mk_repl_cmd_wrapped()
      return mk_repl_cmd(filepath)
    end

    local create_or_toggle_callback = options.builtin.create_repl_window(view)
    create_or_toggle_callback(mk_repl_cmd_wrapped)
    if cur_win ~= -1 and builtin.go_back then
      vim.api.nvim_set_current_win(cur_win)
    else
      vim.cmd('startinsert')
    end
  end

  ---Quit the repl
  ---@return nil
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

  ---Send a command to the repl, followed by <cr>
  ---@param txt string The text to send
  ---@return nil
  function builtin.send_cmd(txt)
    if not repl_is_loaded() then
      return
    end
    local cr = '\13'
    local repl_winid = vim.fn.bufwinid(repl.bufnr)
    local function repl_set_cursor()
      if repl_winid ~= -1 then
        vim.api.nvim_win_set_cursor(repl_winid, { vim.api.nvim_buf_line_count(repl.bufnr), 0 })
      end
    end
    repl_set_cursor()
    vim.api.nvim_chan_send(repl.job_id, txt .. cr)
    repl_set_cursor()
    if not builtin.go_back then
      vim.api.nvim_set_current_win(repl_winid)
      vim.cmd('startinsert')
    end
  end
end

return builtin

local HtCommands = {}

local ht = require('haskell-tools')

---@class haskell-tools.Subcommand
---
---The command implementation
---@field impl fun(args: string[], opts: vim.api.keyset.user_command)
---
---Command completions callback, taking the lead of the subcommand's arguments
---Or a list of subcommands
---@field complete? string[] | fun(subcmd_arg_lead: string): string[]
---
---Whether this command supports a bang!
---@field bang? boolean

---@param arg_lead string
local function complete_haskell_files(arg_lead)
  return vim
    .iter(vim.list_extend(vim.fn.getcompletion(arg_lead, 'file'), vim.fn.getcompletion(arg_lead, 'buffer')))
    :filter(function(file_path)
      local ext = vim.fn.fnamemodify(file_path, ':e')
      return ext == 'hs' or ext == ''
    end)
    :totable()
end

---@param args? string[]
---@return string?
local function get_single_opt_arg(args)
  if type(args) ~= 'table' then
    return
  end
  if #args > 1 then
    require('haskell-tools.log.internal').warn { 'Too many arguments!', args }
  end
  return #args > 0 and args[1] or nil
end

---@param args? string[]
---@return string
local function get_filepath_arg(args)
  if not args or #args == 0 then
    return vim.api.nvim_buf_get_name(0)
  end
  assert(type(args[1]) == 'string', 'filepath is not a string')
  local filepath = vim.fn.expand(args[1])
  ---@cast filepath string
  return filepath
end

---@type table<string, haskell-tools.Subcommand>
local command_tbl = {
  packageYaml = {
    impl = function()
      ht.project.open_package_yaml()
    end,
  },
  packageCabal = {
    impl = function()
      ht.project.open_package_cabal()
    end,
  },
  projectFile = {
    impl = function()
      ht.project.open_project_file()
    end,
  },
  hover = {
    impl = function()
      local hover = require('haskell-tools.lsp.hover')
      hover.hover_actions()
    end,
  },
}

---@param name string The name of the subcommand
---@param subcmd_tbl table<string, haskell-tools.Subcommand> The subcommand's subcommand table
local function register_subcommand_tbl(name, subcmd_tbl)
  command_tbl[name] = {
    impl = function(args, ...)
      local subcmd = subcmd_tbl[table.remove(args, 1)]
      if subcmd then
        subcmd.impl(args, ...)
      else
        vim.notify(
          ([[
Haskell %s: Expected subcommand.
Available subcommands:
%s
]]):format(name, table.concat(vim.tbl_keys(subcmd_tbl), ', ')),
          vim.log.levels.ERROR
        )
      end
    end,
    complete = function(subcmd_arg_lead)
      local subcmd, next_arg_lead = subcmd_arg_lead:match('^(%S+)%s(.*)$')
      if subcmd and next_arg_lead and subcmd_tbl[subcmd] and subcmd_tbl[subcmd].complete then
        return subcmd_tbl[subcmd].complete(next_arg_lead)
      end
      if subcmd_arg_lead and subcmd_arg_lead ~= '' then
        return vim
          .iter(subcmd_tbl)
          ---@param subcmd_name string
          :filter(function(subcmd_name)
            return subcmd_name:find(subcmd_arg_lead) ~= nil
          end)
          :totable()
      end
      return vim.tbl_keys(subcmd_tbl)
    end,
  }
end

---@type table<string, haskell-tools.Subcommand>
local repl_subcommands = {
  toggle = {
    impl = function(args)
      local filepath = get_filepath_arg(args)
      ht.repl.toggle(filepath)
    end,
    complete = complete_haskell_files,
  },
  load = {
    impl = function(args)
      local filepath = get_filepath_arg(args)
      ht.repl.load_file(filepath)
    end,
    complete = complete_haskell_files,
  },
  quit = {
    impl = ht.repl.quit,
  },
  reload = {
    impl = ht.repl.reload,
  },
  paste_type = {
    impl = function(args)
      local reg = get_single_opt_arg(args)
      ht.repl.paste_type(reg)
    end,
  },
  cword_type = {
    impl = ht.repl.cword_type,
  },
  paste_info = {
    impl = function(args)
      local reg = get_single_opt_arg(args)
      ht.repl.paste_info(reg)
    end,
  },
  cword_info = {
    impl = ht.repl.cword_info,
  },
}

-- TODO: Smarter completions. load, quit and reload should only be suggested when a repl is active
register_subcommand_tbl('repl', repl_subcommands)

local log_command_tbl = {
  openHlsLog = {
    impl = function()
      ht.log.nvim_open_hls_logfile()
    end,
  },
  openLog = {
    impl = function()
      require('haskell-tools').log.nvim_open_logfile()
    end,
  },
  setLevel = {
    impl = function(args)
      local level = vim.fn.expand(args[1])
      ---@cast level string
      require('haskell-tools').log.set_level(tonumber(level) or level)
    end,
    complete = function(arg_lead)
      local levels = vim.tbl_keys(vim.log.levels)
      return vim.tbl_filter(function(command)
        return command:find(arg_lead) ~= nil
      end, levels)
    end,
  },
}

register_subcommand_tbl('log', log_command_tbl)

---@generic K, V
---@param predicate fun(V):boolean
---@param tbl table<K, V>
---@return K[]
local function tbl_keys_by_value_filter(predicate, tbl)
  local ret = {}
  for k, v in pairs(tbl) do
    if predicate(v) then
      ret[k] = v
    end
  end
  return vim.tbl_keys(ret)
end

local function haskell_cmd(opts)
  local fargs = opts.fargs
  local cmd = fargs[1]
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local command = command_tbl[cmd]
  if not command then
    vim.notify('Haskell: Unknown command: ' .. cmd, vim.log.levels.ERROR)
    return
  end
  command.impl(args, opts)
end

function HtCommands.init()
  vim.api.nvim_create_user_command('Haskell', haskell_cmd, {
    nargs = '+',
    desc = 'haskell-tools.nvim commands',
    complete = function(arg_lead, cmdline, _)
      local commands = cmdline:match("^['<,'>]*Haskell!") ~= nil
          -- bang!
          and tbl_keys_by_value_filter(function(command)
            return command.bang == true
          end, command_tbl)
        or vim.tbl_keys(command_tbl)
      local subcmd, subcmd_arg_lead = cmdline:match("^['<,'>]*Haskell[!]*%s(%S+)%s(.*)$")
      if subcmd and subcmd_arg_lead and command_tbl[subcmd] and command_tbl[subcmd].complete then
        return command_tbl[subcmd].complete(subcmd_arg_lead)
      end
      if cmdline:match("^['<,'>]*Haskell[!]*%s+%w*$") then
        return vim.tbl_filter(function(command)
          return command:find(arg_lead) ~= nil
        end, commands)
      end
    end,
    bang = false, -- might change
  })
end

return HtCommands

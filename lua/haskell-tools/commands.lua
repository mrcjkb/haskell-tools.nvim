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
}

---@param name string The name of the subcommand
---@param cmd haskell-tools.Subcommand The implementation and optional completions
function HtCommands.register_subcommand(name, cmd)
  command_tbl[name] = cmd
end

---@param name string The name of the subcommand
---@param subcmd_tbl table<string, haskell-tools.Subcommand> The subcommand's subcommand table
function HtCommands.register_subcommand_tbl(name, subcmd_tbl)
  command_tbl[name] = {
    impl = function(args, ...)
      local subcmd = subcmd_tbl[table.remove(args, 1)]
      subcmd.impl(args, ...)
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

return HtCommands

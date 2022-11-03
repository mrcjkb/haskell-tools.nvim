---@mod haskell-tools.dap haskell-tools nvim-dap setup

local ht = require('haskell-tools')
local ht_util = require('haskell-tools.util')
local deps = require('haskell-tools.deps')
local project_util = require('haskell-tools.project.util')
local Path = deps.require_plenary('plenary.path')
local async = deps.require_plenary('plenary.async')

local dap = {
  build_configurations = function(_) end,
}

---@param root_dir string
local function get_ghci_dap_cmd(root_dir)
  if project_util.is_cabal_project(root_dir) then
    return 'cabal exec -- ghci-dap --interactive -i ${workspaceFolder}'
  else
    return 'stack ghci --test --no-load --no-build --main-is TARGET --ghci-options -fprint-evld-with-show'
  end
end

---@param root_dir string
---@param opts AddDapConfigOpts
---@return table
local function find_json_configurations(root_dir, opts)
  local configurations = {}
  local results = vim.fn.glob(Path:new(root_dir, opts.settings_file_pattern).filename, true, true)
  if #results == 0 then
    ht.log.info(opts.settings_file_pattern .. ' not found in project root ' .. root_dir)
  else
    for _, launch_json in pairs(results) do
      local content = ht_util.read_file(launch_json)
      local success, settings = pcall(vim.json.decode, content)
      if not success then
        local msg = 'Could not decode ' .. launch_json .. '.'
        ht.log.warn { msg, error }
      elseif settings and settings.configurations and type(settings.configurations) == 'table' then
        configurations = vim.list_extend(configurations, settings.configurations)
      end
    end
  end
  return configurations
end

---@param root_dir string
---@return table
local function detect_launch_configurations(root_dir)
  local launch_configurations = {}
  local config_opts = ht.config.options
  local dap_opts = config_opts.dap
  ---@param entry_point HsEntryPoint
  local function mk_launch_configuration(entry_point)
    return {
      type = 'ghc',
      request = 'launch',
      name = entry_point.package_name .. ':' .. entry_point.exe_name,
      workspace = '${workspaceFolder}',
      startup = Path:new(entry_point.package_dir, entry_point.source_dir, entry_point.main).filename,
      startupFunc = '', -- defaults to 'main' if not set
      startupArgs = '',
      stopOnEntry = false,
      mainArgs = '',
      logFile = dap_opts.logFile,
      logLevel = dap_opts.logLevel,
      ghciEnv = vim.empty_dict(),
      ghciPrompt = 'λ: ',
      ghciInitialPrompt = 'ghci> ',
      ghciCmd = get_ghci_dap_cmd(root_dir),
      forceInspect = false,
    }
  end
  for _, entry_point in pairs(project_util.parse_project_entrypoints(root_dir)) do
    table.insert(launch_configurations, mk_launch_configuration(entry_point))
  end
  return launch_configurations
end

---@type table<string, table>
local _configuration_cache = {}

---@private
function dap.discover_configurations(_)
  vim.notify_once('haskell-tools.dap has not been set up. Is nvim-dap installed?', vim.log.levels.ERROR)
end

local function setup_dap(nvim_dap)
  dap.nvim_dap = nvim_dap
  local config_opts = ht.config.options
  local dap_opts = config_opts.dap
  nvim_dap.adapters.ghc = {
    type = 'executable',
    command = table.concat(dap_opts.cmd, ' '),
  }

  ---@class AddDapConfigOpts
  ---@field autodetect boolean Whether ta automatically detect launch configurations for the project
  ---@field settings_file_pattern string File name or pattern to search for. Defaults to 'launch.json'

  ---Discover nvim-dap launch configurations for haskell-debug-adapter.
  ---@param bufnr number|nil The buffer number
  ---@param opts AddDapConfigOpts|nil
  ---@return nil
  function dap.discover_configurations(bufnr, opts)
    async.run(function()
      bufnr = bufnr or 0 -- Default to current buffer
      local default_opts = {
        autodetect = true,
        settings_file_pattern = 'launch.json',
      }
      opts = vim.tbl_deep_extend('force', {}, default_opts, opts or {})
      local filename = vim.api.nvim_buf_get_name(bufnr)
      local project_root = project_util.match_project_root(filename)
      if not project_root then
        ht.log.warning('haskell-tools.dap: Unable to detect project root for file ' .. filename)
        return
      end
      if _configuration_cache[project_root] then
        return
      end
      local discovered_configurations = {}
      local json_configurations = find_json_configurations(project_root, opts)
      vim.list_extend(discovered_configurations, json_configurations)
      if opts.autodetect then
        local detected_configurations = detect_launch_configurations(project_root)
        vim.list_extend(discovered_configurations, detected_configurations)
      end
      _configuration_cache[project_root] = discovered_configurations
      local dap_configurations = nvim_dap.configurations.haskell or {}
      for _, config in ipairs(discovered_configurations) do
        for i, existing_config in pairs(dap_configurations) do
          if config.name == existing_config.name and config.startup == existing_config.startup then
            table.remove(dap_configurations, i)
          end
        end
        table.insert(dap_configurations, config)
      end
      nvim_dap.configurations.haskell = dap_configurations
    end)
  end
end

---Setup the DAP module. Called by the haskell-tools setup.
---@return nil
function dap.setup()
  deps.if_available('dap', setup_dap)
end

return dap

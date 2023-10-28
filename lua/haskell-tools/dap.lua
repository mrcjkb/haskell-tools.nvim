---@mod haskell-tools.dap haskell-tools nvim-dap setup

local deps = require('haskell-tools.deps')
local Types = require('haskell-tools.types.internal')
local compat = require('haskell-tools.compat')

---@param root_dir string
local function get_ghci_dap_cmd(root_dir)
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  if HtProjectHelpers.is_cabal_project(root_dir) then
    return 'cabal exec -- ghci-dap --interactive -i ${workspaceFolder}'
  else
    return 'stack ghci --test --no-load --no-build --main-is TARGET --ghci-options -fprint-evld-with-show'
  end
end

---@param root_dir string
---@param opts AddDapConfigOpts
---@return HsDapLaunchConfiguration[]
local function find_json_configurations(root_dir, opts)
  ---@type HsDapLaunchConfiguration[]
  local configurations = {}
  local log = require('haskell-tools.log.internal')
  local results = vim.fn.glob(compat.joinpath(root_dir, opts.settings_file_pattern), true, true)
  if #results == 0 then
    log.info(opts.settings_file_pattern .. ' not found in project root ' .. root_dir)
  else
    for _, launch_json in pairs(results) do
      local OS = require('haskell-tools.os')
      local content = OS.read_file(launch_json)
      local success, settings = pcall(vim.json.decode, content)
      if not success then
        local msg = 'Could not decode ' .. launch_json .. '.'
        log.warn { msg, error }
      elseif settings and settings.configurations and type(settings.configurations) == 'table' then
        configurations = vim.list_extend(configurations, settings.configurations)
      end
    end
  end
  return configurations
end

---@param root_dir string
---@return HsDapLaunchConfiguration[]
local function detect_launch_configurations(root_dir)
  local launch_configurations = {}
  local HTConfig = require('haskell-tools.config.internal')
  local dap_opts = HTConfig.dap
  ---@param entry_point HsEntryPoint
  ---@return HsDapLaunchConfiguration
  local function mk_launch_configuration(entry_point)
    ---@class HsDapLaunchConfiguration
    local HsDapLaunchConfiguration = {
      type = 'ghc',
      request = 'launch',
      name = entry_point.package_name .. ':' .. entry_point.exe_name,
      workspace = '${workspaceFolder}',
      startup = compat.joinpath(entry_point.package_dir, entry_point.source_dir, entry_point.main),
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
    return HsDapLaunchConfiguration
  end
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  for _, entry_point in pairs(HtProjectHelpers.parse_project_entrypoints(root_dir)) do
    table.insert(launch_configurations, mk_launch_configuration(entry_point))
  end
  return launch_configurations
end

---@type table<string, table>
local _configuration_cache = {}

if not deps.has('dap') then
  ---@type HsDapTools
  local NullHsDapTools = {
    discover_configurations = function(_) end,
  }
  return NullHsDapTools
end

local dap = require('dap')

---@class HsDapTools
local HsDapTools = {}

---@class AddDapConfigOpts
local DefaultAutoDapConfigOpts = {
  ---@type boolean Whether to automatically detect launch configurations for the project.
  autodetect = true,
  ---@type string File name or pattern to search for. Defaults to 'launch.json'.
  settings_file_pattern = 'launch.json',
}

---Discover nvim-dap launch configurations for haskell-debug-adapter.
---@param bufnr number|nil The buffer number
---@param opts AddDapConfigOpts|nil
---@return nil
HsDapTools.discover_configurations = function(bufnr, opts)
  local HTConfig = require('haskell-tools.config.internal')
  local HTDapConfig = HTConfig.dap
  local log = require('haskell-tools.log.internal')
  local dap_cmd = Types.evaluate(HTDapConfig.cmd) or {}
  if #dap_cmd == 0 or vim.fn.executable(dap_cmd[1]) ~= 1 then
    log.debug { 'DAP server executable not found.', dap_cmd }
    return
  end
  ---@cast dap_cmd string[]
  dap.adapters.ghc = {
    type = 'executable',
    command = table.concat(dap_cmd, ' '),
  }
  bufnr = bufnr or 0 -- Default to current buffer
  opts = vim.tbl_deep_extend('force', {}, DefaultAutoDapConfigOpts, opts or {})
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  local project_root = HtProjectHelpers.match_project_root(filename)
  if not project_root then
    log.warn('dap: Unable to detect project root for file ' .. filename)
    return
  end
  if _configuration_cache[project_root] then
    log.debug('dap: Found cached configuration. Skipping.')
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
  ---@type HsDapLaunchConfiguration[]
  local dap_configurations = dap.configurations.haskell or {}
  for _, cfg in ipairs(discovered_configurations) do
    for i, existing_config in pairs(dap_configurations) do
      if cfg.name == existing_config.name and cfg.startup == existing_config.startup then
        table.remove(dap_configurations, i)
      end
    end
    table.insert(dap_configurations, cfg)
  end
  dap.configurations.haskell = dap_configurations
end

return HsDapTools

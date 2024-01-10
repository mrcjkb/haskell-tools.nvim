---@mod haskell-tools.project haskell-tools Project module

local log = require('haskell-tools.log.internal')
local deps = require('haskell-tools.deps')

---@brief [[
--- The following commands are available:
---
--- * `:HsProjectFile` - Open the project file for the current buffer (cabal.project or stack.yaml).
--- * `:HsPackageYaml` - Open the package.yaml file for the current buffer.
--- * `:HsPackageCabal` - Open the *.cabal file for the current buffer.
---@brief ]]

---@param callback fun(opts:table<string,any>):nil
---@param opts table<string,any>
local function telescope_package_search(callback, opts)
  local file = vim.api.nvim_buf_get_name(0)
  if vim.fn.filewritable(file) == 0 then
    local err_msg = 'Telescope package search: File not found: ' .. file
    log.error(err_msg)
    vim.notify(err_msg, vim.log.levels.ERROR)
    return
  end
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  local package_root = HtProjectHelpers.match_package_root(file)
  if not package_root then
    local err_msg = 'Telescope package search: No package root found for file ' .. file
    log.error(err_msg)
    vim.notify(err_msg, vim.log.levels.ERROR)
    return
  end
  opts = vim.tbl_deep_extend('keep', {
    cwd = package_root,
    prompt_title = (opts.prompt_title_prefix or 'Package') .. ': ' .. vim.fn.fnamemodify(package_root, ':t'),
  }, opts or {})
  callback(opts)
end

log.debug('Setting up project tools...')

--- Live grep the current package with telescope.
--- available if nvim-telescope/telescope.nvim is installed.
---@param opts table|nil telescope options
local function telescope_package_grep(opts)
  local t = require('telescope.builtin')
  opts = vim.tbl_deep_extend('keep', { prompt_title_prefix = 'package live grep' }, opts or {})
  telescope_package_search(t.live_grep, opts)
end

--- Find file in the current package with telescope
--- available if nvim-telescope/telescope.nvim is installed.
---@param opts table|nil telescope options
local function telescope_package_files(opts)
  local t = require('telescope.builtin')
  opts = vim.tbl_deep_extend('keep', { prompt_title_prefix = 'package file search' }, opts or {})
  telescope_package_search(t.find_files, opts)
end

---@class HsProjectTools
local HsProjectTools = {}

---Get the project's root directory
---@param project_file string The path to a project file
---@return string|nil
HsProjectTools.root_dir = function(project_file)
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  return HtProjectHelpers.match_cabal_project_root(project_file)
    or HtProjectHelpers.match_stack_project_root(project_file)
    or HtProjectHelpers.match_package_root(project_file)
    or HtProjectHelpers.match_hie_yaml(project_file)
end

---Open the package.yaml of the package containing the current buffer.
---@return nil
HsProjectTools.open_package_yaml = function()
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  vim.schedule(function()
    local file = vim.api.nvim_buf_get_name(0)
    local result = HtProjectHelpers.get_package_yaml(file)
    if not result then
      local context = ''
      if HtProjectHelpers.is_cabal_project(file) then
        context = ' cabal project file'
      end
      local err_msg = 'HsPackageYaml: Cannot find package.yaml file for' .. context .. ': ' .. file
      log.error(err_msg)
      vim.notify(err_msg, vim.log.levels.ERROR)
      return
    end
    vim.cmd('e ' .. result)
  end)
end

---Open the *.cabal file of the package containing the current buffer.
---@return nil
HsProjectTools.open_package_cabal = function()
  vim.schedule(function()
    local HtProjectHelpers = require('haskell-tools.project.helpers')
    local file = vim.api.nvim_buf_get_name(0)
    if vim.fn.filewritable(file) ~= 0 and not HtProjectHelpers.is_cabal_project(file) then
      vim.notify('HsPackageCabal: Not a cabal project?', vim.log.levels.ERROR)
      return
    end
    local result = HtProjectHelpers.get_package_cabal(file)
    if not result then
      local err_msg = 'HsPackageCabal: Cannot find *.cabal file for: ' .. file
      log.error(err_msg)
      vim.notify(err_msg, vim.log.levels.ERROR)
      return
    end
    vim.cmd('e ' .. result)
  end)
end

---Open the current buffer's project file (cabal.project or stack.yaml).
---@return nil
HsProjectTools.open_project_file = function()
  vim.schedule(function()
    local HtProjectHelpers = require('haskell-tools.project.helpers')
    local file = vim.api.nvim_buf_get_name(0)
    local stack_project_root = HtProjectHelpers.match_stack_project_root(file)
    if stack_project_root then
      vim.cmd('e ' .. stack_project_root .. '/stack.yaml')
      return
    end
    local cabal_project_root = HtProjectHelpers.match_cabal_multi_project_root(file)
    if cabal_project_root then
      vim.cmd('e ' .. cabal_project_root .. '/cabal.project')
      return
    end
    local package_cabal = HtProjectHelpers.get_package_cabal(file)
    if package_cabal then
      vim.cmd('e ' .. package_cabal)
    end
    local err_msg = 'HsProjectFile: Cannot find project file from: ' .. file
    log.error(err_msg)
    vim.notify(err_msg, vim.log.levels.ERROR)
  end)
end

HsProjectTools.telescope_package_grep = deps.has('telescope.builtin') and telescope_package_grep or nil

HsProjectTools.telescope_package_files = deps.has('telescope.builtin') and telescope_package_files or nil

local commands = {
  {
    'HsPackageYaml',
    function()
      HsProjectTools.open_package_yaml()
    end,
    {},
  },
  {
    'HsPackageCabal',
    function()
      HsProjectTools.open_package_cabal()
    end,
    {},
  },
  {
    'HsProjectFile',
    function()
      HsProjectTools.open_project_file()
    end,
    {},
  },
}

--- Available if nvim-telescope/telescope.nvim is installed.
for _, command in ipairs(commands) do
  vim.api.nvim_create_user_command(unpack(command))
end

return HsProjectTools

---@mod haskell-tools.project haskell-tools Project module

local ht = require('haskell-tools')
local project_util = require('haskell-tools.project-util')
local deps = require('haskell-tools.deps')

---@brief [[
--- The following commands are available:
---
--- * `:HsProjectFile` - Open the project file for the current buffer (cabal.project or stack.yaml).
--- * `:HsPackageYaml` - Open the package.yaml file for the current buffer.
--- * `:HsPackageCabal` - Open the *.cabal file for the current buffer.
---@brief ]]

local project = {}

---@param callback fun(opts:table<string,any>):nil
---@param opts table<string,any>
local function telescope_package_search(callback, opts)
  local file = vim.api.nvim_buf_get_name(0)
  if vim.fn.filewritable(file) == 0 then
    local err_msg = 'Telescope package search: File not found: ' .. file
    ht.log.error(err_msg)
    vim.notify(err_msg, vim.log.levels.ERROR)
    return
  end
  local package_root = project_util.match_package_root(file)
  if not package_root then
    local err_msg = 'Telescope package search: No package root found for file ' .. file
    ht.log.error(err_msg)
    vim.notify(err_msg, vim.log.levels.ERROR)
    return
  end
  opts = vim.tbl_deep_extend('keep', {
    cwd = package_root,
    prompt_title = (opts.prompt_title_prefix or 'Package') .. ': ' .. vim.fn.fnamemodify(package_root, ':t'),
  }, opts or {})
  callback(opts)
end

local commands = {
  {
    'HsPackageYaml',
    function()
      project.open_package_yaml()
    end,
    {},
  },
  {
    'HsPackageCabal',
    function()
      project.open_package_cabal()
    end,
    {},
  },
  {
    'HsProjectFile',
    function()
      project.open_project_file()
    end,
    {},
  },
}

---Set up this module. Called by the haskell-tools setup.
---@return nil
function project.setup()
  ht.log.debug('project.setup')

  ---Open the package.yaml of the package containing the current buffer.
  ---@return nil
  function project.open_package_yaml()
    vim.schedule(function()
      local file = vim.api.nvim_buf_get_name(0)
      local result = project_util.get_package_yaml(file)
      if not result then
        local err_msg = 'HsPackageYaml: Cannot find package.yaml file for: ' .. file
        vim.log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return
      end
      vim.cmd('e ' .. result)
    end)
  end

  ---Open the *.cabal file of the package containing the current buffer.
  ---@return nil
  function project.open_package_cabal()
    vim.schedule(function()
      local file = vim.api.nvim_buf_get_name(0)
      if vim.fn.filewritable(file) ~= 0 and project_util.is_cabal_project(file) == nil then
        vim.notify('HsPackageCabal: Not a cabal project?', vim.log.levels.ERROR)
      end
      local result = project_util.get_package_cabal(file)
      if not result then
        local err_msg = 'HsPackageCabal: Cannot find *.cabal file for: ' .. file
        vim.log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return
      end
      vim.cmd('e ' .. result)
    end)
  end

  ---Open the current buffer's project file (cabal.project or stack.yaml).
  ---@return nil
  function project.open_project_file()
    vim.schedule(function()
      local file = vim.api.nvim_buf_get_name(0)
      local project_root = project_util.match_cabal_project_root(file)
      if project_root then
        vim.cmd('e ' .. project_root .. '/cabal.project')
        return
      end
      project_root = project_util.match_stack_project_root(file)
      if project_root then
        vim.cmd('e ' .. project_root .. '/stack.yaml')
        return
      end
      local err_msg = 'HsProjectFile: Cannot find project file from: ' .. file
      ht.log.error(err_msg)
      vim.notify(err_msg, vim.log.levels.ERROR)
    end)
  end

  deps.if_available('telescope.builtin', function(t)
    --- Live grep the current package with Telescope.
    --- Available if nvim-telescope/telescope.nvim is installed.
    ---@param opts table Telescope options
    function project.telescope_package_grep(opts)
      opts = vim.tbl_deep_extend('keep', { prompt_title_prefix = 'Package live grep' }, opts or {})
      telescope_package_search(t.live_grep, opts)
    end
    --- Find file in the current package with Telescope
    --- Available if nvim-telescope/telescope.nvim is installed.
    ---@param opts table Telescope options
    function project.telescope_package_files(opts)
      opts = vim.tbl_deep_extend('keep', { prompt_title_prefix = 'Package file search' }, opts or {})
      telescope_package_search(t.find_files, opts)
    end
  end)

  --- Available if nvim-telescope/telescope.nvim is installed.
  for _, command in ipairs(commands) do
    vim.api.nvim_create_user_command(unpack(command))
  end
end

return project

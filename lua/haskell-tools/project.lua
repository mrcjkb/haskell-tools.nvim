local project_util = require('haskell-tools.project-util')

local M = {}

local commands = {
  { 'HsPackageYaml', function()
      M.open_package_yaml()
  end, {} },
  { 'HsPackageCabal', function()
      M.open_package_cabal()
  end, {} },
  { 'HsProjectFile', function()
      M.open_project_file()
  end, {} },
}

function M.setup()

  function M.open_package_yaml()
    vim.schedule(function()
      local file = vim.api.nvim_buf_get_name(0)
      local result = project_util.get_package_yaml(file)
      if not result then
        vim.notify("HsPackageYaml: Cannot find package.yaml info for: " .. file, vim.log.levels.ERROR)
        return
      end
      vim.cmd('e ' .. result)
    end)
  end
  
  function M.open_package_cabal()
    vim.schedule(function()
      local file = vim.api.nvim_buf_get_name(0)
      if vim.fn.filewritable(file) ~= 0 and project_util.is_cabal_project(file) == nil then
        vim.notify("HsPackageCabal: Not a cabal project?", vim.log.levels.ERROR)
      end
      local result = project_util.get_package_cabal(file)
      vim.pretty_print("result: " ..result)
      if not result then
        vim.notify("HsPackageCabal: Cannot find package.yaml info for: " .. file, vim.log.levels.ERROR)
        return
      end
      vim.cmd('e ' .. result)
    end)
  end

  function M.open_project_file()
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
      vim.notify("HsProjectFile: Cannot find project file from: " .. file, vim.log.levels.ERROR)
    end)
  end

  for _, command in ipairs(commands) do
    vim.api.nvim_create_user_command(unpack(command))
  end
end

return M

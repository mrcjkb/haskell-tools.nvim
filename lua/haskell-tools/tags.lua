local ht = require('haskell-tools')
local deps = require('haskell-tools.deps')
local project_util = require('haskell-tools.project-util')

local M = {}

local _state = {
  fast_tags_generating = false,
  projects = {},
}

local function setup_fast_tags(config)
  local Job = deps.require_plenary('plenary.job')

  -- Generates tags for the current project
  -- @param path string?: file path
  -- @param opts table?
  -- @field refresh boolean: whether to regenerate the tags if they have already been generated
  -- for the project (default: true)
  function M.generate_project_tags(path, opts)
    path = path or vim.api.nvim_buf_get_name(0)
    vim.tbl_extend('force', { refresh = true, }, opts or {})
    local project_root = project_util.match_project_root(path) or vim.fn.getcwd()
    if opts.refresh == false and _state.projects[project_root] then
      -- project tags already generated
      return
    end
    _state.projects[project_root] = true
    _state.fast_tags_generating = true
    if project_root then
      Job:new({
        command = 'fast-tags',
        args = {'-R', project_root },
        on_exit = function(_)
          _state.fast_tags_generating = false
        end
      }):start()
    end
  end

  function M.generate_package_tags(path)
    path = path or vim.api.nvim_buf_get_name(0)
    _state.fast_tags_generating = true
    local package_root = vim.fn.getcwd() .. '/' .. project_util.match_package_root(path)
    local project_root = project_util.match_project_root(path) or vim.fn.getcwd()
    if package_root and project_root then
      Job:new({
        command = 'fast-tags',
        args = {'-R', package_root, project_root },
        on_exit = function(_)
          _state.fast_tags_generating = false
        end
      }):start()
    end
  end

  if vim.fn.executable('fast-tags') ~= 1 then
    vim.notify('haskell-tools: fast-tags fallback configured, but fast-tags executable not found', vim.log.levels.ERROR)
    return
  end
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('haskell-tools-generate-project-tags', {}),
    pattern = { 'haskell' },
    callback = function(meta)
      M.generate_project_tags(meta.file, { refresh = false, })
    end,
  });
  vim.api.nvim_create_autocmd(config.package_events, {
    group = vim.api.nvim_create_augroup('haskell-tools-generate-package-tags', {}),
    pattern = { 'haskell', '*.hs' },
    callback = function(meta)
      if _state.fast_tags_generating then
        return
      end
      M.generate_package_tags(meta.file)
    end
  });
end


function M.setup()
  local config = ht.config.options.tools.tags
  if config.enable == true then
    setup_fast_tags(config)
  end
end

return M

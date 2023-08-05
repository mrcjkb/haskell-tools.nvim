---@mod haskell-tools.tags haskell-tools fast-tags module

local ht_config = require('haskell-tools.config')
local ht_util = require('haskell-tools.util')
local log = require('haskell-tools.log')
local deps = require('haskell-tools.deps')
local project_util = require('haskell-tools.project.util')

local _state = {
  fast_tags_generating = false,
  projects = {},
}

log.debug('Setting up fast-tags tools')
local config = ht_config.options.tools.tags

local Job = deps.require_plenary('plenary.job')

---@class GenerateProjectTagsOpts
---@field refresh boolean Whether to refresh the tags if they have already been generated
--- for the project (default: true)

---@class FastTagsTools
local FastTagsTools = {}

---Generates tags for the current project
---@param path string|nil File path
---@param opts GenerateProjectTagsOpts|nil Options
FastTagsTools.generate_project_tags = function(path, opts)
  path = path or vim.api.nvim_buf_get_name(0)
  opts = vim.tbl_extend('force', { refresh = true }, opts or {})
  local project_root = project_util.match_project_root(path) or vim.fn.getcwd() or 'UNDEFINED'
  if opts.refresh == false and _state.projects[project_root] then
    log.debug('Project tags already generated. Skipping.')
    return
  end
  _state.projects[project_root] = true
  _state.fast_tags_generating = true
  if project_root then
    log.debug('Generating project tags for' .. project_root)
    vim.schedule(function()
      Job:new({
        command = 'fast-tags',
        args = { '-R', project_root },
        on_exit = function(_)
          _state.fast_tags_generating = false
        end,
      }):start()
    end)
  else
    log.warn('generate_project_tags: No project root found.')
  end
end

---Generate tags for the package containing `path`
---@param path string|nil File path
FastTagsTools.generate_package_tags = function(path)
  path = path or vim.api.nvim_buf_get_name(0)
  _state.fast_tags_generating = true
  local rel_package_root = project_util.match_package_root(path)
  if not rel_package_root then
    log.warn('generate_package_tags: No rel_package root found.')
    return
  end
  local package_root = vim.fn.getcwd() .. '/' .. rel_package_root
  local project_root = project_util.match_project_root(path) or vim.fn.getcwd()
  if not package_root then
    log.warn('generate_package_tags: No package root found.')
    return
  end
  if not project_root then
    log.warn('generate_package_tags: No project root found.')
    return
  end
  vim.schedule(function()
    Job:new({
      command = 'fast-tags',
      args = { '-R', package_root, project_root },
      on_exit = function(_)
        _state.fast_tags_generating = false
      end,
    }):start()
  end)
end

if not ht_util.eval_boolf(config.enable) then
  return
end

if vim.fn.executable('fast-tags') ~= 1 then
  local err_msg = 'haskell-tools: fast-tags fallback configured, but fast-tags executable not found'
  log.error(err_msg)
  vim.notify(err_msg, vim.log.levels.ERROR)
  return
end
local package_events = config.package_events
if #package_events > 0 then
  vim.api.nvim_create_autocmd(package_events, {
    group = vim.api.nvim_create_augroup('haskell-tools-generate-package-tags', {}),
    pattern = { 'haskell', '*.hs' },
    callback = function(meta)
      if _state.fast_tags_generating then
        return
      end
      FastTagsTools.generate_package_tags(meta.file)
    end,
  })
end

return FastTagsTools

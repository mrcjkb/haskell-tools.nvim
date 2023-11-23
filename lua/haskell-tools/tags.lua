---@mod haskell-tools.tags haskell-tools fast-tags module

local HTConfig = require('haskell-tools.config.internal')
local Types = require('haskell-tools.types.internal')
local log = require('haskell-tools.log.internal')
local compat = require('haskell-tools.compat')

local _state = {
  fast_tags_generating = false,
  projects = {},
}

log.debug('Setting up fast-tags tools')
local config = HTConfig.tools.tags

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
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  local project_root = HtProjectHelpers.match_project_root(path)
  if not project_root then
    log.warn('generate_project_tags: No project root found.')
    return
  end
  if opts.refresh == false and _state.projects[project_root] then
    log.debug('Project tags already generated. Skipping.')
    return
  end
  _state.projects[project_root] = true
  _state.fast_tags_generating = true
  if project_root then
    log.debug('Generating project tags for' .. project_root)
    compat.system({ 'fast-tags', '-R', project_root }, nil, function(sc)
      if sc.code ~= 0 then
        log.error { 'Error running fast-tags on project root', sc.code, sc.stderr }
      end
      ---@cast sc vim.SystemCompleted
      _state.fast_tags_generating = false
    end)
  end
end

---Generate tags for the package containing `path`
---@param path string|nil File path
FastTagsTools.generate_package_tags = function(path)
  path = path or vim.api.nvim_buf_get_name(0)
  _state.fast_tags_generating = true
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  local rel_package_root = HtProjectHelpers.match_package_root(path)
  if not rel_package_root then
    log.warn('generate_package_tags: No rel_package root found.')
    return
  end
  local package_root = vim.fn.getcwd() .. '/' .. rel_package_root
  local project_root = HtProjectHelpers.match_project_root(path) or vim.fn.getcwd()
  if not package_root then
    log.warn('generate_package_tags: No package root found.')
    return
  end
  if not project_root then
    log.warn('generate_package_tags: No project root found.')
    return
  end
  compat.system({ 'fast-tags', '-R', package_root, project_root }, nil, function(sc)
    ---@cast sc vim.SystemCompleted
    if sc.code ~= 0 then
      log.error { 'Error running fast-tags on package', sc.code, sc.stderr }
    end
    _state.fast_tags_generating = false
  end)
end

if not Types.evaluate(config.enable) then
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

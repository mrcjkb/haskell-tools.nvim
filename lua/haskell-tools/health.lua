---@mod haskell-tools.health Health checks

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local health = {}

local ht_util = require('haskell-tools.util')
local deps = require('haskell-tools.deps')
local HTConfig = require('haskell-tools.config.internal')
local h = vim.health or require('health')
local start = h.start or h.report_start
local ok = h.ok or h.report_ok
local error = h.error or h.report_error
local warn = h.warn or h.report_warn

---@class LuaDependency
---@field module string The name of a module
---@field optional fun():boolean Function that returns whether the dependency is optional
---@field url string URL (markdown)
---@field info string Additional information

---@type LuaDependency[]
local lua_dependencies = {
  {
    module = 'plenary',
    optional = function()
      return false
    end,
    url = '[nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)',
    info = '',
  },
  {
    module = 'telescope',
    optional = function()
      if not HTConfig then
        return true
      end
      local hoogle_mode = HTConfig.tools.hoogle.mode
      return hoogle_mode:match('telescope') == nil
    end,
    url = '[nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)',
    info = 'Required for hoogle search modes "telescope-local" and "telescope-web"',
  },
}

---@class ExternalDependency
---@field name string Name of the dependency
---@field get_binaries fun():string[]Function that returns the binaries to check for
---@field optional fun():boolean Function that returns whether the dependency is optional
---@field url string URL (markdown)
---@field info string Additional information
---@field extra_checks function|nil Optional extra checks to perform if the dependency is installed

---@type ExternalDependency[]
local external_dependencies = {
  {
    name = 'haskell-language-server',
    get_binaries = function()
      local default = { 'haskell-language-server-wrapper', 'haskell-language-server' }
      if not HTConfig then
        return default
      end
      local cmd = ht_util.evaluate(HTConfig.hls.cmd)
      if not cmd or #cmd == 0 then
        return default
      end
      return { cmd[1] }
    end,
    optional = function()
      return true
    end,
    url = '[haskell-language-server](https://haskell-language-server.readthedocs.io)',
    info = 'Required by the LSP client.',
  },
  {
    name = 'hoogle',
    get_binaries = function()
      return { 'hoogle' }
    end,
    optional = function()
      if not HTConfig then
        return true
      end
      local hoogle_mode = HTConfig.tools.hoogle.mode
      return hoogle_mode ~= 'telescope-local'
    end,
    url = '[ndmitchell/hoogle](https://github.com/ndmitchell/hoogle)',
    info = [[
      Recommended for better Hoogle search performance.
      Without a local installation, the web API will be used by default.
      Required if the hoogle mode is set to "telescope-local".
    ]],
    extra_checks = function()
      local handle, errmsg = io.popen('hoogle base')
      if handle then
        handle:close()
      end
      if errmsg then
        local hoogle_mode = HTConfig.tools.hoogle.mode
        if hoogle_mode and hoogle_mode == 'auto' or hoogle_mode == 'telescope-local' then
          error('hoogle: ' .. errmsg)
        else
          warn('hoogle: ' .. errmsg)
        end
      end
    end,
  },
  {
    name = 'fast-tags',
    get_binaries = function()
      return { 'fast-tags' }
    end,
    optional = function()
      return true
    end,
    url = '[fast-tags](https://hackage.haskell.org/package/fast-tags)',
    info = 'Optional, for generating tags as a `tagfunc` fallback.',
  },
  {
    name = 'curl',
    get_binaries = function()
      return { 'curl' }
    end,
    optional = function()
      local hoogle_mode = HTConfig.tools.hoogle.mode
      return not hoogle_mode or hoogle_mode ~= 'telescope-web'
    end,
    url = '[curl](https://curl.se/)',
    info = 'Required for "telescope-web" hoogle seach mode.',
  },
  {
    name = 'haskell-debug-adapter',
    get_binaries = function()
      return { 'haskell-debug-adapter' }
    end,
    optional = function()
      return true
    end,
    url = '[haskell-debug-adapter](https://github.com/phoityne/haskell-debug-adapter)',
    info = 'Optional, for `dap` support.',
  },
  {
    name = 'ghci-dap',
    get_binaries = function()
      return { 'ghci-dap' }
    end,
    optional = function()
      return true
    end,
    url = '[ghci-dap](https://github.com/phoityne/ghci-dap)',
    info = 'Optional, for `dap` support.',
  },
}

---@param dep LuaDependency
local function check_lua_dependency(dep)
  if deps.has(dep.module) then
    ok(dep.url .. ' installed.')
    return
  end
  if dep.optional() then
    warn(('%s not installed. %s %s'):format(dep.module, dep.info, dep.url))
  else
    error(('Lua dependency %s not found: %s'):format(dep.module, dep.url))
  end
end

---@param dep ExternalDependency
---@return boolean is_installed
---@return string|nil version
local check_installed = function(dep)
  local binaries = dep.get_binaries()
  for _, binary in ipairs(binaries) do
    if vim.fn.executable(binary) == 1 then
      local handle = io.popen(binary .. ' --version')
      if handle then
        local binary_version, error_msg = handle:read('*a')
        handle:close()
        if error_msg then
          return true
        end
        return true, binary_version
      end
      return true
    end
  end
  return false
end

---@param dep ExternalDependency
local function check_external_dependency(dep)
  local installed, mb_version = check_installed(dep)
  if installed then
    local mb_version_newline_idx = mb_version and mb_version:find('\n')
    local mb_version_len = mb_version and (mb_version_newline_idx and mb_version_newline_idx - 1 or mb_version:len())
    local version = mb_version and mb_version:sub(0, mb_version_len) or '(unknown version)'
    ok(('%s: found %s'):format(dep.name, version))
    if dep.extra_checks then
      dep.extra_checks()
    end
    return
  end
  if dep.optional() then
    warn(([[
      %s: not found.
      Install %s for extended capabilities.
      %s
      ]]):format(dep.name, dep.url, dep.info))
  else
    error(([[
      %s: not found.
      haskell-tools.nvim requires %s.
      %s
      ]]):format(dep.name, dep.url, dep.info))
  end
end

local function check_config()
  start('Checking config')
  local valid, err = require('haskell-tools.config.check').validate(HTConfig)
  if valid then
    ok('No errors found in config.')
  else
    error(err)
  end
end

function health.check()
  start('Checking for Lua dependencies')
  for _, dep in ipairs(lua_dependencies) do
    check_lua_dependency(dep)
  end

  start('Checking external dependencies')
  for _, dep in ipairs(external_dependencies) do
    check_external_dependency(dep)
  end
  check_config()
end

return health

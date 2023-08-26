---@toc haskell-tools.contents

---@mod intro Introduction
---@brief [[
---This plugin automatically configures the `haskell-language-server` builtin LSP client
---and integrates with other haskell tools.
---
---Warning:
---Do not call the `lspconfig.hls` setup or set up the lsp manually,
---as doing so may cause conflicts.
---
---@brief ]]

---@mod haskell-tools The haskell-tools module

---@brief [[
---Entry-point into this plugin's public API.
---@brief ]]

local _state = {
  _has_been_setup = false,
}

local ht = {
  config = nil,
  log = nil,
  lsp = nil,
  hoogle = nil,
  repl = nil,
  project = nil,
  tags = nil,
  dap = nil,
}

local announce_2xx
announce_2xx = function(show_more_info)
  local skipfile = vim.fn.stdpath('state') .. '/.no-haskell-tools-2.x.x-notify'
  local skipmsg = "Don't show me this message again"
  local announcement_url = 'https://github.com/mrcjkb/haskell-tools.nvim/discussions/227'
  local more_info_msg = 'More info: ' .. announcement_url
  if vim.fn.filereadable(skipfile) == 0 then
    local choices = { 'OK', skipmsg }
    if show_more_info then
      table.insert(choices, more_info_msg)
    end
    vim.ui.select(choices, {
      prompt = 'The haskell-tools.nvim 2.x.x stable branch is ready for use.',
    }, function(choice)
      if choice == skipmsg then
        vim.system { 'touch', skipfile }
      end
      if choice == more_info_msg then
        local util = require('haskell-tools.util')
        util.open_browser(announcement_url)
        announce_2xx()
      end
    end)
  end
end

---Starts or attaches an LSP client to the current buffer and sets up the plugin if necessary.
---Call this function in ~/.config/nvim/ftplugin/haskell.lua
---
---@param opts HTOpts|nil The plugin configuration.
---@see haskell-tools.config for configuration options.
---@see lspconfig-keybindings for suggested keybindings by `nvim-lspconfig`.
---@see ftplugin
---@see base-directories
---@usage [[
---local ht = require('haskell-tools')
---local def_opts = { noremap = true, silent = true, }
---ht.start_or_attach {
---   tools = {
---   -- ...
---   },
---   hls = {
---     on_attach = function(client, bufnr)
---       -- Set keybindings, etc. here.
---     end,
---     -- ...
---   },
--- }
---@usage ]]
function ht.start_or_attach(opts)
  opts = vim.tbl_deep_extend('force', opts or {}, {
    hls = {
      filetypes = nil,
    },
    tools = {
      tags = {
        filetypes = nil,
      },
    },
  })
  if not _state._has_been_setup then
    ht.setup(opts)
  end
  local hls_bin = ht.config.options.hls.cmd[1]
  if vim.fn.executable(hls_bin) ~= 0 then
    ht.lsp.start()
  end
  if ht.config.options.tools.tags.enable then
    ht.tags.generate_project_tags(nil, { refresh = false })
  end
end

---Sets up the plugin.
---Must be called before using this plugin's API, unless using `start_or_attach()`.
---
---@param opts HTOpts|nil The plugin configuration.
---@see haskell-tools.config for configuration options.
---@see lspconfig-keybindings for suggested keybindings by `nvim-lspconfig`.
---@see haskell-tools.start_or_attach
---@usage [[
---local ht = require('haskell-tools')
---local def_opts = { noremap = true, silent = true, }
---ht.setup {
---   tools = {
---   -- ...
---   },
---   hls = {
---     on_attach = function(client, bufnr)
---       -- Set keybindings, etc. here.
---     end,
---     -- ...
---   },
--- }
---@usage ]]
function ht.setup(opts)
  announce_2xx(true)
  local config = require('haskell-tools.config')
  ht.config = config
  local log = require('haskell-tools.log')
  ht.log = log
  local lsp = require('haskell-tools.lsp')
  ht.lsp = lsp
  local hoogle = require('haskell-tools.hoogle')
  ht.hoogle = hoogle
  local repl = require('haskell-tools.repl')
  ht.repl = repl
  local project = require('haskell-tools.project')
  ht.project = project
  local tags = require('haskell-tools.tags')
  ht.tags = tags
  local dap = require('haskell-tools.dap')
  ht.dap = dap

  config.setup(opts)
  log.setup()
  log.debug { 'Config', config.options }
  lsp.setup()
  hoogle.setup()
  repl.setup()
  project.setup()
  tags.setup()
  dap.setup()

  _state._has_been_setup = true
end

return ht

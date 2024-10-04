---@mod haskell-tools.config.internal

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- The internal configuration.
--- Merges the default config with `vim.g.haskell_tools`.
---@brief ]]

local deps = require('haskell-tools.deps')

---@type haskell-tools.Config
local HTConfig = {}

local ht_capabilities = vim.lsp.protocol.make_client_capabilities()
local cmp_capabilities = deps.if_available('cmp_nvim_lsp', function(cmp_nvim_lsp)
  return cmp_nvim_lsp.default_capabilities()
end, {})
local selection_range_capabilities = deps.if_available('lsp-selection-range', function(lsp_selection_range)
  return lsp_selection_range.update_capabilities {}
end, {})
local folding_range_capabilities = deps.if_available('ufo', function(_)
  return {
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  }
end, {})
local capabilities = vim.tbl_deep_extend(
  'force',
  ht_capabilities,
  cmp_capabilities,
  selection_range_capabilities,
  folding_range_capabilities
)

---@class haskell-tools.Config haskell-tools.nvim plugin configuration.
local HTDefaultConfig = {

  ---@class haskell-tools.tools.Config haskell-tools module config.
  tools = {
    ---@class haskell-tools.codeLens.Config LSP codeLens options.
    codeLens = {
      ---@type boolean | (fun():boolean) (default: `true`) Whether to auto-refresh code-lenses.
      autoRefresh = true,
    },
    ---@class haskell-tools.hoogle.Config hoogle type signature search config.
    hoogle = {
      ---@type haskell-tools.hoogle.Mode Use a telescope with a local hoogle installation or a web backend, or use the browser for hoogle signature search?
      mode = 'auto',
    },
    ---@class haskell-tools.hover.Config Enhanced LSP hover options.
    hover = {
      ---@type boolean | (fun():boolean) (default: `true`) Whether to enable haskell-tools hover.
      enable = function()
        local has_jit = pcall(require, 'jit')
        return has_jit
      end,
      ---@type string[][] | nil The hover window's border. Set to `nil` to disable.
      border = {
        { '╭', 'FloatBorder' },
        { '─', 'FloatBorder' },
        { '╮', 'FloatBorder' },
        { '│', 'FloatBorder' },
        { '╯', 'FloatBorder' },
        { '─', 'FloatBorder' },
        { '╰', 'FloatBorder' },
        { '│', 'FloatBorder' },
      },
      ---@type boolean (default: `false`) The builtin LSP client's default behaviour is to stylize markdown. Setting this option to false sets the file type to markdown and enables treesitter syntax highligting for Haskell snippets if nvim-treesitter is installed.
      stylize_markdown = false,
      ---@type boolean (default: `false`) Whether to automatically switch to the hover window.
      auto_focus = false,
    },
    ---@class haskell-tools.definition.Config Enhanced LSP go-to-definition options.
    definition = {
      ---@type boolean | (fun():boolean) (default: `false`) Configure `vim.lsp.definition` to fall back to hoogle search (does not affect `vim.lsp.tagfunc`).
      hoogle_signature_fallback = false,
    },
    ---@class haskell-tools.repl.Config GHCi repl options.
    repl = {
      ---@type haskell-tools.repl.Handler | (fun():haskell-tools.repl.Handler) `'builtin'`: Use the simple builtin repl. `'toggleterm'`: Use akinsho/toggleterm.nvim.
      handler = 'builtin',
      ---@type haskell-tools.repl.Backend | (fun():haskell-tools.repl.Backend) Prefer cabal or stack when both stack and cabal project files are present?
      prefer = function()
        return vim.fn.executable('stack') == 1 and 'stack' or 'cabal'
      end,
      ---@class haskell-tools.repl.builtin.Config Configuration for the builtin repl
      builtin = {
        ---@type fun(view:haskell-tools.repl.View):fun(mk_repl_cmd:mk_ht_repl_cmd_fun) How to create the repl window. Should return a function that calls one of the `ReplView`'s functions.
        create_repl_window = function(view)
          return view.create_repl_split { size = vim.o.lines / 3 }
        end,
      },
      ---@type boolean | nil Whether to auto-focus the repl on toggle or send. If unset, the handler decides.
      auto_focus = nil,
    },
    ---@class haskell-tools.fast-tags.Config fast-tags module options.
    tags = {
      ---@type boolean | (fun():boolean) Enabled by default if the `fast-tags` executable is found.
      enable = function()
        return vim.fn.executable('fast-tags') == 1
      end,
      ---@type string[] `autocmd` Events to trigger package tag generation.
      package_events = { 'BufWritePost' },
    },
    ---@class haskell-tools.log.Config haskell-tools logger options.
    log = {
      ---@diagnostic disable-next-line: param-type-mismatch
      logfile = vim.fs.joinpath(vim.fn.stdpath('log'), 'haskell-tools.log'),
      ---@type number | string The log level.
      ---@see vim.log.levels
      level = vim.log.levels.WARN,
    },
    ---@type fun(url: string) custom action for opening url
    open_url = function(url)
      require('haskell-tools.os').open_browser(url)
    end,
  },
  ---@class haskell-tools.lsp.ClientConfig haskell-language-server client options.
  hls = {
    ---@type boolean | (fun():boolean) Whether to automatically attach the LSP client. Defaults to `true` if the haskell-language-server executable is found.
    auto_attach = function()
      local Types = require('haskell-tools.types.internal')
      local cmd = Types.evaluate(HTConfig.hls.cmd)
      ---@cast cmd string[]
      local hls_bin = cmd[1]
      return vim.fn.executable(hls_bin) == 1
    end,
    ---@type boolean Whether to enable haskell-language-server debug logging.
    debug = false,
    ---@type (fun(client:number,bufnr:number,ht:HaskellTools)) Callback that is invoked when the client attaches to a buffer.
    ---@see vim.lsp.start
    on_attach = function(_, _, _) end,
    ---@type string[] | (fun():string[]) The command to start haskell-language-server with.
    ---@see vim.lsp.start
    cmd = function()
      -- Some distributions don't prorvide a hls wrapper.
      -- So we check if it exists and fall back to hls if it doesn't
      local hls_bin = 'haskell-language-server'
      local hls_wrapper_bin = hls_bin .. '-wrapper'
      local bin = vim.fn.executable(hls_wrapper_bin) == 1 and hls_wrapper_bin or hls_bin
      local cmd = { bin, '--lsp', '--logfile', HTConfig.hls.logfile }
      if HTConfig.hls.debug then
        table.insert(cmd, '--debug')
      end
      return cmd
    end,
    ---@type lsp.ClientCapabilities | nil LSP client capabilities.
    ---@see vim.lsp.protocol.make_client_capabilities
    ---@see vim.lsp.start
    capabilities = capabilities,
    ---@type table | (fun(project_root:string|nil):table) | nil The haskell-language-server settings or a function that creates them. To view the default settings, run `haskell-language-server generate-default-config`.
    settings = function(project_root)
      local ht = require('haskell-tools')
      return ht.lsp.load_hls_settings(project_root)
    end,
    ---@type table The default haskell-language-server settings that will be used if no settings are specified or detected.
    default_settings = {
      haskell = {
        -- The formatting providers.
        formattingProvider = 'fourmolu',
        -- Maximum number of completions sent to the LSP client.
        maxCompletions = 40,
        -- Whether to typecheck the entire project on initial load.
        -- Could drive to bad performance in large projects, if set to true.
        checkProject = true,
        -- When to typecheck reverse dependencies of a file;
        -- one of NeverCheck, CheckOnSave (means dependent/parent modules will only be checked when you save),
        -- or AlwaysCheck (means re-typechecking them on every change).
        checkParents = 'CheckOnSave',
        plugin = {
          alternateNumberFormat = { globalOn = true },
          callHierarchy = { globalOn = true },
          changeTypeSignature = { globalOn = true },
          class = {
            codeActionsOn = true,
            codeLensOn = true,
          },
          eval = {
            globalOn = true,
            config = {
              diff = true,
              exception = true,
            },
          },
          excplicitFixity = { globalOn = true },
          gadt = { globalOn = true },
          ['ghcide-code-actions-bindings'] = { globalOn = true },
          ['ghcide-code-actions-fill-holes'] = { globalOn = true },
          ['ghcide-code-actions-imports-exports'] = { globalOn = true },
          ['ghcide-code-actions-type-signatures'] = { globalOn = true },
          ['ghcide-completions'] = {
            globalOn = true,
            config = {
              autoExtendOn = true,
              snippetsOn = true,
            },
          },
          ['ghcide-hover-and-symbols'] = {
            hoverOn = true,
            symbolsOn = true,
          },
          ['ghcide-type-lenses'] = {
            globalOn = true,
            config = {
              mode = 'always',
            },
          },
          haddockComments = { globalOn = true },
          hlint = {
            codeActionsOn = true,
            diagnosticsOn = true,
          },
          importLens = {
            globalOn = true,
            codeActionsOn = true,
            codeLensOn = true,
          },
          moduleName = { globalOn = true },
          pragmas = {
            codeActionsOn = true,
            completionOn = true,
          },
          qualifyImportedNames = { globalOn = true },
          refineImports = {
            codeActionsOn = true,
            codeLensOn = true,
          },
          rename = {
            globalOn = true,
            config = { crossModule = true },
          },
          retrie = { globalOn = true },
          splice = { globalOn = true },
          tactics = {
            codeActionsOn = true,
            codeLensOn = true,
            config = {
              auto_gas = 4,
              hole_severity = nil,
              max_use_ctor_actions = 5,
              proofstate_styling = true,
              timeout_duration = 2,
            },
            hoverOn = true,
          },
        },
      },
    },
    ---@type string The path to the haskell-language-server log file.
    logfile = vim.fn.tempname() .. '-haskell-language-server.log',
  },
  ---@class haskell-tools.dap.Config debug adapter config for nvim-dap.
  dap = {
    ---@type string[] | (fun():string[]) The command to start the debug adapter server with.
    cmd = { 'haskell-debug-adapter' },
    ---@type string Log file path for detected configurations.
    logFile = vim.fn.stdpath('data') .. '/haskell-dap.log',
    ---@type haskell-tools.debugAdapter.LogLevel The log level for detected configurations.
    logLevel = 'Warning',
    ---@type boolean | haskell-tools.dap.AddConfigOpts Set to `false` to disable auto-discovery of launch configurations. `true` uses the default configurations options`.
    auto_discover = true,
  },
  debug_info = {
    ---@type boolean
    was_g_haskell_tools_sourced = vim.g.haskell_tools ~= nil,
  },
}

local haskell_tools = vim.g.haskell_tools or {}
---@type haskell-tools.Opts
local opts = type(haskell_tools) == 'function' and haskell_tools() or haskell_tools

---@type haskell-tools.Config
HTConfig = vim.tbl_deep_extend('force', {}, HTDefaultConfig, opts)
local check = require('haskell-tools.config.check')
local ok, err = check.validate(HTConfig)
if not ok then
  vim.notify('haskell-tools: ' .. err, vim.log.levels.ERROR)
end

local dont_warn = {
  'tools.repl.auto_focus',
  'hls.capabilities',
  'hls.settings',
  'hls.default_settings',
}
local unrecognized_keys = check.get_unrecognized_keys(opts, HTDefaultConfig, dont_warn)
if #unrecognized_keys > 0 then
  vim.notify('unrecognized configs in vim.g.haskell_tools: ' .. vim.inspect(unrecognized_keys), vim.log.levels.WARN)
end

HTConfig.debug_info.unrecognized_keys = unrecognized_keys

return HTConfig

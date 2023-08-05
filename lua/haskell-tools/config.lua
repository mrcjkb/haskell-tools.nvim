---@mod haskell-tools.config plugin configuration
---
---@brief [[
---To configure haskell-tools.nvim, set the variable `vim.g.haskell_tools`,
---which is a `HTOpts` table, in your neovim configuration.
---
---Example:
--->
---vim.g.haskell_tools = {
---   tools = {
---     -- ...
---   },
---   hls = {
---     on_attach = function(client, bufnr)
---       -- Set keybindings, etc. here.
---     end,
---     -- ...
---   },
--- }
---<
---
---@brief ]]

---@class HTOpts
---@field tools ToolsOpts|nil haskell-tools plugin options
---@field hls HaskellLspClientOpts|nil haskell-language-server client options
---@field dap HTDapOpts|nil haskell-debug-adapter client options

---@class ToolsOpts
---@field codeLens CodeLensOpts|nil LSP client codeLens options
---@field hoogle HoogleOpts|nil Hoogle options
---@field hover HoverOpts|nil LSP client hover options
---@field definition DefinitionOpts|nil LSP client definition options
---@field repl ReplOpts|nil GHCi REPL options
---@field tags FastTagsOpts|nil Options for generating tags using fast-tags
---@field log HTLogOpts|nil Logging options

---@class CodeLensOpts
---@field autoRefresh (fun():boolean)|boolean (default: `true`) Whether to auto-refresh code-lenses

---@class HoogleOpts
---@field mode HoogleMode

---@alias HoogleMode 'auto' | 'telescope-local' | 'telescope-web' | 'browser'

---@class HoverOpts
---@field enable (fun():boolean)|boolean|nil (default: `true`) Whether to enable haskell-tools hover
---@field border table|nil The hover window's border. Set to `nil` to disable.
---@field stylize_markdown boolean|nil (default: `false`) The builtin LSP client's default behaviour is to stylize markdown. Setting this option to false sets the file type to markdown and enables treesitter syntax highligting for Haskell snippets if nvim-treesitter is installed
---@field auto_focus boolean|nil (default: `false`) Whether to automatically switch to the hover window

---@class DefinitionOpts
---@field hoogle_signature_fallback boolean|nil (default: `false`) Configure `vim.lsp.definition` to fall back to hoogle search (does not affect `vim.lsp.tagfunc`)

---@alias repl_backend 'cabal' | 'stack'

---@class ReplOpts
---@field handler ReplHandler|nil `'builtin'`: Use the simple builtin repl. `'toggleterm'`: Use akinsho/toggleterm.nvim
---@field prefer repl_backend|nil Prefer cabal or stack when both stack and cabal project files are present?
---@field builtin BuiltinReplOpts|nil Configuration for the builtin repl
---@field auto_focus boolean|nil Whether to auto-focus the repl on toggle or send. The default value of `nil` means the handler decides.

---@alias ReplHandler 'builtin' | 'toggleterm'

---@class BuiltinReplOpts
---@field create_repl_window (fun(view:ReplView):function)|nil How to create the repl window

---@class ReplView
---@field create_repl_split fun(opts:ReplViewOpts):function Create the REPL in a horizontally split window
---@field create_repl_vsplit fun(opts:ReplViewOpts):function Create the REPL in a vertically split window
---@field create_repl_tabnew fun(opts:ReplViewOpts):function Create the REPL in a new tab
---@field create_repl_cur_win fun(opts:ReplViewOpts):function Create the REPL in the current window

---@class ReplViewOpts
---@field delete_buffer_on_exit boolean|nil Whether to delete the buffer when the Repl quits
---@field size function|number|nil The size of the window or a function that determines it

---@class FastTagsOpts
---@field enable (fun():boolean)|boolean|nil Enabled by default if the `fast-tags` executable is found
---@field package_events string[]|nil `autocmd` Events to trigger package tag generation

---@class HTLogOpts
---@field level number|string|nil The log level
---@see vim.log.levels

---@class HaskellLspClientOpts
---@field auto_attach(fun():boolean)|boolean|nil Whether to automatically attach the LSP client. Defaults to `true` if the haskell-language-server executable is found.
---@field debug boolean|nil Whether to enable debug logging
---@field on_attach (fun(client:number,bufnr:number))|nil Callback to execute when the client attaches to a buffer
---@field cmd string[]|nil The command to start the server with
---@field capabilities table|nil LSP client capabilities
---@field settings table|(fun(project_root:string|nil):table)|nil The server config or a function that creates the server config
---@field default_settings table|nil The default server config that will be used if no settings are specified or found
---@see https://haskell-language-server.readthedocs.io/en/latest/configuration.html.
---@comment To print all options that are available for your haskell-language-server version, run `haskell-language-server-wrapper generate-default-config`

---@class HTDapOpts
---@field cmd string[]|nil The command to start haskell-debug-adapter with.
---@field logFile string|nil Log file path for detected configurations.
---@field logLevel LogLevel|nil The log level for detected configurations.

---@alias LogLevel 'Debug' | 'Info' | 'Warning' | 'Error'

local deps = require('haskell-tools.deps')

local config = {
  hls_log = vim.fn.stdpath('log') .. '/' .. 'haskell-language-server.log',
}

local ht_capabilities = vim.lsp.protocol.make_client_capabilities()
local cmp_capabilities = deps.if_available('cmp_nvim_lsp', function(cmp_nvim_lsp)
  return cmp_nvim_lsp.default_capabilities()
end, {})
local selection_range_capabilities = deps.if_available('lsp-selection-range', function(lsp_selection_range)
  return lsp_selection_range.update_capabilities {}
end, {})
local capabilities = vim.tbl_deep_extend('keep', ht_capabilities, cmp_capabilities, selection_range_capabilities)

---@type HTConfig
config.defaults = {
  ---@type ToolsConfig
  tools = {
    ---@type CodeLensConfig
    codeLens = {
      autoRefresh = true,
    },
    ---@type HoogleConfig
    hoogle = {
      mode = 'auto',
    },
    ---@type HoverConfig
    hover = {
      enable = true,
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
      stylize_markdown = false,
      auto_focus = false,
    },
    ---@type DefinitionConfig
    definition = {
      hoogle_signature_fallback = false,
    },
    ---@type ReplConfig
    repl = {
      handler = 'builtin',
      prefer = vim.fn.executable('stack') == 1 and 'stack' or 'cabal',
      ---@type BuiltinReplConfig
      builtin = {
        create_repl_window = function(view)
          -- create_repl_split | create_repl_vsplit | create_repl_tabnew | create_repl_cur_win
          return view.create_repl_split { size = vim.o.lines / 3 }
        end,
      },
      auto_focus = nil,
    },
    ---@type FastTagsConfig
    tags = {
      enable = function()
        return vim.fn.executable('fast-tags') == 1
      end,
      package_events = { 'BufWritePost' },
    },
    ---@type HTLogConfig
    log = {
      level = vim.log.levels.WARN,
    },
  },
  ---@type HaskellLspClientConfig
  hls = {
    auto_attach = function()
      local hls_bin = config.options.hls.cmd[1]
      return vim.fn.executable(hls_bin) ~= 0
    end,
    debug = false,
    on_attach = function(_, _) end,
    cmd = { 'haskell-language-server-wrapper', '--lsp', '--logfile', config.hls_log },
    capabilities = capabilities,
    settings = function(project_root)
      local ht = require('haskell-tools')
      return ht.lsp.load_hls_settings(project_root)
    end,
    default_settings = {
      haskell = {
        -- The formatting providers.
        formattingProvider = 'fourmolu',
        cabalFormattingProvider = 'cabalfmt',
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
  },
  ---@type HTDapConfig
  dap = {
    cmd = { 'haskell-debug-adapter' },
    logFile = vim.fn.stdpath('data') .. '/haskell-dap.log',
    logLevel = 'Warning',
  },
}

---@type HTOpts
local opts = vim.g.haskell_tools or {}
---@type HTConfig
config.options = vim.tbl_deep_extend('force', {}, config.defaults, opts)
if config.options.hls.debug then
  table.insert(config.options.hls.cmd, '--debug')
end
local check = require('haskell-tools.config.check')
local ok, err = check.validate(config.options)
if not ok then
  vim.notify('haskell-tools: ' .. err, vim.log.levels.ERROR)
end

return config

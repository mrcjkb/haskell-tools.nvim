---@mod haskell-tools.config haskell-tools configuration

---@class HaskellToolsConfig
---@field hls_log string The path to the haskell-language-server log file
---@field defaults HTOpts The default configuration options
---@field options HTOpts The configuration options as applied by `setup()`
---@field setup fun(HTOpts?):nil

---@class HTOpts
---@field tools ToolsOpts haskell-tools plugin options
---@field hls HaskellLspClientOpts haskell-language-server client options

---@class ToolsOpts
---@field codeLens CodeLensOpts LSP client codeLens options
---@field hoogle HoogleOpts Hoogle options
---@field hover HoverOpts LSP client hover options
---@field definition DefinitionOpts LSP client definition options
---@field repl ReplOpts GHCi REPL options
---@field tags FastTagsOpts Options for generating tags using fast-tags
---@field log HTLogOpts Logging options

---@class CodeLensOpts
---@field autoRefresh boolean (default: `true`) Whether to auto-refresh code-lenses

---@class HoogleOpts
---@field mode string 'auto', 'telescope-local', 'telescope-web' or 'browser'

---@class HoverOpts
---@field disable boolean (default: `false`) Whether to disable haskell-tools hover and use the builtin lsp's default handler
---@field border table? The hover window's border. Set to `nil` to disable.
---@field stylize_markdown boolean (default: `false`) The builtin LSP client's default behaviour is to stylize markdown. Setting this option to false sets the file type to markdown and enables treesitter syntax highligting for Haskell snippets if nvim-treesitter is installed
---@field auto_focus boolean (default: `false`) Whether to automatically switch to the hover window

---@class DefinitionOpts
---@field hoogle_signature_fallback boolean (default:`false`) Configure `vim.lsp.definition` to fall back to hoogle search (does not affect `vim.lsp.tagfunc`)

---@class ReplOpts
---@field handler string 'builtin': Use the simple builtin repl. 'toggleterm': Use akinsho/toggleterm.nvim
---@field builtin table Configuration for the builtin repl
---@field builtin.create_repl_window fun(ReplView):nil How to create the repl window
---@field auto_focus boolean? Whether to auto-focus the repl on toggle or send. The default value of `nil` means the handler decides.

---@class ReplView
---@field create_repl_split fun(opts:ReplViewOpts?):nil Create the REPL in a horizontally split window
---@field create_repl_vsplit fun(opts:ReplViewOpts?):nil Create the REPL in a vertically split window
---@field create_repl_tabnew fun(opts:ReplViewOpts?):nil Create the REPL in a new tab
---@field create_repl_cur_win fun(opts:ReplViewOpts?):nil Create the REPL in the current window

---@class ReplViewOpts
---@field delete_buffer_on_exit boolean Whether to delete the buffer when the Repl quits
---@field size function|number? The size of the window or a function that determines it

---@class FastTagsOpts
---@field enable boolean Enabled by default if the `fast-tags` executable is found
---@field package_events table autocmd Events to trigger package tag generation

---@class HTLogOpts
---@field level integer|string The log level
---@see vim.log.levels

---@class HaskellLspClientOpts
---@field debug boolean Whether to enable debug logging
---@field on_attach fun(client:number,bufnr:number) Callback to execute when the client attaches to a buffer
---@field cmd table The command to start the server with
---@field filetypes table List of file types to attach the client to
---@field capabilities table LSP client capabilities
---@field settings table The server config
---@see https://haskell-language-server.readthedocs.io/en/latest/configuration.html.
---@comment To print all options that are available for your haskell-language-server version, run `haskell-language-server-wrapper generate-default-config`

local deps = require('haskell-tools.deps')

---@type HaskellToolsConfig
local config = {
  -- TODO: (breaking) Move to log options
  hls_log = vim.fn.stdpath('log') .. '/' .. 'haskell-language-server.log',
}

local ht_capabilities = {}
local cmp_capabilities = deps.if_available('cmp_nvim_lsp', function(cmp_nvim_lsp)
  return cmp_nvim_lsp.default_capabilities()
end, {})
local selection_range_capabilities = deps.if_available('lsp-selection-range', function(lsp_selection_range)
  return lsp_selection_range.update_capabilities {}
end, {})
local capabilities = vim.tbl_deep_extend('keep', ht_capabilities, cmp_capabilities, selection_range_capabilities)

---@type HTOpts
config.defaults = {
  ---@type ToolsOpts
  tools = {
    ---@type CodeLensOpts
    codeLens = {
      autoRefresh = true,
    },
    ---@type HoogleOpts
    hoogle = {
      mode = 'auto',
    },
    ---@type HoverOpts
    hover = {
      disable = false,
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
    ---@type DefinitionOpts
    definition = {
      hoogle_signature_fallback = false,
    },
    ---@type ReplOpts
    repl = {
      handler = 'builtin',
      builtin = {
        create_repl_window = function(view)
          -- create_repl_split | create_repl_vsplit | create_repl_tabnew | create_repl_cur_win
          return view.create_repl_split { size = vim.o.lines / 3 }
        end,
      },
      auto_focus = nil,
    },
    ---@type FastTagsOpts
    tags = {
      enable = vim.fn.executable('fast-tags') == 1,
      package_events = { 'BufWritePost' },
    },
    ---@type HTLogOpts
    log = {
      level = vim.log.levels.WARN,
    },
  },
  ---@type HaskellLspClientOpts
  hls = {
    debug = false,
    on_attach = function(_, _) end,
    cmd = { 'haskell-language-server-wrapper', '--lsp', '--logfile', config.hls_log },
    filetypes = { 'haskell', 'lhaskell', 'cabal', 'cabalproject' },
    capabilities = capabilities,
    settings = {
      haskell = {
        -- The formatting provider.
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
  },
}

---@type HTOpts
config.options = {
  hls = {},
}

---Set the options of this plugin. Called by the haskell-tools setup.
---@param opts HTOpts?
function config.setup(opts)
  config.options = vim.tbl_deep_extend('force', {}, config.defaults, opts or {})
  if config.options.hls.debug then
    table.insert(config.options.hls.cmd, '--debug')
  end
end

return config

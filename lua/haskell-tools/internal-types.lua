---@mod haskell-tools.internal-types

---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

--- Type definitions
---@brief ]]

---@class HsEntryPoint
---@field package_dir string
---@field package_name string
---@field exe_name string
---@field main string
---@field source_dir string

--- Config options (built from HTOpts)
---@class HTConfig
---@field tools ToolsConfig haskell-tools plugin options
---@field hls HaskellLspClientConfig haskell-language-server client options
---@field dap HTDapConfig haskell-debug-adapter client options

---@class ToolsConfig
---@field codeLens CodeLensConfig LSP client codeLens options
---@field hoogle HoogleConfig Hoogle options
---@field hover HoverConfig LSP client hover options
---@field definition DefinitionConfig LSP client definition options
---@field repl ReplConfig GHCi REPL options
---@field tags FastTagsConfig Options for generating tags using fast-tags
---@field log HTLogConfig Logging options

---@class CodeLensConfig
---@field autoRefresh (fun():boolean)|boolean (default: `true`) Whether to auto-refresh code-lenses

---@class HoogleConfig
---@field mode HoogleMode

---@class HoverConfig
---@field disable boolean (default: `false`) Whether to disable haskell-tools hover and use the builtin lsp's default handler
---@field border table|nil The hover window's border. Set to `nil` to disable.
---@field stylize_markdown boolean (default: `false`) The builtin LSP client's default behaviour is to stylize markdown. Setting this option to false sets the file type to markdown and enables treesitter syntax highligting for Haskell snippets if nvim-treesitter is installed
---@field auto_focus boolean|nil (default: `false`) Whether to automatically switch to the hover window

---@class DefinitionConfig
---@field hoogle_signature_fallback boolean (default: `false`) Configure `vim.lsp.definition` to fall back to hoogle search (does not affect `vim.lsp.tagfunc`)

---@class ReplConfig
---@field handler string `'builtin'`: Use the simple builtin repl. `'toggleterm'`: Use akinsho/toggleterm.nvim
---@field prefer repl_backend Prefer cabal or stack when both stack and cabal project files are present?
---@field builtin BuiltinReplConfig Configuration for the builtin repl
---@field auto_focus boolean|nil Whether to auto-focus the repl on toggle or send. The default value of `nil` means the handler decides.

---@class BuiltinReplConfig
---@field create_repl_window fun(view:ReplView):function How to create the repl window

---@class FastTagsConfig
---@field enable (fun():boolean)|boolean Enabled by default if the `fast-tags` executable is found
---@field package_events string[] `autocmd` Events to trigger package tag generation

---@class HTLogConfig
---@field level number|string The log level
---@see vim.log.levels

---@class HaskellLspClientConfig
---@field auto_attach(fun():boolean)|boolean Whether to automatically attach the LSP client
---@field debug boolean Whether to enable debug logging
---@field on_attach fun(client:number,bufnr:number,ht:HaskellTools) Callback to execute when the client attaches to a buffer
---@field cmd string[] The command to start the server with
---@field capabilities table LSP client capabilities
---@field settings table|fun(project_root:string|nil):table The server config or a function that creates the server config
---@field default_settings table The default server config that will be used if no settings are specified or found
---@see https://haskell-language-server.readthedocs.io/en/latest/configuration.html.
---@comment To print all options that are available for your haskell-language-server version, run `haskell-language-server-wrapper generate-default-config`

---@class HTDapConfig
---@field cmd string[] The command to start haskell-debug-adapter with.
---@field logFile string Log file path for detected configurations.
---@field logLevel LogLevel The log level for detected configurations.

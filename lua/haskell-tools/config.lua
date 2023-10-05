---@mod haskell-tools.config plugin configuration
---
---@brief [[
---To configure haskell-tools.nvim, set the variable `vim.g.haskell_tools`,
---which is a `HTOpts` table, in your neovim configuration.
---
---Example:
--->
------@type HTOpts
---vim.g.haskell_tools = {
---   ---@type ToolsOpts
---   tools = {
---     -- ...
---   },
---   ---@type HaskellLspClientOpts
---   hls = {
---     on_attach = function(client, bufnr)
---       -- Set keybindings, etc. here.
---     end,
---     -- ...
---   },
---   ---@type HTDapOpts
---   dap = {
---     -- ...
---   },
--- }
---<
---
---Note: `vim.g.haskell_tools` can also be a function that returns a 'HTOpts' table.
---
---@brief ]]

local config = {}

---@type HTOpts | fun():HTOpts | nil
vim.g.haskell_tools = vim.g.haskell_tools

---@class HTOpts
---@field tools ToolsOpts | nil haskell-tools module options.
---@field hls HaskellLspClientOpts | nil haskell-language-server client options.
---@field dap HTDapOpts | nil debug adapter config for nvim-dap.
---@class ToolsOpts
---@field codeLens CodeLensOpts | nil LSP codeLens options.
---@field hoogle HoogleOpts | nil Hoogle type signature search options.
---@field hover HoverOpts | nil LSP hover options.
---@field definition DefinitionOpts | nil LSP go-to-definition options.
---@field repl ReplOpts | nil GHCi repl options.
---@field tags FastTagsOpts | nil fast-tags module options.
---@field log HTLogOpts | nil haskell-tools logger options.

---@class CodeLensOpts
---@field autoRefresh boolean | (fun():boolean) | nil (default: `true`) Whether to auto-refresh code-lenses.

---@class HoogleOpts
---@field mode HoogleMode | nil Use a telescope with a local hoogle installation or a web backend, or use the browser for hoogle signature search?

---@alias HoogleMode 'auto' | 'telescope-local' | 'telescope-web' | 'browser'

---@class HoverOpts
---@field enable boolean | (fun():boolean) | nil (default: `true`) Whether to enable haskell-tools hover.
---@field border string[][] | nil The hover window's border. Set to `nil` to disable.
---@field stylize_markdown boolean | nil (default: `false`) The builtin LSP client's default behaviour is to stylize markdown. Setting this option to false sets the file type to markdown and enables treesitter syntax highligting for Haskell snippets if nvim-treesitter is installed.
---@field auto_focus boolean | nil (default: `false`) Whether to automatically switch to the hover window.

---@class DefinitionOpts
---@field hoogle_signature_fallback boolean | (fun():boolean) | nil (default: `false`) Configure `vim.lsp.definition` to fall back to hoogle search (does not affect `vim.lsp.tagfunc`).

---@class ReplOpts
---@field handler ReplHandler | (fun():ReplHandler) | nil `'builtin'`: Use the simple builtin repl. `'toggleterm'`: Use akinsho/toggleterm.nvim.
---@field prefer repl_backend | (fun():repl_backend) | nil Prefer cabal or stack when both stack and cabal project files are present?
---@field builtin BuiltinReplOpts | nil Configuration for the builtin repl.
---@field auto_focus boolean | nil Whether to auto-focus the repl on toggle or send. If unset, the handler decides.

---@alias ReplHandler 'builtin' | 'toggleterm'
---@alias repl_backend 'cabal' | 'stack'

---@class BuiltinReplOpts
---@field create_repl_window (fun(view:ReplView):fun(mk_repl_cmd:mk_repl_cmd_fun)) | nil How to create the repl window. Should return a function that calls one of the `ReplView`'s functions.

---@class ReplView
---@field create_repl_split fun(opts:ReplViewOpts):mk_repl_cmd_fun Create the REPL in a horizontally split window.
---@field create_repl_vsplit fun(opts:ReplViewOpts):mk_repl_cmd_fun Create the REPL in a vertically split window.
---@field create_repl_tabnew fun(opts:ReplViewOpts):mk_repl_cmd_fun Create the REPL in a new tab.
---@field create_repl_cur_win fun(opts:ReplViewOpts):mk_repl_cmd_fun Create the REPL in the current window.

---@class ReplViewOpts
---@field delete_buffer_on_exit boolean|nil Whether to delete the buffer when the Repl quits.
---@field size (fun():number)|number|nil The size of the window or a function that determines it.

---@alias mk_repl_cmd_fun fun():(string[]|nil)

---@class FastTagsOpts
---@field enable boolean | (fun():boolean) | nil Enabled by default if the `fast-tags` executable is found.
---@field package_events string[] | nil `autocmd` Events to trigger package tag generation.

---@class HTLogOpts
---@field level number | string | nil The log level.
---@see vim.log.levels

---@class HaskellLspClientOpts
---@field auto_attach boolean | (fun():boolean) | nil Whether to automatically attach the LSP client. Defaults to `true` if the haskell-language-server executable is found.
---@field debug boolean Whether to enable haskell-language-server debug logging.
---@field on_attach (fun(client:number,bufnr:number,ht:HaskellTools)) | nil Callback that is invoked when the client attaches to a buffer.
---@field cmd string[] | (fun():string[]) | nil The command to start haskell-language-server with.
---@field capabilities lsp.ClientCapabilities | nil LSP client capabilities.
---@field settings table | (fun(project_root:string|nil):table) | nil The haskell-language-server settings or a function that creates them. To view the default settings, run `haskell-language-server generate-default-config`.
---@field default_settings table | nil The default haskell-language-server settings that will be used if no settings are specified or detected.
---@field logfile string The path to the haskell-language-server log file.
---@comment To print all options that are available for your haskell-language-server version, run `haskell-language-server-wrapper generate-default-config`
---@see https://haskell-language-server.readthedocs.io/en/latest/configuration.html.

---@class HTDapOpts
---@field cmd string[] | nil The command to start the debug adapter server with.
---@field logFile string | nil Log file path for detected configurations.
---@field logLevel HaskellDebugAdapterLogLevel | nil The log level for detected configurations.
---@field auto_discover boolean | AddDapConfigOpts Set to `false` to disable auto-discovery of launch configurations. `true` uses the default configurations options`.

---@alias HaskellDebugAdapterLogLevel 'Debug' | 'Info' | 'Warning' | 'Error'

return config

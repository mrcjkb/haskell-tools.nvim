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

---@type (fun():HTOpts) | HTOpts | nil
vim.g.haskell_tools = vim.g.haskell_tools

---@class HTOpts
---@field tools? ToolsOpts haskell-tools module options.
---@field hls? HaskellLspClientOpts haskell-language-server client options.
---@field dap? HTDapOpts debug adapter config for nvim-dap.
---@class ToolsOpts
---@field codeLens? CodeLensOpts LSP codeLens options.
---@field hoogle? HoogleOpts Hoogle type signature search options.
---@field hover? HoverOpts LSP hover options.
---@field definition? DefinitionOpts LSP go-to-definition options.
---@field repl? ReplOpts GHCi repl options.
---@field tags? FastTagsOpts fast-tags module options.
---@field log? HTLogOpts haskell-tools logger options.

---@class CodeLensOpts
---@field autoRefresh? (fun():boolean) | boolean (default: `true`) Whether to auto-refresh code-lenses.

---@class HoogleOpts
---@field mode? HoogleMode Use a telescope with a local hoogle installation or a web backend, or use the browser for hoogle signature search?

---@alias HoogleMode 'auto' | 'telescope-local' | 'telescope-web' | 'browser'

---@class HoverOpts
---@field enable? (fun():boolean) | boolean (default: `true`) Whether to enable haskell-tools hover.
---@field border? string[][] The hover window's border. Set to `nil` to disable.
---@field stylize_markdown? boolean (default: `false`) The builtin LSP client's default behaviour is to stylize markdown. Setting this option to false sets the file type to markdown and enables treesitter syntax highligting for Haskell snippets if nvim-treesitter is installed.
---@field auto_focus? boolean (default: `false`) Whether to automatically switch to the hover window.

---@class DefinitionOpts
---@field hoogle_signature_fallback? (fun():boolean) | boolean (default: `false`) Configure `vim.lsp.definition` to fall back to hoogle search (does not affect `vim.lsp.tagfunc`).

---@class ReplOpts
---@field handler? (fun():ReplHandler) | ReplHandler `'builtin'`: Use the simple builtin repl. `'toggleterm'`: Use akinsho/toggleterm.nvim.
---@field prefer? (fun():repl_backend) | repl_backend Prefer cabal or stack when both stack and cabal project files are present?
---@field builtin? BuiltinReplOpts Configuration for the builtin repl.
---@field auto_focus? boolean Whether to auto-focus the repl on toggle or send. If unset, the handler decides.

---@alias ReplHandler 'builtin' | 'toggleterm'
---@alias repl_backend 'cabal' | 'stack'

---@class BuiltinReplOpts
---@field create_repl_window? (fun(view:ReplView):fun(mk_repl_cmd:mk_repl_cmd_fun)) How to create the repl window. Should return a function that calls one of the `ReplView`'s functions.

---@class ReplView
---@field create_repl_split? fun(opts:ReplViewOpts):mk_repl_cmd_fun Create the REPL in a horizontally split window.
---@field create_repl_vsplit? fun(opts:ReplViewOpts):mk_repl_cmd_fun Create the REPL in a vertically split window.
---@field create_repl_tabnew? fun(opts:ReplViewOpts):mk_repl_cmd_fun Create the REPL in a new tab.
---@field create_repl_cur_win? fun(opts:ReplViewOpts):mk_repl_cmd_fun Create the REPL in the current window.

---@class ReplViewOpts
---@field delete_buffer_on_exit? boolean Whether to delete the buffer when the Repl quits.
---@field size? (fun():number) | number The size of the window or a function that determines it.

---@alias mk_repl_cmd_fun fun():(string[]|nil)

---@class FastTagsOpts
---@field enable? boolean | (fun():boolean) Enabled by default if the `fast-tags` executable is found.
---@field package_events? string[] `autocmd` Events to trigger package tag generation.

---@class HTLogOpts
---@field level? number | string The log level.
---@see vim.log.levels

---@class HaskellLspClientOpts
---@field auto_attach? (fun():boolean) | boolean Whether to automatically attach the LSP client. Defaults to `true` if the haskell-language-server executable is found.
---@field debug? boolean Whether to enable haskell-language-server debug logging.
---@field on_attach? fun(client:number,bufnr:number,ht:HaskellTools) Callback that is invoked when the client attaches to a buffer.
---@field cmd? (fun():string[]) | string[] The command to start haskell-language-server with.
---@field capabilities? lsp.ClientCapabilities LSP client capabilities.
---@field settings? (fun(project_root:string|nil):table) | table The haskell-language-server settings or a function that creates them. To view the default settings, run `haskell-language-server generate-default-config`.
---@field default_settings? table The default haskell-language-server settings that will be used if no settings are specified or detected.
---@field logfile? string The path to the haskell-language-server log file.

---@brief [[
--- To print all options that are available for your haskell-language-server version, run `haskell-language-server-wrapper generate-default-config`
---See: https://haskell-language-server.readthedocs.io/en/latest/configuration.html.
---@brief ]]

---@class HTDapOpts
---@field cmd? string[] The command to start the debug adapter server with.
---@field logFile? string Log file path for detected configurations.
---@field logLevel? HaskellDebugAdapterLogLevel The log level for detected configurations.
---@field auto_discover? boolean | AddDapConfigOpts Set to `false` to disable auto-discovery of launch configurations. `true` uses the default configurations options`.

---@alias HaskellDebugAdapterLogLevel 'Debug' | 'Info' | 'Warning' | 'Error'

return config

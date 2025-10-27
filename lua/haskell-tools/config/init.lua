---@mod haskell-tools.config plugin configuration
---
---@brief [[
---To configure haskell-tools.nvim, set the variable `vim.g.haskell_tools`,
---which is a `haskell-tools.Opts` table, in your neovim configuration.
---
---Example:
--->
------@type haskell-tools.Opts
---vim.g.haskell_tools = {
---   ---@type haskell-tools.tools.Opts
---   tools = {
---     -- ...
---   },
---   ---@type haskell-tools.lsp.ClientOpts
---   hls = {
---     on_attach = function(client, bufnr)
---       -- Set keybindings, etc. here.
---     end,
---     -- ...
---   },
---   ---@type haskell-tools.dap.Opts
---   dap = {
---     -- ...
---   },
--- }
---<
---
---Note: `vim.g.haskell_tools` can also be a function that returns a 'haskell-tools.Opts' table.
---
---@brief ]]

local config = {}

---@type (fun():haskell-tools.Opts) | haskell-tools.Opts | nil
vim.g.haskell_tools = vim.g.haskell_tools

---@class haskell-tools.Opts
---
---haskell-tools module options.
---@field tools? haskell-tools.tools.Opts
---
---haskell-language-server client options.
---You can also configure some of these options via |vim.lsp.config()|, with the `"hls"` key.
---If both the `hls` table and a `vim.lsp.config["hls"]` are defined,
---haskell-tools.nvim merges |vim.lsp.config()| settings into the `hls` table,
---giving them precedence over existing settings.
---Note that |vim.lsp.config()| expects a |vim.lsp.ClientConfig|.
---Although you can also pass in |haskell-tools.lsp.ClientOpts|, doing so is not
-- officially supported and may not be possible in the future.
---@field hls? haskell-tools.lsp.ClientOpts
---
---debug adapter config for nvim-dap.
---@field dap? haskell-tools.dap.Opts

---@class haskell-tools.tools.Opts
---
---LSP codeLens options.
---@field codeLens? haskell-tools.codeLens.Opts
---
---Hoogle type signature search options.
---@field hoogle? haskell-tools.hoogle.Opts
---
---LSP hover options.
---@field hover? haskell-tools.hover.Opts
---LSP go-to-definition options.
---@field definition? haskell-tools.definition.Opts
---
---GHCi repl options.
---@field repl? haskell-tools.repl.Opts
---
---fast-tags module options.
---@field tags? haskell-tools.fast-tags.Opts
---
---haskell-tools logger options.
---@field log? haskell-tools.log.Opts
---
---custom action for opening a url
---@field open_url? fun(url: string)

---@class haskell-tools.codeLens.Opts
---
---(default: `true`) Whether to auto-refresh code-lenses.
---@field autoRefresh? (fun():boolean) | boolean

---@class haskell-tools.hoogle.Opts
---
---Use a telescope with a local hoogle installation or a web backend,
---or use the browser for hoogle signature search?
---@field mode? haskell-tools.hoogle.Mode

---@alias haskell-tools.hoogle.Mode 'auto' | 'telescope-local' | 'telescope-web' | 'browser'

---@class haskell-tools.hover.Opts
---
---(default: `true`) Whether to enable haskell-tools hover.
---@field enable? (fun():boolean) | boolean
---
---The hover window's border. Set to `nil` to disable.
---@field border? string[][]
---
---(default: `false`) The builtin LSP client's default behaviour is to stylize markdown.
---Setting this option to false sets the file type to markdown
---and enables treesitter syntax highlighting for Haskell snippets if nvim-treesitter is installed.
---@field stylize_markdown? boolean
---
---(default: `false`) Whether to automatically switch to the hover window.
---@field auto_focus? boolean

---@class haskell-tools.definition.Opts
---
---(default: `false`) Configure |vim.lsp.definition| to fall back to hoogle search
---(does not affect |vim.lsp.tagfunc|).
---@field hoogle_signature_fallback? (fun():boolean) | boolean

---@class haskell-tools.repl.Opts
---
---`'builtin'`: Use the simple builtin repl.
---`'toggleterm'`: Use akinsho/toggleterm.nvim.
---@field handler? (fun():haskell-tools.repl.Handler) | haskell-tools.repl.Handler
---
---Prefer cabal or stack when both stack and cabal project files are present?
---@field prefer? (fun():haskell-tools.repl.Backend) | haskell-tools.repl.Backend
---
---Configuration for the builtin repl.
---@field builtin? haskell-tools.repl.builtin.Opts
---
---Whether to auto-focus the repl on toggle or send. If unset, the handler decides.
---@field auto_focus? boolean

---@alias haskell-tools.repl.Handler 'builtin' | 'toggleterm'
---@alias haskell-tools.repl.Backend 'cabal' | 'stack'

---@class haskell-tools.repl.builtin.Opts
---
---How to create the repl window.
---Should return a function that calls one of the |haskell-tools.repl.View|'s functions.
---@field create_repl_window? (fun(view:haskell-tools.repl.View):fun(mk_repl_cmd:mk_ht_repl_cmd_fun))

---@class haskell-tools.repl.View
---
---Create the REPL in a horizontally split window.
---@field create_repl_split? fun(opts:haskell-tools.repl.view.Opts):mk_ht_repl_cmd_fun
---
---Create the REPL in a vertically split window.
---@field create_repl_vsplit? fun(opts:haskell-tools.repl.view.Opts):mk_ht_repl_cmd_fun
---
---Create the REPL in a new tab.
---@field create_repl_tabnew? fun(opts:haskell-tools.repl.view.Opts):mk_ht_repl_cmd_fun
---
---Create the REPL in the current window.
---@field create_repl_cur_win? fun(opts:haskell-tools.repl.view.Opts):mk_ht_repl_cmd_fun

---@class haskell-tools.repl.view.Opts
---
---Whether to delete the buffer when the Repl quits.
---@field delete_buffer_on_exit? boolean
---
---The size of the window or a function that determines it.
---@field size? (fun():number) | number

---@alias mk_ht_repl_cmd_fun fun():(string[]|nil)

---@class haskell-tools.fast-tags.Opts
---
---Enabled by default if the `fast-tags` executable is found.
---@field enable? boolean | (fun():boolean)
---
---The |autocmd| events to trigger package tag generation.
---@field package_events? string[]

---@class haskell-tools.log.Opts
---
---The log level.
---@field level? number | string
---@see vim.log.levels

---@class haskell-tools.lsp.ClientOpts
---
---Whether to automatically attach the LSP client.
---Defaults to `true` if the haskell-language-server executable is found.
---@field auto_attach? (fun():boolean) | boolean
---
---Whether to enable haskell-language-server debug logging.
---@field debug? boolean
---
---Callback that is invoked when the client attaches to a buffer.
---@field on_attach? fun(client:number,bufnr:number,ht:HaskellTools)
---
---The command to start haskell-language-server with.
---@field cmd? (fun():string[]) | string[]
---
---LSP client capabilities.
---@field capabilities? lsp.ClientCapabilities
---
---The haskell-language-server settings or a function that creates them.
---To view the default settings, run `haskell-language-server generate-default-config`.
---@field settings? (fun(project_root:string|nil):table) | table
---
---The default haskell-language-server settings that will be used if no settings are specified or detected.
---@field default_settings? table
---
---The path to the haskell-language-server log file.
---@field logfile? string

---@brief [[
--- To print all options that are available for your haskell-language-server version, run `haskell-language-server-wrapper generate-default-config`
---See: https://haskell-language-server.readthedocs.io/en/latest/configuration.html.
---@brief ]]

---@class haskell-tools.dap.Opts
---
---The command to start the debug adapter server with.
---@field cmd? string[]
---
---Log file path for detected configurations.
---@field logFile? string
---
---The log level for detected configurations.
---@field logLevel? haskell-tools.debugAdapter.LogLevel
---@field auto_discover? boolean | haskell-tools.dap.AddConfigOpts Set to `false` to disable auto-discovery of launch configurations. `true` uses the default configurations options`.

---@alias haskell-tools.debugAdapter.LogLevel 'Debug' | 'Info' | 'Warning' | 'Error'

---@class haskell-tools.dap.AddConfigOpts
---
---Whether to automatically detect launch configurations for the project.
---@field autodetect boolean
---
---File name or pattern to search for.
---Defaults to 'launch.json'.
---@field settings_file_pattern string

return config

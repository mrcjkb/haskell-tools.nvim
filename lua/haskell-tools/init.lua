local M = {
  config = nil,
  lsp = nil,
  hoogle = nil,
  repl = nil,
  project = nil,
  tags = nil,
}

function M.setup(opts)
  local config = require('haskell-tools.config')
  M.config = config
  local lsp = require('haskell-tools.lsp')
  M.lsp = lsp
  local hoogle = require('haskell-tools.hoogle')
  M.hoogle = hoogle
  local repl = require('haskell-tools.repl')
  M.repl = repl
  local project = require('haskell-tools.project')
  M.project = project
  local tags = require('haskell-tools.tags')
  M.tags = tags

  config.setup(opts)
  lsp.setup()
  hoogle.setup()
  repl.setup()
  project.setup()
  tags.setup()

end

return M

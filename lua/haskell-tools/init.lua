local ht = {
  config = nil,
  log = nil,
  lsp = nil,
  hoogle = nil,
  repl = nil,
  project = nil,
  tags = nil,
}

function ht.setup(opts)
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

  config.setup(opts)
  log.setup()
  log.debug { 'Config', config.options }
  lsp.setup()
  hoogle.setup()
  repl.setup()
  project.setup()
  tags.setup()
end

return ht

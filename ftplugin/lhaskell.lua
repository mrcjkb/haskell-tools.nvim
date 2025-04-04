if vim.fn.has('nvim-0.11') ~= 1 then
  vim.notify_once('haskell-tools.nvim requires Neovim 0.11 or above', vim.log.levels.ERROR)
  return
end
require('haskell-tools.internal').ftplugin()

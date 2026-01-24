vim.env.LAZY_STDPATH = '.repro'
---@diagnostic disable-next-line: param-type-mismatch
load(vim.fn.system('curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua'))()

require('lazy.minit').repro {
  spec = {
    {
      'mrcjkb/haskell-tools.nvim',
      version = '^7',
      init = function()
        -- Configure haskell-tools.nvim here
        vim.g.haskell_tools = {}
      end,
      dependencies = {
        -- Uncomment or add any optional dependencies needed to reproduce the issue
        -- 'nvim-telescope/telescope.nvim',
        -- 'akinsho/toggleterm.nvim',
      },
      lazy = false,
    },
  },
}

-- do anything else you need to do to reproduce the issue

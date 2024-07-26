vim.env.LAZY_STDPATH = '.repro'
load(vim.fn.system('curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua'))()

require('lazy.minit').repro {
  spec = {
    {
      'mrcjkb/haskell-tools.nvim',
      version = '^4',
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

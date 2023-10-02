{self}: final: prev: {
  haskell-tools-nvim-dev = prev.vimUtils.buildVimPlugin {
    name = "haskell-tools.nvim";
    src = self;
  };
}

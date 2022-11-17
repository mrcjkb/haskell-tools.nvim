{ self }:
final: prev: {
  haskell-tools-nvim-dev = prev.vimUtils.buildVimPluginFrom2Nix {
    name = "haskell-tools-nvim";
    src = self;
  };
}

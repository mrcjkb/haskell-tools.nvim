{neovim-nightly}: final: prev: let
  inherit (final) lib;

  mkNvimMinimal = nvim:
    final.wrapNeovimUnstable nvim {
      withPython3 = true;
      viAlias = true;
      vimAlias = true;
      wrapRc = false;
      plugins = with final.vimPlugins; [
        haskell-tools-nvim
        prev.vimPlugins.nvim-treesitter.withAllGrammars
      ];
      wrapperArgs =
        ''--set NVIM_APPNAME "nvim-haskell-tools" ''
        + ''--prefix PATH : "${lib.makeBinPath [final.haskell-language-server]}"'';
    };
in {
  nvim-minimal-stable = mkNvimMinimal final.neovim-unwrapped;
  nvim-minimal-nightly = mkNvimMinimal neovim-nightly;
}

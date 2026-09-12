{neovim-nightly}: final: prev: let
  inherit (final) lib;

  mkNvimMinimal = nvim:
    with final; let
      neovimConfig = neovimUtils.makeNeovimConfig {
        withPython3 = true;
        viAlias = true;
        vimAlias = true;
        plugins = with vimPlugins; [
          haskell-tools-nvim
          prev.vimPlugins.nvim-treesitter.withAllGrammars
        ];
      };
      runtimeDeps = [
        haskell-language-server
      ];
    in
      final.wrapNeovimUnstable nvim (neovimConfig
        // {
          wrapperArgs =
            lib.escapeShellArgs neovimConfig.wrapperArgs
            + " "
            + ''--set NVIM_APPNAME "nvim-haskell-tools"''
            + " "
            + ''--prefix PATH : "${lib.makeBinPath runtimeDeps}"'';
          wrapRc = false;
        });
in {
  nvim-minimal-stable = mkNvimMinimal final.neovim-unwrapped;
  nvim-minimal-nightly = mkNvimMinimal neovim-nightly;
}

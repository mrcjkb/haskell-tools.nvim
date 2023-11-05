{self}: final: prev: let
  lib = final.lib;

  haskell-tools-nvim-luaPackage-override = luaself: luaprev: {
    haskell-tools-nvim = luaself.callPackage ({
      luaOlder,
      buildLuarocksPackage,
      lua,
    }:
      buildLuarocksPackage {
        pname = "haskell-tools.nvim";
        version = "scm-1";
        knownRockspec = "${self}/haskell-tools.nvim-scm-1.rockspec";
        src = self;
        disabled = luaOlder "5.1";
      }) {};
  };

  lua5_1 = prev.lua5_1.override {
    packageOverrides = haskell-tools-nvim-luaPackage-override;
  };

  lua51Packages = final.lua5_1.pkgs;
in {
  inherit
    lua5_1
    lua51Packages
    ;

  haskell-tools-nvim-dev = final.neovimUtils.buildNeovimPlugin {
    pname = "haskell-tools.nvim";
    version = "scm-1";
    src = self;
  };

  neovim-minimal = let
    neovimConfig = final.neovimUtils.makeNeovimConfig {
      withPython3 = true;
      viAlias = true;
      vimAlias = true;
      plugins = with final.vimPlugins; [
        haskell-tools-nvim
      ];
    };
    runtimeDeps = [
      final.haskell-language-server
    ];
  in
    final.wrapNeovimUnstable final.neovim-nightly (neovimConfig
      // {
        wrapperArgs =
          lib.escapeShellArgs neovimConfig.wrapperArgs
          + " "
          + ''--set NVIM_APPNAME "nvim-haskell-tools"''
          + " "
          + ''--prefix PATH : "${lib.makeBinPath runtimeDeps}"'';
        wrapRc = false;
      });
}

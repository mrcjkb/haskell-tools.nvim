{
  self,
  name,
}: final: prev: let
  haskell-tools-nvim-luaPackage-override = luaself: luaprev: {
    haskell-tools-nvim = luaself.callPackage ({
      luaOlder,
      buildLuarocksPackage,
    }:
      buildLuarocksPackage {
        pname = name;
        version = "dev-1";
        knownRockspec = "${self}/haskell-tools.nvim-dev-1.rockspec";
        src = self;
        disabled = luaOlder "5.1";
      }) {};
  };

  lua5_1 = prev.lua5_1.override {
    packageOverrides = haskell-tools-nvim-luaPackage-override;
  };
  luajit = prev.luajit.override {
    packageOverrides = haskell-tools-nvim-luaPackage-override;
  };

  lua51Packages = final.lua5_1.pkgs;
  luajitPackages = final.luajit.pkgs;
in {
  inherit
    lua5_1
    lua51Packages
    luajit
    luajitPackages
    ;

  vimPlugins =
    prev.vimPlugins
    // {
      haskell-tools-nvim = final.neovimUtils.buildNeovimPlugin {
        luaAttr = final.luajitPackages.haskell-tools-nvim;
      };
    };

  inherit (final.vimPlugins) haskell-tools-nvim;
  haskell-tools-nvim-dev = final.vimPlugins.haskell-tools-nvim;
}

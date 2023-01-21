{
  self,
  pkgs,
  lib,
  stdenv,
  ...
}: let
  tag = self.shortRev or null;
  rev =
    if tag != null
    then "${tag}"
    else "scm";
  luarocks-package = stdenv.mkDerivation {
    name = "haskell-tools-${rev}-rockspec";

    src = self;

    installPhase = ''
      mkdir -p $out
      cp haskell-tools.nvim-scm-1.rockspec $out/haskell-tools.nvim-${rev}-1.rockspec
    '';
  };
in
  pkgs.writeShellApplication {
    name = "luarocks-upload";
    runtimeInputs = with pkgs; [
      lua51Packages.luarocks
      lua51Packages.dkjson # Needed for luarocks upload
      luarocks-package
      sd
      git
    ];
    text = lib.optionalString (tag != null) ''
      rstmp=$(mktemp -d)
      modrev=$(git describe --tags --always --first-parent)
      cp -x "${luarocks-package}/haskell-tools.nvim-${rev}-1.rockspec" "$rstmp/haskell-tools.nvim-$modrev-1.rockspec"
      sd "= 'scm'" "= '$modrev'" "$rstmp/haskell-tools.nvim-$modrev-1.rockspec"
      luarocks upload "$rstmp/haskell-tools.nvim-$modrev-1.rockspec" --api-key="$LUAROCKS_API_KEY"
    '';
  }

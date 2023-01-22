{
  self,
  packer-nvim,
  plenary-nvim,
  nvim-lspconfig,
  telescope-nvim,
  toggleterm,
}: final: prev:
with final.lib;
with final.lib.strings;
with final.stdenv; let
  lints = mkDerivation {
    name = "haskell-tools-lints";

    src = self;

    phases = [
      "unpackPhase"
      "buildPhase"
      "checkPhase"
    ];

    doCheck = true;

    buildInputs = with final; [
      lua51Packages.luacheck
      sumneko-lua-language-server
    ];

    buildPhase = ''
      mkdir -p $out
      cp -r lua $out/lua
      cp -r tests $out/tests
      cp .luacheckrc $out
      cp .luarc.json $out
    '';

    checkPhase = ''
      export HOME=$(realpath .)
      cd $out
      luacheck lua
      luacheck tests
      lua-language-server --check "$out/lua" \
        --configpath "$out/.luarc.json" \
        --logpath "$out" \
        --checklevel="Warning"
      if [[ -f $out/check.json ]]; then
        cat $out/check.json
        exit 1
      fi
    '';
  };

  nvim-nightly = final.neovim-nightly;

  mkPlenaryTest = {
    name,
    nvim ? final.neovim,
    withTelescope ? true,
    extraPkgs ? [],
  }:
    mkDerivation {
      inherit name;

      phases = [
        "buildPhase"
        "checkPhase"
      ];

      doCheck = true;

      buildInputs = with final;
        [
          nvim
          makeWrapper
        ]
        ++ extraPkgs;

      buildPhase = ''
        mkdir -p $out
        mkdir -p $out/.config/nvim/site/pack/packer/start
        ln -s ${packer-nvim} $out/.config/nvim/site/pack/packer/start/packer.nvim
        ln -s ${plenary-nvim} $out/.config/nvim/site/pack/packer/start/plenary.nvim
        ln -s ${nvim-lspconfig} $out/.config/nvim/site/pack/packer/start/nvim-lspconfig
        ln -s ${toggleterm} $out/.config/nvim/site/pack/packer/start/toggleterm.nvim
        ${optionalString withTelescope "ln -s ${telescope-nvim} $out/.config/nvim/site/pack/packer/start/telescope.nvim"}
        ln -s ${./..} $out/.config/nvim/site/pack/packer/start/${name}
      '';

      checkPhase = ''
        export NVIM_DATA_MINIMAL=$(realpath $out/.config/nvim)
        export HOME=$(realpath .)
        cd ${./..}
        # TODO: split test directories by environment
        nvim --headless --noplugin -u ${../tests/minimal.lua} -c "PlenaryBustedDirectory ${../tests} {minimal_init = '${../tests/minimal.lua}'}"
      '';
    };
in {
  inherit lints;

  haskell-tools-test = mkPlenaryTest {name = "haskell-tools";};

  haskell-tools-test-no-telescope = mkPlenaryTest {
    name = "haskell-tools-no-telescope";
    withTelescope = false;
  };

  haskell-tools-test-no-telescope-with-hoogle = mkPlenaryTest {
    name = "haskell-tools-no-telescope-local-hoogle";
    withTelescope = false;
    extraPkgs = [final.pkgs.haskellPackages.hoogle];
  };

  haskell-tools-test-nightly = mkPlenaryTest {
    nvim = nvim-nightly;
    name = "haskell-tools-nightly";
  };

  haskell-tools-test-no-telescope-nightly = mkPlenaryTest {
    nvim = nvim-nightly;
    name = "haskell-tools-no-telescope-nightly";
    withTelescope = false;
  };

  haskell-tools-test-no-telescope-with-hoogle-nightly = mkPlenaryTest {
    nvim = nvim-nightly;
    name = "haskell-tools-no-telescope-local-hoogle-nightly";
    withTelescope = false;
    extraPkgs = [final.pkgs.haskellPackages.hoogle];
  };
}

{
  self,
  plenary-nvim,
  telescope-nvim,
  toggleterm,
}: final: prev:
with final.lib;
with final.lib.strings;
with final.stdenv; let
  nvim-nightly = final.neovim-nightly;

  plenary-plugin = final.pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "plenary.nvim";
    src = plenary-nvim;
  };

  telescope-plugin = final.pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "telescope.nvim";
    src = telescope-nvim;
  };

  toggleterm-plugin = final.pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "toggleterm";
    src = toggleterm;
  };

  mkPlenaryTest = {
    name,
    nvim ? final.neovim-unwrapped,
    withTelescope ? true,
    withHls ? true,
    extraPkgs ? [],
  }: let
    nvim-wrapped = final.pkgs.wrapNeovim nvim {
      configure = {
        customRC = ''
          lua << EOF
          vim.cmd('runtime! plugin/plenary.vim')
          EOF
        '';
        packages.myVimPackage = {
          start =
            [
              final.haskell-tools-nvim-dev
              plenary-plugin
              toggleterm-plugin
            ]
            ++ (
              if withTelescope
              then [telescope-plugin]
              else []
            );
        };
      };
    };
  in
    mkDerivation {
      inherit name;

      src = self;

      phases = [
        "unpackPhase"
        "buildPhase"
        "checkPhase"
      ];

      doCheck = true;

      buildInputs = with final;
        [
          nvim-wrapped
          makeWrapper
          curl
        ]
        ++ (
          if withHls
          then [haskell-language-server]
          else []
        )
        ++ extraPkgs;

      buildPhase = ''
        mkdir -p $out
        cp -r tests $out
        # FIXME: Fore some reason, this doesn't work
        # haskell-language-server-wrapper generate-default-config > $out/tests/hls.json
      '';

      checkPhase = ''
        export HOME=$(realpath .)
        export TEST_CWD=$(realpath $out/tests)
        cd $out
        nvim --headless --noplugin -c "PlenaryBustedDirectory tests {nvim_cmd = 'nvim'}"
      '';
    };
in {
  haskell-tools-test = mkPlenaryTest {name = "haskell-tools";};

  haskell-tools-test-no-hls = mkPlenaryTest {
    name = "haskell-tools-no-hls";
    withHls = false;
  };

  haskell-tools-test-no-telescope = mkPlenaryTest {
    name = "haskell-tools-no-telescope";
    withTelescope = false;
  };

  haskell-tools-test-no-telescope-with-hoogle = mkPlenaryTest {
    name = "haskell-tools-no-telescope-local-hoogle";
    withTelescope = false;
    extraPkgs = [final.pkgs.haskellPackages.hoogle];
  };

  haskell-tools-test-with-stack = mkPlenaryTest {
    name = "haskell-tools-with-stack";
    extraPkgs = [final.pkgs.stack];
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

  inherit
    nvim-nightly
    plenary-plugin
    ;
}

{
  self,
  neodev-nvim,
  telescope-nvim,
  nvim-dap,
  toggleterm,
}: final: prev:
with final.lib;
with final.lib.strings;
with final.stdenv; let
  nvim-nightly = final.pkgs.neovim-nightly;

  neodev-plugin = final.pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "neodev.nvim";
    src = neodev-nvim;
  };

  telescope-plugin = final.pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "telescope.nvim";
    src = telescope-nvim;
  };

  nvim-dap-plugin = final.pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "nvim-dap";
    src = nvim-dap;
  };

  toggleterm-plugin = final.pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "toggleterm";
    src = toggleterm;
  };

  mkNeorocksTest = {
    name,
    nvim ? final.neovim-unwrapped,
    withTelescope ? true,
    withHls ? true,
    extraPkgs ? [],
  }: let
    nvim-wrapped = final.pkgs.wrapNeovim nvim {
      configure = {
        packages.myVimPackage = {
          start =
            [
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
    final.pkgs.neorocksTest {
      inherit name;
      pname = "haskell-tools.nvim";
      src = self;
      neovim = nvim;

      luaPackages = ps: with ps; [plenary-nvim];

      extraPackages = with final;
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

      preCheck = ''
        # Neovim expects to be able to create log files, etc.
        export HOME=$(realpath .)
      '';
    };
in {
  haskell-tools-test = mkNeorocksTest {name = "haskell-tools";};

  haskell-tools-test-no-hls = mkNeorocksTest {
    name = "haskell-tools-no-hls";
    withHls = false;
  };

  haskell-tools-test-no-telescope = mkNeorocksTest {
    name = "haskell-tools-no-telescope";
    withTelescope = false;
  };

  haskell-tools-test-no-telescope-with-hoogle = mkNeorocksTest {
    name = "haskell-tools-no-telescope-local-hoogle";
    withTelescope = false;
    extraPkgs = [final.pkgs.haskellPackages.hoogle];
  };

  haskell-tools-test-with-stack = mkNeorocksTest {
    name = "haskell-tools-with-stack";
    extraPkgs = [final.pkgs.stack];
  };

  haskell-tools-test-nightly = mkNeorocksTest {
    nvim = nvim-nightly;
    name = "haskell-tools-nightly";
  };

  haskell-tools-test-no-telescope-nightly = mkNeorocksTest {
    nvim = nvim-nightly;
    name = "haskell-tools-no-telescope-nightly";
    withTelescope = false;
  };

  haskell-tools-test-no-telescope-with-hoogle-nightly = mkNeorocksTest {
    nvim = nvim-nightly;
    name = "haskell-tools-no-telescope-local-hoogle-nightly";
    withTelescope = false;
    extraPkgs = [final.pkgs.haskellPackages.hoogle];
  };

  inherit
    nvim-nightly
    plenary-plugin
    neodev-plugin
    telescope-plugin
    nvim-dap-plugin
    toggleterm-plugin
    ;
}

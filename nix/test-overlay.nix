{self}: final: prev:
with final.lib;
with final.lib.strings;
with final.stdenv; let
  nvim-nightly = final.neovim-nightly;

  mkNeorocksTest = {
    name,
    nvim ? final.neovim-unwrapped,
    withTelescope ? true,
    withHls ? true,
    extraPkgs ? [],
  }: let
    nvim-wrapped = with final.vimPlugins;
      final.wrapNeovim nvim {
        configure = {
          packages.myVimPackage = {
            start =
              [
                toggleterm-nvim
              ]
              ++ (
                if withTelescope
                then [
                  telescope-nvim
                  plenary-nvim
                ]
                else []
              );
          };
        };
      };
  in
    final.neorocksTest {
      inherit name;
      pname = "haskell-tools.nvim";
      src = self;
      neovim = nvim-wrapped;

      extraPackages = with final;
        [
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

  mkNvimMinimal = nvim:
    with final; let
      neovimConfig = neovimUtils.makeNeovimConfig {
        withPython3 = true;
        viAlias = true;
        vimAlias = true;
        plugins = with vimPlugins; [
          haskell-tools-nvim-dev
          nvim-treesitter.withAllGrammars
        ];
      };
      runtimeDeps = [
        haskell-language-server
      ];
    in
      wrapNeovimUnstable nvim (neovimConfig
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
    extraPkgs = [final.haskellPackages.hoogle];
  };

  haskell-tools-test-with-stack = mkNeorocksTest {
    name = "haskell-tools-with-stack";
    extraPkgs = [final.stack];
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
    extraPkgs = [final.haskellPackages.hoogle];
  };

  nvim-minimal-stable = mkNvimMinimal final.neovim-unwrapped;
  nvim-minimal-nightly = mkNvimMinimal final.neovim-nightly;

  inherit
    nvim-nightly
    neodev-plugin
    telescope-plugin
    nvim-dap-plugin
    toggleterm-plugin
    ;
}

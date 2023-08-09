{
  description = "haskell-tools.nvim - supercharge your haskell experience in neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # inputs for tests
    plenary-nvim = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };

    telescope-nvim = {
      url = "github:nvim-telescope/telescope.nvim";
      flake = false;
    };

    nvim-dap = {
      url = "github:mfussenegger/nvim-dap";
      flake = false;
    };

    toggleterm = {
      url = "github:akinsho/toggleterm.nvim";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    neovim-nightly-overlay,
    pre-commit-hooks,
    flake-utils,
    ...
  }: let
    supportedSystems = [
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    test-overlay = import ./nix/test-overlay.nix {
      inherit
        (inputs)
        self
        plenary-nvim
        telescope-nvim
        nvim-dap
        toggleterm
        ;
    };

    haskell-tooling-overlay = import ./nix/haskell-tooling-overlay.nix {inherit self;};
  in
    flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          haskell-tooling-overlay
          test-overlay
          neovim-nightly-overlay.overlay
        ];
      };

      haskell-tools-nvim = pkgs.vimUtils.buildVimPluginFrom2Nix {
        name = "haskell-tools";
        src = self;
      };

      docgen = pkgs.callPackage ./nix/docgen.nix {};

      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = self;
        hooks = {
          alejandra.enable = true;
          stylua.enable = true;
          luacheck.enable = true;
          lua-ls.enable = true;
          editorconfig-checker.enable = true;
          markdownlint.enable = true;
        };
        settings = {
          lua-ls = {
            config = {
              runtime.version = "LuaJIT";
              Lua = {
                workspace = {
                  library = [
                    "${pkgs.neovim-nightly}/share/nvim/runtime/lua"
                    "${pkgs.plenary-plugin}/lua"
                    "${pkgs.telescope-plugin}/lua"
                    "${pkgs.toggleterm-plugin}/lua"
                    "${pkgs.nvim-dap-plugin}/lua"
                  ];
                  checkThirdParty = false;
                  ignoreDir = [
                    ".git"
                    ".github"
                    ".direnv"
                    "result"
                    "nix"
                    "doc"
                  ];
                };
                diagnostics.libraryFiles = "Disable";
              };
            };
          };
        };
      };

      haskell-tools-shell = pkgs.mkShell {
        name = "haskell-tools.nvim-shell";
        inherit (pre-commit-check) shellHook;
        buildInputs = with pre-commit-hooks.packages.${system}; [
          alejandra
          lua-language-server
          stylua
          luacheck
          editorconfig-checker
          markdownlint-cli
        ];
      };
    in {
      devShells = rec {
        default = haskell-tools;
        haskell-tools = haskell-tools-shell;
      };

      packages = {
        default = haskell-tools-nvim;
        inherit
          docgen
          haskell-tools-nvim
          ;
      };

      checks = {
        inherit pre-commit-check;
        inherit
          (pkgs)
          haskell-tools-test
          haskell-tools-test-no-hls
          haskell-tools-test-no-telescope
          haskell-tools-test-no-telescope-with-hoogle
          haskell-tools-test-nightly
          haskell-tools-test-no-telescope-nightly
          haskell-tools-test-no-telescope-with-hoogle-nightly
          ;
      };
    })
    // {
      overlays = {
        inherit
          test-overlay
          haskell-tooling-overlay
          ;
        default = haskell-tooling-overlay;
      };
    };
}

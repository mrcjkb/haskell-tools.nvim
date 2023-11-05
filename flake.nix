{
  description = "haskell-tools.nvim - supercharge your haskell experience in neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    neorocks = {
      url = "github:nvim-neorocks/neorocks";
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

    # inputs for tests and lints
    neodev-nvim = {
      url = "github:folke/neodev.nvim";
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
    neorocks,
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
        neodev-nvim
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
          neorocks.overlays.default
        ];
      };

      docgen = pkgs.callPackage ./nix/docgen.nix {};

      mkTypeCheck = {
        nvim-api ? [],
        disabled-diagnostics ? [],
      }:
        pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            lua-ls.enable = true;
          };
          settings = {
            lua-ls = {
              config = {
                runtime.version = "LuaJIT";
                Lua = {
                  workspace = {
                    library =
                      nvim-api
                      ++ [
                        "${pkgs.telescope-plugin}/lua"
                        "${pkgs.toggleterm-plugin}/lua"
                        "${pkgs.nvim-dap-plugin}/lua"
                        # FIXME:
                        # "${pkgs.luajitPackages.busted}"
                      ];
                    checkThirdParty = false;
                    ignoreDir = [
                      ".git"
                      ".github"
                      ".direnv"
                      "result"
                      "nix"
                      "doc"
                      "spec" # FIXME: Add busted library
                    ];
                  };
                  diagnostics = {
                    libraryFiles = "Disable";
                    disable = disabled-diagnostics;
                  };
                };
              };
            };
          };
        };

      type-check-stable = mkTypeCheck {
        nvim-api = [
          "${pkgs.neovim}/share/nvim/runtime/lua"
          "${pkgs.neodev-plugin}/types/stable"
        ];
        disabled-diagnostics = [
          "undefined-doc-name"
          "redundant-parameter"
          "invisible"
        ];
      };

      type-check-nightly = mkTypeCheck {
        nvim-api = [
          "${pkgs.neovim-nightly}/share/nvim/runtime/lua"
          "${pkgs.neodev-plugin}/types/nightly"
        ];
      };

      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = self;
        hooks = {
          alejandra.enable = true;
          stylua.enable = true;
          luacheck.enable = true;
          editorconfig-checker.enable = true;
          markdownlint.enable = true;
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

      packages = rec {
        default = haskell-tools-nvim;
        haskell-tools-nvim = pkgs.haskell-tools-nvim-dev;
        inherit
          (pkgs)
          nvim-minimal-stable
          nvim-minimal-nightly
          ;
        inherit
          docgen
          ;
      };

      checks = {
        inherit
          type-check-stable
          type-check-nightly
          pre-commit-check
          ;
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

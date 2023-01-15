{
  description = "haskell-tools.nvim - supercharge your haskell experience in neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-22.11";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # inputs for tests
    packer-nvim = {
      url = "github:wbthomason/packer.nvim";
      flake = false;
    };

    plenary-nvim = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };

    telescope-nvim = {
      url = "github:nvim-telescope/telescope.nvim";
      flake = false;
    };

    nvim-lspconfig = {
      url = "github:neovim/nvim-lspconfig";
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
    ...
  }: let
    supportedSystems = [
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    perSystem = nixpkgs.lib.genAttrs supportedSystems;
    pkgsFor = system: import nixpkgs {inherit system;};

    test-overlay = import ./nix/test-overlay.nix {
      inherit
        (inputs)
        packer-nvim
        plenary-nvim
        telescope-nvim
        nvim-lspconfig
        toggleterm
        ;
    };

    haskell-tooling-overlay = import ./nix/haskell-tooling-overlay.nix {inherit self;};

    haskell-tools-nvim-for = system: let
      pkgs = pkgsFor system;
    in
      pkgs.vimUtils.buildVimPluginFrom2Nix {
        name = "haskell-tools";
        src = self;
      };

    pre-commit-check-for = system:
      pre-commit-hooks.lib.${system}.run {
        src = self;
        hooks = {
          alejandra.enable = true;
          stylua.enable = true;
        };
      };

    shellFor = system: let
      pkgs = pkgsFor system;
      pre-commit-check = pre-commit-check-for system;
      docgen = pkgs.callPackage ./nix/docgen.nix {};
    in
      pkgs.mkShell {
        name = "haskell-tools.nvim-shell";
        inherit (pre-commit-check) shellHook;
        buildInputs = with pkgs; [
          zlib
          alejandra
          stylua
          docgen
        ];
      };
  in {
    overlays = {
      inherit test-overlay haskell-tooling-overlay;
      default = haskell-tooling-overlay;
    };

    devShells = perSystem (system: rec {
      default = haskell-tools;
      haskell-tools = shellFor system;
    });

    packages = perSystem (system: rec {
      default = haskell-tools-nvim;
      haskell-tools-nvim = haskell-tools-nvim-for system;
    });

    checks = perSystem (system: let
      checkPkgs = import nixpkgs {
        inherit system;
        overlays = [
          test-overlay
          neovim-nightly-overlay.overlay
        ];
      };
    in {
      formatting = pre-commit-check-for system;
      inherit
        (checkPkgs)
        haskell-tools-test
        haskell-tools-test-no-telescope
        haskell-tools-test-no-telescope-with-hoogle
        haskell-tools-test-nightly
        haskell-tools-test-no-telescope-nightly
        haskell-tools-test-no-telescope-with-hoogle-nightly
        ;
    });
  };
}

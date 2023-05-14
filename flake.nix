{
  description = "haskell-tools.nvim - supercharge your haskell experience in neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
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
    plenary-nvim = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };

    telescope-nvim = {
      url = "github:nvim-telescope/telescope.nvim";
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
    nixpkgs-unstable,
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
    pkgsUnstableFor = system: import nixpkgs-unstable {inherit system;};

    test-overlay = import ./nix/test-overlay.nix {
      inherit
        (inputs)
        self
        plenary-nvim
        telescope-nvim
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
          luacheck.enable = true;
          editorconfig-checker.enable = true;
          markdownlint.enable = true;
        };
      };

    shellFor = system: let
      pkgs = pkgsFor system;
      pre-commit-check = pre-commit-check-for system;
    in
      pkgs.mkShell {
        name = "haskell-tools.nvim-shell";
        inherit (pre-commit-check) shellHook;
        buildInputs = with pkgs; [
          zlib
          alejandra
          stylua
          lua51Packages.luacheck
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

    packages = perSystem (system: let
      pkgs = pkgsUnstableFor system;
      haskell-tools-nvim = haskell-tools-nvim-for system;
      docgen = pkgs.callPackage ./nix/docgen.nix {};
    in {
      default = haskell-tools-nvim;
      inherit docgen haskell-tools-nvim;
    });

    checks = perSystem (system: let
      checkPkgs = import nixpkgs {
        inherit system;
        overlays = [
          test-overlay
          haskell-tooling-overlay
          neovim-nightly-overlay.overlay
        ];
      };
    in {
      formatting = pre-commit-check-for system;
      inherit
        (checkPkgs)
        typecheck
        haskell-tools-test
        haskell-tools-test-no-hls
        haskell-tools-test-no-telescope
        haskell-tools-test-no-telescope-with-hoogle
        haskell-tools-test-nightly
        haskell-tools-test-no-telescope-nightly
        haskell-tools-test-no-telescope-with-hoogle-nightly
        ;
    });
  };
}

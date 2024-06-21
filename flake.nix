{
  description = "haskell-tools.nvim - supercharge your haskell experience in neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    neorocks = {
      url = "github:nvim-neorocks/neorocks";
    };

    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";

    git-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    neorocks,
    gen-luarc,
    git-hooks,
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
          gen-luarc.overlays.default
        ];
      };

      docgen = pkgs.callPackage ./nix/docgen.nix {};

      luarc-plugins = with pkgs.lua51Packages; (with pkgs.vimPlugins; [
        toggleterm-nvim
        telescope-nvim
        nvim-dap
      ]);

      luarc-nightly = pkgs.mk-luarc {
        nvim = pkgs.neovim-nightly;
        plugins = luarc-plugins;
      };

      luarc-stable = pkgs.mk-luarc {
        nvim = pkgs.neovim-unwrapped;
        plugins = luarc-plugins;
        disabled-diagnostics = [
          "undefined-doc-name"
          "redundant-parameter"
          "invisible"
        ];
      };

      type-check-nightly = git-hooks.lib.${system}.run {
        src = self;
        hooks = {
          lua-ls = {
            enable = true;
            settings.configuration = luarc-nightly;
          };
        };
      };

      type-check-stable = git-hooks.lib.${system}.run {
        src = self;
        hooks = {
          lua-ls = {
            enable = true;
            settings.configuration = luarc-stable;
          };
        };
      };

      pre-commit-check = git-hooks.lib.${system}.run {
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
        name = "haskell-tools.nvim-devShell";
        shellHook = ''
          ${pre-commit-check.shellHook}
          ln -fs ${pkgs.luarc-to-json luarc-nightly} .luarc.json
        '';
        buildInputs =
          self.checks.${system}.pre-commit-check.enabledPackages
          ++ (with pkgs; [
            lua-language-server
            busted-nlua
            (lua5_1.withPackages (ps: with ps; [luarocks]))
          ]);
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

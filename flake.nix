{
  description = "haskell-tools.nvim - supercharge your haskell experience in neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gen-luarc = {
      url = "github:mrcjkb/nix-gen-luarc-json";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
      };
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    git-hooks,
    gen-luarc,
    ...
  }: let
    name = "haskell-tools.nvim";

    plugin-overlay = import ./nix/plugin-overlay.nix {inherit name self;};
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = builtins.attrNames nixpkgs.legacyPackages;
      imports = [
        git-hooks.flakeModule
      ];
      perSystem = {
        system,
        pkgs,
        ...
      }: let
        neovim-nightly = inputs.neovim-nightly-overlay.packages.${system}.default;

        ci-overlay = import ./nix/ci-overlay.nix {inherit neovim-nightly;};

        luarc-plugins = with pkgs.luajitPackages; (with pkgs.vimPlugins; [
          toggleterm-nvim
          telescope-nvim
          nvim-dap
        ]);

        luarc-nightly = pkgs.mk-luarc {
          nvim = neovim-nightly;
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
            markdownlint = {
              enable = true;
              excludes = [
                ".github/PULL_REQUEST_TEMPLATE.md"
              ];
            };
          };
        };

        docgen = pkgs.callPackage ./nix/docgen.nix {};

        devShell = pkgs.mkShell {
          name = "haskell-tools.nvim-devShell";
          shellHook = ''
            ${pre-commit-check.shellHook}
            if command -v nvim >/dev/null 2>&1; then
              export VIMRUNTIME="$(nvim --clean --headless -c 'lua io.write(vim.env.VIMRUNTIME)' +q)";
            else
              export VIMRUNTIME="${pkgs.neovim-unwrapped}/share/nvim/runtime";
            fi
          '';
          buildInputs =
            pre-commit-check.enabledPackages
            ++ (with pkgs; [
              lua-language-server
              lux-cli
              haskell.packages.ghc914.haskell-debugger
            ]);
        };
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [
            ci-overlay
            gen-luarc.overlays.default
            plugin-overlay
          ];
        };

        devShells = {
          default = devShell;
          ci = pkgs.mkShell {
            name = "haskell-tools.nvim devShell";
            shellHook = ''
              ${pre-commit-check.shellHook}
            '';
            buildInputs = with pkgs; [
              haskell-language-server
              cabal-install
              stack
              ghc
              haskell.packages.ghc914.haskell-debugger
            ];
          };
        };

        legacyPackages = pkgs;

        packages = rec {
          default = haskell-tools-nvim;
          hdb = pkgs.haskell.packages.ghc914.haskell-debugger;
          inherit docgen;
          inherit
            (pkgs)
            haskell-tools-nvim
            nvim-minimal-stable
            nvim-minimal-nightly
            ;
        };

        checks = {
          formatting = pre-commit-check;
          inherit
            type-check-stable
            type-check-nightly
            ;
        };
      };
      flake = {
        overlays.default = plugin-overlay;
      };
    };
}

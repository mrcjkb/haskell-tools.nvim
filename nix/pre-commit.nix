{ sources ? import ./sources.nix }:
let
  pre-commit-hooks = import sources.pre-commit-hooks;
in
{
  run = pre-commit-hooks.run {
    src = ../.;
    hooks = {
      nixpkgs-fmt.enable = true;
    };
  };
  tools = with pre-commit-hooks; [
    nixpkgs-fmt
  ];
}

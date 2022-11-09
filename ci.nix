let
  sources = import ./nix/sources.nix;
  pkgs = import ./nix/pkgs.nix { inherit sources; };
  pre-commit = import ./nix/pre-commit.nix { inherit sources; };
in
{
  haskell-tools-test = pkgs.haskell-tools-test;

  pre-commit-check = pre-commit.run;

  shell = pkgs.symlinkJoin {
    name = "shell";
    paths = (import ./shell.nix { inherit sources pkgs pre-commit; }).buildInputs;
  };
}

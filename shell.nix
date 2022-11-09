{ sources ? import ./nix/sources.nix
, pkgs ? import ./nix/pkgs.nix { inherit sources; }
, pre-commit ? import ./nix/pre-commit.nix { inherit sources; }
}:

pkgs.mkShell {
  name = "haskell-tools.nvim-shell";
  buildInputs = with pkgs; [
    (import sources.niv { }).niv
    zlib
  ] ++ pre-commit.tools;
}


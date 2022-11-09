{ sources ? import ./sources.nix }:

import sources.nixpkgs {
  overlays = [
    (final: previous: { inherit (import sources.gitignore { inherit (final) lib; }) gitignoreSource; })
    (import ./overlay.nix)
  ];
}

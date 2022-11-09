# Contributing guide

Contributions are more than welcome!

Please don't forget to add your changes to the "Unreleased" section of [the changelog](./CHANGELOG.md) (if applicable).

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Tests

I haven't had the time to set up proper tests (beyond checking that the plugin can be loaded).
I use [nix](https://nixos.org/download.html#download-nix) for development and testing.

To run tests locally:

```nix
nix-build ci.nix -A haskell-tools-test
```

For formatting:

```nix
nix-build ci.nix -A pre-commit-check
```

To enter a development shell:

```nix
nix-shell
```

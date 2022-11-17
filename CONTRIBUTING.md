# Contributing guide

Contributions are more than welcome!

Please don't forget to add your changes to the "Unreleased" section of [the changelog](./CHANGELOG.md) (if applicable).

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Tests

I haven't had the time to set up proper tests (beyond checking that the plugin can be loaded).
I use [`nix`](https://nixos.org/download.html#download-nix) for development and testing.

To run tests locally:

```console
nix-build -A haskell-tools-test
```

or (with flakes enabled)

```console
nix build .#checks.<your-system>.haskell-tools-test
```

For formatting:

```console
nix-build -A formatting
```

or (with flakes enabled)

```console
nix build .#checks.<your-system>.formatting
```

To apply formatting, while in a devShell, run 

```console 
pre-commit run --all
```

If you have flakes enabled and just want to run all checks that are available, run: 

```console
nix flake check
```

To enter a development shell:

```console
nix-shell
```
or (with flakes enabled)

```console
nix develop
```

if you use direnv, just run `direnv allow` and you will be dropped in this devShell.

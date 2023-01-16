# Contributing guide

Contributions are more than welcome!

Please don't forget to add your changes to the "Unreleased" section of [the changelog](./CHANGELOG.md) (if applicable).

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Development

I use

* [`nix`](https://nixos.org/download.html#download-nix) for development and testing.
* [`stylua`](https://github.com/JohnnyMorganz/StyLua) for formatting.
* [`luacheck`](https://github.com/mpeterv/luacheck) and [`sumneko-lua-language-server`](https://github.com/sumneko/lua-language-server/wiki/Diagnosis-Report#create-a-report) for linting.

To enter a development shell:

```console
nix-shell
```

or (with flakes enabled)

```console
nix develop
```

To apply formatting, while in a devShell, run

```console
pre-commit run --all
```

If you use [`direnv`](https://direnv.net/), just run `direnv allow` and you will be dropped in this devShell.

## Tests


To run tests locally

```console
nix-build -A haskell-tools-test
```

or (with flakes enabled)

```console
nix build .#checks.<your-system>.haskell-tools-test --print-build-logs
```

For formatting:

```console
nix-build -A formatting
```

or (with flakes enabled)

```console
nix build .#checks.<your-system>.formatting --print-build-logs
```

If you have flakes enabled and just want to run all checks that are available, run:

```console
nix flake check --print-build-logs
```

# Contributing guide

Contributions are more than welcome!

This document assumes that you already know how to use GitHub and Git.
If that's not the case, we recommend learning about it first [here](https://docs.github.com/en/get-started/quickstart/hello-world).

## Strict No LLM / No AI Policy

No LLMs for issues.

No LLMs for pull requests.

No LLMs for comments on issues/PRs, including translation. English is encouraged, but not required. You are welcome to post in your native language and rely on others to have their own translation tools of choice to interpret your words.

## First-time contributors

I label issues that I think should be easy for first-time contributors
with [`good-first-issue`](https://github.com/mrcjkb/haskell-tools.nvim/issues?q=is%3Aissue%20state%3Aopen%20label%3A%22good%20first%20issue%22).

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Development

I use

- [`nix`](https://nixos.org/download.html#download-nix) for development and testing.
- [`stylua`](https://github.com/JohnnyMorganz/StyLua),
  [`.editorconfig`](https://editorconfig.org/),
  and [`alejandra`](https://github.com/kamadorueda/alejandra)
  for formatting.
- [`luacheck`](https://github.com/mpeterv/luacheck),
  and [`markdownlint`](https://github.com/DavidAnson/markdownlint),
  for linting.
- [`sumneko-lua-language-server`](https://github.com/sumneko/lua-language-server/wiki/Diagnosis-Report#create-a-report)
  for static type checking.

### Type safety

Lua is incredibly responsive, giving immediate feedback for configuration.
But its dynamic typing makes Neovim plugins susceptible to unexpected bugs
at the wrong time.
To mitigate this, I rely on [LuaCATS annotations](https://luals.github.io/wiki/annotations/),
which are checked in CI.

### Running tests

This plugin uses [`busted`](https://lunarmodules.github.io/busted/) for testing.

The best way to run tests is with Nix (see below),
because this includes tests that take different
envrionments into account (e.g. with/without `fast-tags`, `hoogle`, ...).

If you do not use Nix, you can run a basic version of the test suite using
`luarocks test`.
For more information, see the [neorocks tutorial](https://github.com/nvim-neorocks/neorocks#without-neolua).

### Development using Nix

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

If you use [`direnv`](https://direnv.net/),
just run `direnv allow` and you will be dropped in this devShell.

To run tests locally

```console
nix-build -A haskell-tools-test
```

Or (with flakes enabled)

```console
nix build .#checks.<your-system>.haskell-tools-test --print-build-logs
```

For formatting and linting:

```console
nix-build -A pre-commit-check
```

Or (with flakes enabled)

```console
nix build .#checks.<your-system>.formatting --print-build-logs
```

If you have flakes enabled and just want to run all checks that are available, run:

```console
nix flake check --print-build-logs
```

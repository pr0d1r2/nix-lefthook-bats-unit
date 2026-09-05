# nix-lefthook-bats-unit

[![CI](https://github.com/pr0d1r2/nix-lefthook-bats-unit/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-bats-unit/actions/workflows/ci.yml)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible [Bats](https://github.com/bats-core/bats-core) unit test runner, packaged as a Nix flake.

Runs a repository's `.bats` specs, discovered with `git ls-files` so no layout is
privileged: flat in `tests/`, under `tests/unit/`, or nested anywhere else.

Sequential by default, because specs that share git and test state are flaky in
parallel; set `LEFTHOOK_BATS_UNIT_JOBS` to opt back in.

A repository with no tracked specs says so and exits 0. Outside a git repository
it exits non-zero rather than reporting green on a suite it could not find --
the previous default was the literal path `tests/unit/` and exited 0 when absent,
so a repository keeping its specs elsewhere had a gate that ran nothing.

With arguments the contract is unchanged: a directory runs the `.bats` files
directly inside it, and file arguments run exactly those files.

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` — no flake input needed, just `pkgs.bats and pkgs.coreutils` in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-bats-unit
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-bats-unit = {
  url = "github:pr0d1r2/nix-lefthook-bats-unit";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-bats-unit.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add to `lefthook.yml`:

```yaml
pre-push:
  commands:
    bats-unit:
      run: timeout ${LEFTHOOK_BATS_UNIT_TIMEOUT:-120} lefthook-bats-unit
```

### Configuring timeout

The default timeout is 120 seconds. Override per-repo via environment variable:

```bash
export LEFTHOOK_BATS_UNIT_TIMEOUT=60
```

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) — entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-bats-unit  # direnv loads the flake
bats tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
bats tests/unit/
```

## License

MIT

#!/usr/bin/env bats
#
# The PACKAGE, not the script: a consumer repository gets this wrapper and no
# other bats, because `writeShellApplication` puts its runtimeInputs ahead of
# the caller's PATH. So whatever bats this package bundles IS the bats every
# consumer spec runs under, and if it carries no libraries every spec dies in
# `setup` before asserting anything.

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    FLAKE="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TMPDIR="$(mktemp -d)"

    # git EXPORTS these into every hook it runs, and this spec runs under the
    # pre-commit hook. Inherited, the fixture's `git add` writes the REAL index
    # of the repository being committed — measured: it replaced this repository
    # with the fixture's single file. The fixture must own its own git state.
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
    unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
}

teardown() {
    rm -rf "$TMPDIR"
}

@test "the packaged wrapper brings its own bats libraries" {
    command -v nix >/dev/null 2>&1 || skip "nix not on PATH"
    # stderr carries nix's settings warnings, which `run` folds into $output;
    # the store path is what the last line says.
    run bash -c 'nix build --no-link --print-out-paths "$1#default" 2>/dev/null' -- "$FLAKE"
    assert_success
    wrapper="$(printf '%s\n' "$output" | tail -1)/bin/lefthook-bats-unit"
    [ -x "$wrapper" ]

    # A repository whose specs load the libraries the way these repositories
    # do, run with NO ambient BATS_LIB_PATH — the consumer's situation exactly.
    mkdir -p "$TMPDIR/repo/tests/unit"
    cd "$TMPDIR/repo"
    git init -q .
    git config user.email t@t
    git config user.name t
    cat > tests/unit/probe.bats <<'SPEC'
#!/usr/bin/env bats
setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
}
@test "libraries resolve" {
    run echo hi
    assert_output "hi"
}
SPEC
    git add -A

    run env -u BATS_LIB_PATH "$wrapper"
    assert_success
    assert_output --partial "ok 1 libraries resolve"
    refute_output --partial "bats-support/load.bash"
}

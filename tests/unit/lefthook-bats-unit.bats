#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    TMP="$BATS_TEST_TMPDIR"
    SCRIPT="$BATS_TEST_DIRNAME/../../lefthook-bats-unit.sh"
}

# A git repo at $TMP/$1 holding a spec at $2 with body $3.
_repo() {
    mkdir -p "$TMP/$1/$(dirname "$2")"
    cd "$TMP/$1" || return 1
    git init -q .
    git config user.email t@t
    git config user.name t
    printf '#!/usr/bin/env bats\n@test "%s" {\n    %s\n}\n' "$3" "$4" >"$2"
    git add "$2"
}

# A stub `bats` on PATH at $TMP/$1 that echoes its argv.
_stub_bats() {
    mkdir -p "$TMP/$1"
    printf '#!/usr/bin/env bash\nprintf "bats %%s\\n" "$*"\n' >"$TMP/$1/bats"
    chmod +x "$TMP/$1/bats"
}

@test "exits 0 when the given directory does not exist" {
    run lefthook-bats-unit "$TMP/nonexistent"
    assert_success
}

@test "says so when the given directory holds no .bats files" {
    mkdir -p "$TMP/empty"
    run lefthook-bats-unit "$TMP/empty"
    assert_success
    assert_output --partial "nothing to run"
}

@test "runs the .bats files in a given directory" {
    _repo dirarg tests/unit/example.bats "passes" "true"
    run lefthook-bats-unit "$TMP/dirarg/tests/unit"
    assert_success
    assert_output --partial "ok 1"
}

@test "reports failure for a failing test" {
    _repo dirfail tests/unit/fail.bats "fails" "false"
    run lefthook-bats-unit "$TMP/dirfail/tests/unit"
    assert_failure
}

@test "discovers tracked specs wherever they live, not only tests/unit/" {
    # The old default was the literal path tests/unit/, so a repository with
    # specs elsewhere got a gate that ran nothing and reported green.
    _repo flat tests/flat.bats "flat spec ran" "true"
    run lefthook-bats-unit
    assert_success
    assert_output --partial "flat spec ran"
}

@test "discovers specs in nested directories too" {
    _repo nested tests/unit/deep/n.bats "nested spec ran" "true"
    run lefthook-bats-unit
    assert_success
    assert_output --partial "nested spec ran"
}

@test "a repository with no specs says so and passes" {
    mkdir -p "$TMP/bare"
    cd "$TMP/bare" || return 1
    git init -q .
    run lefthook-bats-unit
    assert_success
    assert_output --partial "no .bats files tracked"
}

@test "outside a git repository it REFUSES rather than passing silently" {
    mkdir -p "$TMP/plain"
    cd "$TMP/plain" || return 1
    run lefthook-bats-unit
    assert_failure
    assert_output --partial "not a git repository"
}

@test "a failing tracked spec fails the run" {
    _repo redrepo tests/bad.bats "fails" "false"
    run lefthook-bats-unit
    assert_failure
}

# These two assert the ARGV the wrapper builds, so they invoke the script
# directly: the built wrapper puts the store's bats first on PATH, so a stub
# placed there is never reached and the test would pass whatever it did.

@test "runs sequentially by default -- no --jobs is passed" {
    _repo seq tests/one.bats "one" "true"
    _stub_bats binseq
    PATH="$TMP/binseq:$PATH" run bash "$SCRIPT"
    assert_success
    refute_output --partial "--jobs"
}

@test "LEFTHOOK_BATS_UNIT_JOBS opts parallelism back in" {
    _repo par tests/one.bats "one" "true"
    _stub_bats binpar
    PATH="$TMP/binpar:$PATH" LEFTHOOK_BATS_UNIT_JOBS=4 run bash "$SCRIPT"
    assert_success
    assert_output --partial "--jobs 4"
}

#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR"
}

@test "exits 0 when tests/unit/ does not exist" {
    run lefthook-bats-unit "$TMP/nonexistent"
    assert_success
}

@test "exits 0 when tests/unit/ has no .bats files" {
    mkdir -p "$TMP/empty-tests"
    run lefthook-bats-unit "$TMP/empty-tests"
    assert_success
}

@test "runs .bats files in tests/unit/" {
    mkdir -p "$TMP/project/tests/unit"
    cat > "$TMP/project/tests/unit/example.bats" <<'BATS'
#!/usr/bin/env bats
@test "passes" {
    true
}
BATS
    run lefthook-bats-unit "$TMP/project/tests/unit"
    assert_success
    assert_output --partial "ok 1"
}

@test "reports failure for failing test" {
    mkdir -p "$TMP/project/tests/unit"
    cat > "$TMP/project/tests/unit/fail.bats" <<'BATS'
#!/usr/bin/env bats
@test "fails" {
    false
}
BATS
    run lefthook-bats-unit "$TMP/project/tests/unit"
    assert_failure
}

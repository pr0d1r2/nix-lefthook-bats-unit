# shellcheck shell=bash
# Run bats unit tests in parallel for the tests/unit/ directory.
# Usage: lefthook-bats-unit [test_dir]
# Defaults to tests/unit/ if no argument is given.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

test_dir="${1:-tests/unit}"

if [ ! -d "$test_dir" ]; then
    exit 0
fi

shopt -s nullglob
tests=("$test_dir"/*.bats)
shopt -u nullglob

if [ ${#tests[@]} -eq 0 ]; then
    exit 0
fi

exec bats --jobs "$(nproc)" "$test_dir"

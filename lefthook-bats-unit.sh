# shellcheck shell=bash
# Run bats unit tests in parallel.
# Usage: lefthook-bats-unit [file1.bats file2.bats ...]
# With arguments: runs only the given .bats files.
# Without arguments: runs all *.bats in tests/unit/.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ $# -gt 0 ]; then
  files=()
  for f in "$@"; do
    [ -f "$f" ] || continue
    case "$f" in
      *.bats) files+=("$f") ;;
    esac
  done
  if [ ${#files[@]} -eq 0 ]; then
    exit 0
  fi
  exec bats --jobs "$(nproc)" "${files[@]}"
fi

test_dir="tests/unit"

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

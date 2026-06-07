# shellcheck shell=bash
# Run bats unit tests in parallel.
# Usage: lefthook-bats-unit [dir_or_files...]
# With a directory argument: runs all *.bats in that directory.
# With file arguments: runs only the given .bats files.
# Without arguments: runs all *.bats in tests/unit/.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ $# -eq 0 ]; then
  test_dir="tests/unit"
elif [ $# -eq 1 ] && [ -d "$1" ]; then
  test_dir="$1"
else
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

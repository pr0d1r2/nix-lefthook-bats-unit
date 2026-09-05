# shellcheck shell=bash
# Run a repository's bats specs.
# Usage: lefthook-bats-unit [dir_or_files...]
#   a directory  -> every *.bats directly inside it
#   file args    -> exactly those files
#   no arguments -> every *.bats TRACKED BY GIT, wherever it lives
#
# WHY GIT DISCOVERY: the no-argument default used to be the literal path
# tests/unit/, and exited 0 when it was absent. A repository that keeps its
# specs anywhere else therefore had a pre-push gate that reported green in
# hundredths of a second having executed nothing. Measured on a repository with
# 617 specs in tests/: the hook had never run one of them. `git ls-files` is
# what the repository itself says its specs are, so no layout is privileged.
#
# WHY SEQUENTIAL: bats files in these repositories share git and test state,
# and parallel runs are flaky under emulation and on multi-core runners. Set
# LEFTHOOK_BATS_UNIT_JOBS to opt back in.
#
# NOTE: sourced by writeShellApplication -- no shebang or set needed.

jobs_args=()
if [ -n "${LEFTHOOK_BATS_UNIT_JOBS:-}" ]; then
  jobs_args=(--jobs "$LEFTHOOK_BATS_UNIT_JOBS")
fi

if [ $# -eq 1 ] && [ -d "$1" ]; then
  shopt -s nullglob
  dir_tests=("$1"/*.bats)
  shopt -u nullglob
  if [ ${#dir_tests[@]} -eq 0 ]; then
    echo "bats-unit: no .bats files in $1 -- nothing to run"
    exit 0
  fi
  exec bats "${jobs_args[@]}" "${dir_tests[@]}"
fi

if [ $# -gt 0 ]; then
  files=()
  for f in "$@"; do
    [ -f "$f" ] || continue
    case "$f" in
      *.bats) files+=("$f") ;;
    esac
  done
  if [ ${#files[@]} -eq 0 ]; then
    echo "bats-unit: no .bats files among the given arguments -- nothing to run"
    exit 0
  fi
  exec bats "${jobs_args[@]}" "${files[@]}"
fi

# No arguments: ask the repository what its specs are.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "bats-unit: not a git repository, so specs cannot be discovered" >&2
  exit 1
fi

# NUL-delimited straight into mapfile: a command substitution would strip the
# separators and bash would warn about the ignored null bytes.
all_tests=()
mapfile -d '' all_tests < <(git ls-files -z -- '*.bats')

if [ ${#all_tests[@]} -eq 0 ]; then
  echo "bats-unit: no .bats files tracked in this repository -- nothing to run"
  exit 0
fi

missing=()
present=()
for f in "${all_tests[@]}"; do
  if [ -f "$f" ]; then
    present+=("$f")
  else
    missing+=("$f")
  fi
done

if [ ${#present[@]} -eq 0 ]; then
  echo "bats-unit: ${#missing[@]} .bats file(s) tracked but none present in the working tree" >&2
  exit 1
fi

exec bats "${jobs_args[@]}" "${present[@]}"

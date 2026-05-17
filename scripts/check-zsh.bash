#!/usr/bin/env bash

: "${EPOCHREALTIME:?requires GNU Bash >= 5.3}" 2> /dev/null || {
  printf 'error: GNU Bash >= 5.3 required (found %s)\n' "$BASH_VERSION" >&2
  exit 1
}

set -uo pipefail
export LC_ALL=C

main() {
  if ! command -v zsh > /dev/null 2>&1; then
    printf 'error: zsh not found\n' >&2
    return 127
  fi

  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf 'error: run from inside the m1zsh git repository\n' >&2
    return 2
  fi

  local -a files=()
  mapfile -d '' -t files < <(git ls-files -z -c -o --exclude-standard -- '*.zsh' 'init.zsh' 'zshenv.zsh')

  local file status=0
  for file in "${files[@]}"; do
    if zsh -n "$file"; then
      printf 'PASS zsh -n %s\n' "$file"
    else
      printf 'FAIL zsh -n %s\n' "$file" >&2
      status=1
    fi
  done

  if ((${#files[@]} == 0)); then
    printf 'error: no zsh files found\n' >&2
    return 1
  fi

  return "$status"
}

main "$@"

#!/usr/bin/env bash

: "${EPOCHREALTIME:?requires GNU Bash >= 5.3}" 2> /dev/null || {
  printf 'error: GNU Bash >= 5.3 required (found %s)\n' "$BASH_VERSION" >&2
  exit 1
}

set -uo pipefail
export LC_ALL=C

main() {
  local msg_file=${1:-}
  if [[ -z $msg_file || ! -r $msg_file ]]; then
    printf 'error: commit message file missing\n' >&2
    return 2
  fi

  local first_line
  IFS= read -r first_line < "$msg_file" || first_line=''
  if [[ -z $first_line ]]; then
    printf 'error: commit message needs an intent line\n' >&2
    return 1
  fi

  local status=0 required
  for required in 'Confidence:' 'Scope-risk:' 'Tested:'; do
    if ! grep -q "^$required" "$msg_file"; then
      printf 'error: missing Lore trailer: %s\n' "$required" >&2
      status=1
    fi
  done

  return "$status"
}

main "$@"

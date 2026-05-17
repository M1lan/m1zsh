#!/usr/bin/env bash

# Re-exec under a newer Bash if invoked by macOS's stock /bin/bash 3.2.
if ((BASH_VERSINFO[0] < 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] < 3))); then
  while IFS= read -r bash_bin; do
    if [[ -x $bash_bin && $bash_bin != "$BASH" ]] &&
      "$bash_bin" -c '((BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 3)))' > /dev/null 2>&1; then
      exec "$bash_bin" "$0" "$@"
    fi
  done < <(type -a -P bash 2> /dev/null)

  printf 'error: GNU Bash >= 5.3 required (found %s)\n' "$BASH_VERSION" >&2
  exit 1
fi

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

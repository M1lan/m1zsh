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
  if ! command -v zsh > /dev/null 2>&1; then
    printf 'error: zsh not found\n' >&2
    return 127
  fi

  if ! git -c core.fsmonitor=false rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf 'error: run from inside the m1zsh git repository\n' >&2
    return 2
  fi

  local -a files=()
  mapfile -d '' -t files < <(git -c core.fsmonitor=false ls-files -z -- '*.zsh')

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

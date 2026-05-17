#!/usr/bin/env bash

: "${EPOCHREALTIME:?requires GNU Bash >= 5.3}" 2> /dev/null || {
  printf 'error: GNU Bash >= 5.3 required (found %s)\n' "$BASH_VERSION" >&2
  exit 1
}

set -uo pipefail
export LC_ALL=C

main() {
  if ! command -v rg > /dev/null 2>&1; then
    printf 'error: ripgrep (rg) is required for secret scanning\n' >&2
    return 127
  fi

  local -a patterns=(
    '-----BEGIN (RSA|OPENSSH|EC|DSA|PRIVATE) KEY-----'
    '(?i)(api[_-]?key|secret|token|password|passwd|credential|webhook)[[:space:]]*[:=][[:space:]]*["'"'"']?[^"'"'"'[[:space:]]{16,}'
    'ghp_[A-Za-z0-9_]{36,}'
    'github_pat_[A-Za-z0-9_]{20,}'
    'xox[baprs]-[A-Za-z0-9-]{10,}'
    'AKIA[0-9A-Z]{16}'
    '://[^/@[:space:]]+:[^/@[:space:]]+@'
    '/Users/[^/[:space:]]+'
  )

  local status=0 pattern
  for pattern in "${patterns[@]}"; do
    if rg --pcre2 -n --hidden --no-ignore-vcs \
      --glob '!.git/**' \
      --glob '!scripts/scan-secrets.bash' \
      --glob '!templates/personal.zsh' \
      -e "$pattern" .; then
      status=1
    fi
  done

  if ((status == 0)); then
    printf 'PASS secret boundary scan\n'
  else
    printf 'FAIL secret boundary scan\n' >&2
  fi
  return "$status"
}

main "$@"

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

# Scan only files tracked by git. Gitignored agent-state directories
# (.omc/.omx/.claude/.codex/.forge/) and local caches legitimately contain
# machine paths and provider tokens — they must never enter the scanner's
# view. Tracked-files-only enforces "if you can publish it, we scan it".
main() {
  if ! command -v rg > /dev/null 2>&1; then
    printf 'error: ripgrep (rg) is required for secret scanning\n' >&2
    return 127
  fi
  if ! command -v git > /dev/null 2>&1; then
    printf 'error: git is required for secret scanning\n' >&2
    return 127
  fi

  local repo_root
  repo_root=$(git -c core.fsmonitor=false rev-parse --show-toplevel 2> /dev/null) || {
    printf 'error: scan-secrets must run inside a git checkout\n' >&2
    return 2
  }
  cd "$repo_root" || return 2

  local -a patterns=(
    # Private key blocks: RSA / OpenSSH / EC / DSA / ed25519 / ecdsa / PGP /
    # any future "-----BEGIN <kind> KEY-----" (with optional " BLOCK" suffix
    # for PGP).
    '-----BEGIN [A-Z0-9 ]+ KEY( BLOCK)?-----'

    # Generic high-entropy key=value assignments.
    '(?i)(api[_-]?key|secret|token|password|passwd|credential|webhook)[[:space:]]*[:=][[:space:]]*["'"'"']?[^"'"'"'[[:space:]]{16,}'

    # GitHub tokens: classic PAT (ghp_), OAuth (gho_), user-to-server (ghu_),
    # server-to-server (ghs_), refresh (ghr_), fine-grained PAT.
    'gh[pousr]_[A-Za-z0-9_]{30,}'
    'github_pat_[A-Za-z0-9_]{20,}'

    # Slack tokens.
    'xox[baprs]-[A-Za-z0-9-]{10,}'

    # AWS access key id + secret access key context match.
    'AKIA[0-9A-Z]{16}'
    '(?i)aws(.{0,20})?(secret|sk)[^A-Za-z0-9/+=]{0,5}[A-Za-z0-9/+=]{40}'

    # GCP service-account JSON markers.
    '"type"[[:space:]]*:[[:space:]]*"service_account"'
    '"private_key_id"[[:space:]]*:[[:space:]]*"[a-f0-9]{32,}"'

    # Generic JWT (three base64url segments, header starts with eyJ).
    'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'

    # OpenAI / Anthropic / project-scoped API key prefixes.
    'sk-(ant|proj|live|test|admin|svcacct)-[A-Za-z0-9_-]{20,}'
    'sk-[A-Za-z0-9]{32,}'

    # 1Password Connect / service-account tokens.
    'ops_[A-Za-z0-9_=.-]{40,}'

    # Basic-auth credentials embedded in URLs.
    '://[^/@[:space:]]+:[^/@[:space:]]+@'

    # Machine-local absolute paths (any /Users/<name>/).
    '/Users/[^/[:space:]]+'
  )

  # Tracked files only, NUL-delimited, with two carve-outs:
  #   - this script: contains the patterns it scans for
  #   - templates/personal.zsh: documents placeholder tokens for users
  local -a scan_files=()
  mapfile -d '' -t scan_files < <(
    git -c core.fsmonitor=false ls-files -z -- . \
      ':!:scripts/scan-secrets.bash' \
      ':!:templates/personal.zsh'
  )

  if ((${#scan_files[@]} == 0)); then
    printf 'PASS secret boundary scan (no tracked files)\n'
    return 0
  fi

  # rg exit-code contract: 0 = match found, 1 = no match, >1 = error.
  # Treat anything above 1 as a hard failure so a broken pattern never
  # silently passes a release gate.
  local status=0 pattern rg_status
  for pattern in "${patterns[@]}"; do
    rg --pcre2 -n -e "$pattern" -- "${scan_files[@]}"
    rg_status=$?
    if ((rg_status == 0)); then
      status=1
    elif ((rg_status > 1)); then
      printf 'error: ripgrep failed (exit %d) on pattern: %s\n' \
        "$rg_status" "$pattern" >&2
      return "$rg_status"
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
